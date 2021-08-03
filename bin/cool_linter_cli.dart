// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cool_linter/src/cli/analyze_command.dart';

Future<void> main(List<String> args) async {
  try {
    final CommandRunner<void> runner = CommandRunner<void>('cool_linter', 'cool_linter cli')
      ..addCommand(AnalyzeCommand());

    await runner.run(args);
  } on UsageException catch (exc) {
    print(exc.message);
    print(exc.usage);
    exit(64);
  } on Exception catch (exc) {
    print('Uunexpected error: $exc');
    exit(1);
  }
}