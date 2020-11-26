import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:hive2moor/src/annotations.dart';
import 'package:source_gen/source_gen.dart';

final _hiveFieldChecker = const TypeChecker.fromRuntime(HiveField);
final _nullableChecker = const TypeChecker.fromRuntime(NullableMoor);
final _primaryChecker = const TypeChecker.fromRuntime(PK);
final getFileName = RegExp(r'.*\/(.*).dart');
final getParameterType = RegExp(r'.*\((.*) .*');

class Hive2MoorGenerator extends GeneratorForAnnotation<HiveType> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    return _generateWidgetSource(
        element as ClassElement, annotation, buildStep);
  }

  Future<String> _generateWidgetSource(ClassElement element,
      ConstantReader annotation, BuildStep buildStep) async {
    print('*' * 99);
    // print(getParameterType
    // .firstMatch(element.getNamedConstructor('fromJson').toString())
    // .group(1));
    var filename =
        getFileName.firstMatch(buildStep.inputId.path).group(1) + 's';
    var parameterType = getParameterType
            .firstMatch(element.getNamedConstructor('fromJson').toString())
            ?.group(1) ??
        'var';
    var fields = '${element}s extends Table{';
    var primaryKey = '';
    var isAutoIncrement = false;
    var insertDAO = createInsertDAO(
        filename: filename, element: element, parameterType: parameterType);
    var classMethods =
        await getClassMethods(element: element, buildStep: buildStep);
    for (var f in element.fields) {
      if (_hiveFieldChecker.hasAnnotationOfExact(f)) {
        var field;
        if (_primaryChecker.hasAnnotationOfExact(f)) {
          isAutoIncrement =
              _primaryChecker.firstAnnotationOf(f).getField('ai').toBoolValue();
          if (!isAutoIncrement) {
            primaryKey = f.declaration.toString().split(' ')[1];
          }
        }
        switch (f.declaration.toString().split(' ')[0]) {
          case 'String':
            {
              _nullableChecker.hasAnnotationOfExact(f)
                  ? field =
                      "TextColumn get ${f.declaration.toString().split(" ")[1]} => text().nullable()()"
                  : field =
                      "TextColumn get ${f.declaration.toString().split(" ")[1]} => text()()";
            }
            break;
          case 'int':
            {
              if (isAutoIncrement) {
                field =
                    "IntColumn get ${f.declaration.toString().split(" ")[1]} => integer().autoIncrement()()";
                break;
              }
              _nullableChecker.hasAnnotationOfExact(f)
                  ? field =
                      "IntColumn get ${f.declaration.toString().split(" ")[1]} => integer().nullable()()"
                  : field =
                      "IntColumn get ${f.declaration.toString().split(" ")[1]} => integer()()";
            }
            break;
          case 'double':
            {
              if (isAutoIncrement) {
                field =
                    "RealColumn get ${f.declaration.toString().split(" ")[1]} => real().autoIncrement()()";
                break;
              }
              _nullableChecker.hasAnnotationOfExact(f)
                  ? field =
                      "RealColumn get ${f.declaration.toString().split(" ")[1]} => real().nullable()()"
                  : field =
                      "RealColumn get ${f.declaration.toString().split(" ")[1]} => real()()";
            }
            break;
          case 'bool':
            {
              _nullableChecker.hasAnnotationOfExact(f)
                  ? field =
                      "BoolColumn get ${f.declaration.toString().split(" ")[1]} => boolean().nullable()()"
                  : field =
                      "BoolColumn get ${f.declaration.toString().split(" ")[1]} => boolean()()";
            }
            break;
          default:
            {
              field = f.declaration.toString();
            }
        }
        fields = fields + field + ';';
      }
    }
    if (primaryKey.isNotEmpty) {
      fields =
          fields + '@override Set<Column> get primaryKey => {${primaryKey}};';
    }
    // fields = fields + '}';
    // No closing bracket because regex matches till the end.
    return fields + classMethods + insertDAO;
  }

  String createInsertDAO(
      {String filename, ClassElement element, String parameterType}) {
    var filenameCamel =
        filename.replaceFirst(filename[0], filename[0].toLowerCase());
    var moorClassName = filename.substring(0, filename.length - 1);
    var companion = createCompanion(filename: filename, element: element);
    var insertDAO =
        'Future insert${filename}({@required ${parameterType} parsedJson}){' +
            companion;
    insertDAO =
        insertDAO + 'return into(${filenameCamel}).insert(entry);' + '}';
    return insertDAO;
  }

  String createCompanion({String filename, ClassElement element}) {
    var companion = '${filename}Companion entry = ${filename}Companion(';
    for (var f in element.fields) {
      if (_hiveFieldChecker.hasAnnotationOfExact(f)) {
        if (_primaryChecker.hasAnnotationOfExact(f) &&
            _primaryChecker.firstAnnotationOf(f).getField('ai').toBoolValue()) {
          continue;
        }
        var fieldname = f.declaration.toString().split(' ')[1];
        switch (f.declaration.toString().split(' ')[0]) {
          case 'String':
            {
              companion = companion +
                  fieldname +
                  ':' +
                  'Value(parsedJson["$fieldname"] ?? ' +
                  '"N/A"' +
                  '),';
            }
            break;
          case 'int':
            {
              companion = companion +
                  fieldname +
                  ':' +
                  'Value(parsedJson["$fieldname"] ?? ' +
                  '-1' +
                  '),';
            }
            break;
          case 'double':
            {
              companion = companion +
                  fieldname +
                  ':' +
                  'Value(parsedJson["$fieldname"] ??' +
                  '-1' +
                  '),';
            }
            break;
          default:
            {
              companion = companion +
                  fieldname +
                  ':' +
                  'Value(parsedJson["$fieldname"])' +
                  ',';
            }
        }
      }
    }
    companion = companion + ');';
    return companion;
  }

  Future<String> getClassMethods(
      {ClassElement element, BuildStep buildStep}) async {
    var getMethodBody;
    var methodBody = '';
    for (int i = 0; i < element.methods.length; i++) {
      if (i == element.methods.length - 1) {
        var m = element.methods[i];
        var regexString;
        var regexMatchString = m.declaration.toString().replaceAll(r'(', r'\(');
        regexMatchString = regexMatchString.replaceAll(r')', r'\)');
        regexString = '(${regexMatchString}.*{.*})';
        print("Group 0");
        print(regexString);
        getMethodBody = RegExp('${regexString}', dotAll: true);
        var contents = await buildStep.readAsString(buildStep.inputId);
        methodBody = methodBody + getMethodBody.firstMatch(contents).group(0);
      } else {
        var m = element.methods[i];
        var mN = element?.methods[i + 1];
        var regexString;
        var regexMatchString = m.declaration.toString().replaceAll(r'(', r'\(');
        regexMatchString = regexMatchString.replaceAll(r')', r'\)');
        regexString = '(${regexMatchString}.*{.*})';
        var regexMatchStringNext = mN.toString().replaceAll(r')', r'\)');
        regexMatchStringNext = regexMatchStringNext.replaceAll('(', r'\(');
        regexString = regexString + '.*${regexMatchStringNext}';
        getMethodBody = RegExp('${regexString}', dotAll: true);
        var contents = await buildStep.readAsString(buildStep.inputId);
        print('Group 1');
        print(regexString);
        methodBody = methodBody + getMethodBody.firstMatch(contents).group(1);
      }
    }
    if (methodBody.isEmpty) {
      return '}';
    }
    return methodBody;
  }
}
