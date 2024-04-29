import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class JSImportVisitor extends SimpleAstVisitor<void> {
  static List<String> _usedNames = [];

  String _output = '';
  String get output => _output;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (var metadata in node.metadata) {
      if (metadata.name.name == 'jsimport') {
        _parseArgs(metadata);
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    for (var metadata in node.metadata) {
      if (metadata.name.name == 'jsimport') {
        _parseArgs(metadata);
      }
    }
  }

  void _checkNameAndAdd(List<String> names, String name) {
    if (_usedNames.contains(name)) {
      throw '$name is already used.';
    }
    names.add(name);
    _usedNames.add(name);
  }

  void _parseArgs(Annotation metadata) {
    if (metadata.arguments == null) throw 'Invalid parameter';

    var strargs = <String>[];
    var args = metadata.arguments?.arguments;

    if (args == null) throw 'Invalid parameter';
    for (var arg in args) {
      if (arg is StringLiteral) {
        var val = arg.stringValue;
        if (val != null) strargs.add(val);
      } else {
        break;
      }
    }
    if (strargs.isEmpty) throw 'Invalid parameter';

    var impstr = '';
    var names = <String>[];
    var type = '';
    var count = 0;

    for (var arg in strargs) {
      if (count == 0) {
        if (arg.length > 2 && arg.endsWith('+')) {
          type = 'default';
          var addname = arg.substring(0, arg.length - 1);
          _checkNameAndAdd(names, addname);
          impstr = '$addname from ';
        } else if (arg.length > 2 && arg.endsWith('*')) {
          type = 'namespace';
          var addname = arg.substring(0, arg.length - 1);
          _checkNameAndAdd(names, addname);
          impstr = '* as $addname from ';
        } else if (arg.isEmpty) {
          type = 'effect';
          impstr = '';
        } else {
          type = 'named';
          if (arg.endsWith('+') || arg.endsWith('*')) throw 'Invalid parameter';
          _checkNameAndAdd(names, arg);
          impstr = '{ $arg,';
        }
      } else if (count < strargs.length - 1) {
        if (type != 'named') throw 'Invalid parameter';
        if (arg.endsWith('+') || arg.endsWith('*')) throw 'Invalid parameter';
        impstr += ' $arg,';
        names.add(arg);
      } else {
        if (type == 'named') {
          impstr = impstr.substring(0, impstr.length - 1) + ' } from ';
        }
        impstr += '"$arg"';
        _addImport(names, impstr);
      }
      count++;
    }
  }

  void _addImport(List<String> name, String param) {
    _output += 'import $param;\n';
    if (name.isNotEmpty) {
      for (var n in name) {
        _output += 'self.$n = $n;\n';
      }
    }
    _output += '\n';
  }

  static JSImportVisitor parse(String path) {
    final ASTResult = parseFile(path: path, featureSet: FeatureSet.latestLanguageVersion());
    final visitor = JSImportVisitor();
    ASTResult.unit.visitChildren(visitor);
    return visitor;
  }
}
