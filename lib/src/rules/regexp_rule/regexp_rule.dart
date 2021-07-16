import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:cool_linter/src/config/yaml_config.dart';
import 'package:cool_linter/src/rules/rule.dart';
import 'package:cool_linter/src/rules/rule_message.dart';
import 'package:pub_semver/pub_semver.dart';

class RegExpRule extends Rule {
  List<RuleMessage> _getIncorrectLines({
    required String content,
    required String path,
    required YamlConfig yamlConfig,
  }) {
    final List<ExcludeWord> patterns = yamlConfig.coolLinter?.excludeWords ?? <ExcludeWord>[];
    if (patterns.isEmpty) {
      return const <RuleMessage>[];
    }

    final List<RuleMessage> matchListInfo = <RuleMessage>[];

    try {
      final ParseStringResult parseResult = parseString(
        content: content,
        featureSet: FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: Version.parse('2.12.0'),
          flags: <String>[],
        ),
        throwIfDiagnostics: false,
      );

      final List<int> lineStarts = parseResult.lineInfo.lineStarts;
      int prevIndex = 0;
      int columnIndex = 0;

      lineStarts.forEach((int lineStartIndex) {
        if (lineStartIndex == 0) {
          return;
        }

        final String lineStr = content.substring(prevIndex, lineStartIndex);
        prevIndex = lineStartIndex;

        // is comment
        final bool isComment = lineStr.trimLeft().startsWith('//');
        if (isComment) {
          columnIndex++;
          return;
        }

        // find first pattern
        final Iterable<ExcludeWord> excludedWordList = patterns.where(
          (ExcludeWord excludeWord) {
            if (excludeWord.pattern == null) {
              return false;
            }

            final RegExp re = RegExp(excludeWord.pattern!);

            return lineStr.contains(re);
          },
        );

        if (excludedWordList.isNotEmpty) {
          final ExcludeWord firstExcluded = excludedWordList.first;
          final String hint = firstExcluded.hint ?? '';

          matchListInfo.add(RuleMessage(
            severityName: firstExcluded.safeSeverity,
            message: 'cool_linter. $hint for pattern: ${firstExcluded.pattern}',
            code: 'cool_linter_needs_fixes',
            location: Location(
              path,
              1, // offset
              1, // length
              columnIndex + 1,
              1, // startColumn
              1, // endLine
              1, // endColumn
            ),
            changeMessage: 'cool_linter. need to replace by pattern:',
          ));
        }

        columnIndex++;
      });

      return matchListInfo;
    } catch (exc) {
      return const <RuleMessage>[];
    }
  }

  @override
  List<RuleMessage> check({
    required String content,
    required String path,
    required YamlConfig yamlConfig,
  }) {
    return _getIncorrectLines(
      content: content,
      path: path,
      yamlConfig: yamlConfig,
    );
  }
}
