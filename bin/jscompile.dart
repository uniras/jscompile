import 'dart:io';
import '../lib/jsImportVisitor.dart';
import '../lib/argparser.dart';

void isExists(String path) {
  if (!File(path).existsSync()) {
    print('File not found: ${path}');
    exit(1);
  }
}

Future<int> main(List<String> args) async {
  //parsing arguments
  final arglist = argParser(args);
  if (arglist.multipleFlagContains(['h', 'help'])) {
    final helpMessage = '''
Dart to JavaScript compiler tool

Usage: dart tool/jscompile.dart [-r] [-n] [-i <entry>] [-o <output>] <entry>

Options:
  -r: Activates release mode, applying level O4 optimization (default: level O1 optimization).
  -i: Entry file path (default: ./lib/main.dart)
  -o: Output file path (default: ./output/main.js)
  -n: Compile dart to js only (no @jsimport annotations parsing and no additional code generation)
  -m: Create a source map file
  -d: no remove .deps file
  -h: Display this help message
    ''';
    print(helpMessage.trim());
    return 0;
  }

  final String level = arglist.contains('r') ? 'O4' : 'O1';
  final String sourceMap = arglist.contains('m') ? '' : '--no-source-maps';
  final bool compileOnly = arglist.contains('n');
  final String outputPath = arglist.getValue('o', './output/main.js');
  final String entryPath = arglist.getMultipleFlagValue(['i'], true, './lib/main.dart');
  final bool noRemoveDeps = arglist.contains('d');

  String dartOutputPath;
  if (compileOnly) {
    dartOutputPath = outputPath;
  } else {
    dartOutputPath = outputPath.replaceAll(RegExp(r'\.js$'), '_dart.js');
  }

  isExists(entryPath);

  var options = <String>[];
  options.addAll(['compile', 'js']);
  options.addAll(['--no-frequency-based-minification', '--server-mode']);
  options.add('-$level');
  if (sourceMap.isNotEmpty) options.add(sourceMap);
  options.addAll(['-o', dartOutputPath]);
  options.add(entryPath);

  //compile dart to js. no minification and server mode compilation.
  final process = await Process.run('dart', options);

  if (process.exitCode != 0) {
    print('Compilation of the Dart entry file failed');
    print(process.stdout);
    print(process.stderr);
    return process.exitCode;
  }

  if (!noRemoveDeps) {
    final depsFile = File('$dartOutputPath.deps');
    if (depsFile.existsSync()) {
      depsFile.deleteSync();
    }
  }

  if (compileOnly) return 0;

  try {
    //Getting output file name
    final dartOutputFileName = dartOutputPath.split(RegExp(r'/|\\')).last;

    //parsing jsimport annotations
    final visitor = JSImportVisitor.parse(entryPath);

    //setting output code
    final outputCode = '''
//Node.js compatible code
if (typeof self === 'undefined' && typeof global === 'object') global.self = global;
self.__nodeInit = true;

//Parse Arguments
if(typeof global === 'object' && typeof global.process === 'object') {
  //Node.js and Bun Arguments parsing
  globalThis.__args = process.argv.slice(2);
} else if(typeof globalThis.Deno !== 'undefined') {
  //Deno Arguments parsing
  globalThis.__args = Deno.args;
} else {
  //Other Platforms Arument not supported
  globalThis.__args = [];
}

//Modules static import and Dart compatible code
${visitor.output}

//Loading Dart transpiled code
(async () => {
  await import('./${dartOutputFileName}');
})();
    ''';

    //writing output file
    final outputFile = File(outputPath);
    outputFile.writeAsStringSync(outputCode.trim());
  } catch (e) {
    print('Failed to generate script.');
    print(e.toString());
    return 1;
  }

  return 0;
}
