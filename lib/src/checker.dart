
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:glob/glob.dart';

import 'config/analysis_settings.dart';
import 'rules/always_specify_types_rule/always_specify_types_rule.dart';
import 'rules/regexp_rule/regexp_rule.dart';
import 'rules/rule.dart';
import 'rules/rule_message.dart';
import 'rules/stream_subscription_rule/stream_subscription_rule.dart';
import 'utils/analyse_utils.dart';

// TODO: add if exists in analysis options
// final List<Rule> kRulesList = <Rule>[
//   RegExpRule(),
//   AlwaysSpecifyTypesRule(),
//   StreamSubscriptionRule(),
// ];

class Checker {
  const Checker();

  Iterable<AnalysisErrorFixes> checkResult({
    required AnalysisSettings analysisSettings,
    required List<Glob> excludesGlobList,
    required ResolvedUnitResult parseResult,
    AnalysisErrorSeverity errorSeverity = AnalysisErrorSeverity.WARNING,
  }) {
    if (parseResult.content == null || parseResult.path == null) {
      return <AnalysisErrorFixes>[];
    }

    final bool isExcluded = AnalysisSettingsUtil.isExcluded(parseResult.path, excludesGlobList);
    if (isExcluded) {
      return <AnalysisErrorFixes>[];
    }

    // rules using
    final List<Rule> kRulesList = <Rule>[
      if (analysisSettings.useRegexpExclude) RegExpRule(),
      if (analysisSettings.useAlwaysSpecifyTypes) AlwaysSpecifyTypesRule(),
      if (analysisSettings.useAlwaysSpecifyStreamSub) StreamSubscriptionRule(),
    ];

    final Iterable<RuleMessage> errorMessageList = kRulesList.map((Rule rule) {
      return rule.check(
        parseResult: parseResult,
        analysisSettings: analysisSettings,
      );
    }).expand((List<RuleMessage> errorMessage) {
      return errorMessage;
    });

    if (errorMessageList.isEmpty) {
      return <AnalysisErrorFixes>[];
    }

    return errorMessageList.map((RuleMessage errorMessage) {
      AnalysisErrorSeverity serverity = AnalysisErrorSeverity.INFO;
      switch (errorMessage.severityName) {
        case 'ERROR':
          serverity = AnalysisErrorSeverity.ERROR;
          break;
        case 'INFO':
          serverity = AnalysisErrorSeverity.INFO;
          break;
        case 'WARNING':
          serverity = AnalysisErrorSeverity.WARNING;
          break;
      }
      final AnalysisError error = AnalysisError(serverity, AnalysisErrorType.LINT,
          errorMessage.location, errorMessage.message, errorMessage.code,
          hasFix: true, correction: '');

      final PrioritizedSourceChange fix = PrioritizedSourceChange(
        1,
        SourceChange(
          'Apply fixes for cool_linter.',
          edits: <SourceFileEdit>[
            SourceFileEdit(
              parseResult.path!,
              parseResult.unit?.declaredElement?.source.modificationStamp ?? 1,
              edits: <SourceEdit>[
                SourceEdit(
                  errorMessage.location.offset, //1,
                  errorMessage.location.length, //2,
                  errorMessage.changeMessage,
                ),
              ],
            )
          ],
        ),
      );

      return AnalysisErrorFixes(
        error,
        fixes: <PrioritizedSourceChange>[
          fix,
        ],
      );
    });
  }
}
