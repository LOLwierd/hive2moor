import 'dart:async';

import 'package:build/build.dart';

class Hive2MoorBuilder implements Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    AssetId inputId = buildStep.inputId;
    var copyInputId = inputId.changeExtension('.g.dart');
    var contents = await buildStep.readAsString(inputId);
    await buildStep.writeAsString(copyInputId, contents);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.g.dart']
      };
}
