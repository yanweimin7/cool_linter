import 'dart:convert';
import 'dart:io' as io;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:cool_linter/src/config/analysis_settings.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../plugin.dart';

/// folder's name in format without slashes
/// used in [plugin.dart]
/// ``` dart
/// '.dart_tool',
/// '.vscode',
/// ```
const List<String> kDefaultExcludedFolders = <String>[
  '.dart_tool',
  '.vscode',
  'packages',
  'ios',
  'macos',
  'android',
  'web',
  'linux',
  'windows',
  'go',
];

/// folder's name in format with slashes
/// used in [yaml_config_extension.dart]
/// ``` dart
/// '.dart_tool/**',
/// '.vscode/**',
/// ```
final List<String> kDefaultExcludedFoldersYaml = kDefaultExcludedFolders.map((String e) {
  return e + '/**';
}).toList();

const List<String> possibleSeverityValues = <String>[
  'INFO',
  'WARNING',
  'ERROR',
];

abstract class AnalysisSettingsUtil {
  static Map<String, dynamic> convertYamlToMap(String str) {
    final dynamic rawMap = json.decode(json.encode(loadYaml(str)));
    if (rawMap is! Map<String, dynamic>) {
      throw ArgumentError('Wrong yaml source');
    }

    return rawMap;
  }

  static AnalysisSettings? getAnalysisSettingsFromFile(File? file) {
    if (file == null) {
      return null;
    }
    String yaml = file.readAsStringSync();
    Map<String, dynamic> map = convertYamlToMap(yaml);
    //add by wey.yan , 如果有include，则读include里面的配置,用于支持import配置。
    if (map['include'] != null) {
      final String includePath = map['include'] as String;
      final String subPath = includePath.substring('package:'.length);
      final List<String> list = subPath.split('/');
      final String packageName = list[0].trim();
      final String fileName = list[1].trim();
      final io.File packageConfigFile =
          io.File('${CoolLinterPlugin.sRootPath}/.dart_tool/package_config.json');
      final String jsonStr = packageConfigFile.readAsStringSync();
      final List packages = convertYamlToMap(jsonStr)['packages'] as List;
      final Map targetLib =
          packages.firstWhere((dynamic e) => (e as Map)['name'] == packageName) as Map;
      final String absPath = '${targetLib['rootUri']}/${targetLib['packageUri']}$fileName';
      final io.File yamlFile = io.File.fromUri(Uri.parse(absPath));
      yaml = yamlFile.readAsStringSync();
      map = convertYamlToMap(yaml);
    }
    return AnalysisSettings.fromJson(map);
  }

  static List<Glob> excludesGlobList(String root, AnalysisSettings analysisSettings) {
    final Iterable<String> patterns = analysisSettings.coolLinter?.excludeFolders ?? <String>[];

    return <String>[
      ...kDefaultExcludedFoldersYaml,
      ...patterns,
    ].map((String folder) {
      return Glob(p.join(root, folder));
    }).toList();
  }

  static bool isExcluded(String? path, Iterable<Glob> excludes) {
    if (path == null) {
      return false;
    }

    return excludes.any((Glob exclude) {
      return exclude.matches(path);
    });
  }

  static Iterable<int>? ignoreColumnList(ResolvedUnitResult parseResult, RegExp regExpSuppression) {
    if (parseResult.content == null) {
      return null;
    }

    final String content = parseResult.content!;

    // ignores
    final Iterable<RegExpMatch> matches = regExpSuppression.allMatches(content);
    // places of [// ignore: always_specify_stream_subscription] comment
    final Iterable<int> ignoreColumnList = matches.map((RegExpMatch match) {
      // ignore: always_specify_types
      final loc = parseResult.lineInfo.getLocation(match.start);

      return loc.lineNumber;
    });

    return ignoreColumnList;
  }
}
