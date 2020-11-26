library hive2moor;

import 'package:build/build.dart';
import 'package:hive2moor/src/Hive2MoorBuilder.dart';
import 'package:hive2moor/src/Hive2MoorGenerator.dart';
import 'package:source_gen/source_gen.dart';
export 'package:hive2moor/src/annotations.dart';

Builder hive2moorBuilder(BuilderOptions options) => Hive2MoorBuilder();

Builder hive2moorGenerator(BuilderOptions options) =>
    SharedPartBuilder([Hive2MoorGenerator()], 'hive2moor');
