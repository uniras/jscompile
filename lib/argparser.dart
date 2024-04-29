class argParser {
  var _args = <String, List<String>>{};
  var _argEmpty = <String>[];
  bool _ignoreCase = false;
  bool _multipleArgValue = false;

  argParser(
    List<String> args, {
    bool ignoreCase = false,
    bool multipleArgValue = false,
    bool singleArgFlag = false,
    bool singleHyphenLongName = false,
    bool parseEqual = false,
  }) {
    _ignoreCase = ignoreCase;
    _multipleArgValue = multipleArgValue;
    if(!multipleArgValue && singleArgFlag) singleArgFlag = false;

    String argName = '';
    for (var arg in args) {
      if (arg.indexOf('-') == 0) {
        String name;
        String argValue = '';
        bool useEqual = false;

        if (arg.length == 1) continue;
        if (arg[1] == '-' && arg.length == 2) continue;
        if (parseEqual && (arg.indexOf('-=') == 0 || arg.indexOf('--=') == 0)) continue;

        if (argName.isNotEmpty && (!_multipleArgValue || !_args.containsKey(argName))) {
          _args[argName] = <String>[];
        }

        if (parseEqual && arg.indexOf('=') >= 1) useEqual = true;
        if (useEqual) {
          var argSplit = arg.split('=');
          name = argSplit[0];
          argValue = argSplit[1];
        } else {
          name = arg;
        }

        if (arg[1] == '-') {
          name = name.substring(2);
        } else {
          name = singleHyphenLongName ? name.substring(1) : name.substring(1, 2);
        }

        if (_ignoreCase) name = name.toLowerCase();

        if (useEqual) {
          _args[name] = [argValue];
          argName = '';
        } else {
          argName = name;
        }
      } else {
        if (argName.isEmpty) {
          if (_multipleArgValue && _argEmpty.isNotEmpty) {
            _argEmpty.add(arg);
          } else {
            _argEmpty = [arg];
          }
        } else {
          if (_multipleArgValue && _args.containsKey(argName)) {
            _args[argName]!.add(arg);
          } else {
            _args[argName] = [arg];
          }
          if (!_multipleArgValue || singleArgFlag) argName = '';
        }
      }
    }
    if (argName.isNotEmpty && (!_multipleArgValue || !_args.containsKey(argName))) {
      _args[argName] = <String>[];
    }
  }

  bool contains(String flag) {
    if (_ignoreCase) flag = flag.toLowerCase();
    return _args.containsKey(flag);
  }

  bool multipleFlagContains(List<String> flags) {
    for (var flag in flags) {
      if (_ignoreCase) flag = flag.toLowerCase();
      if (_args.containsKey(flag)) return true;
    }
    return false;
  }

  bool containsValue(String flag) {
    if (_ignoreCase) flag = flag.toLowerCase();
    return _args.containsKey(flag) && _args[flag]!.isNotEmpty && _args[flag]!.first != '';
  }

  bool multipleFlagContainsValue(List<String> flags) {
    for (var flag in flags) {
      if (_ignoreCase) flag = flag.toLowerCase();
      if (_args.containsKey(flag) && _args[flag]!.isNotEmpty) return true;
    }
    return false;
  }

  String getValue(String flag, [String defaultValue = '']) {
    if (_ignoreCase) flag = flag.toLowerCase();
    if (!_args.containsKey(flag)) return defaultValue;
    if (_args[flag]!.isEmpty) return defaultValue;
    return _args[flag]?.first ?? defaultValue;
  }

  List<String> getMultipleValue(String flag, [List<String> defaultValue = const <String>[]]) {
    if (_ignoreCase) flag = flag.toLowerCase();
    if (!_args.containsKey(flag)) return defaultValue;
    if (_args[flag]!.isEmpty) return defaultValue;
    return _args[flag] ?? defaultValue;
  }

  String getMultipleFlagValue(List<String> flags, [bool useEmptyNameArg = false, String defaultValue = '']) {
    for (var flag in flags) {
      if (_ignoreCase) flag = flag.toLowerCase();
      if (_args.containsKey(flag)) return _args[flag]?.first ?? defaultValue;
    }
    if (useEmptyNameArg) return getEmptyNameArgValue(defaultValue);
    return defaultValue;
  }

  List<String> getMultipleFlagMultipleValue(List<String> flags,
      [bool useEmptyNameArg = false, List<String> defaultValue = const <String>[]]) {
    var result = <String>[];
    for (var flag in flags) {
      if (_ignoreCase) flag = flag.toLowerCase();
      if (_args.containsKey(flag)) {
        if (_multipleArgValue) {
          if (_args[flag] != null) result.addAll(_args[flag]!);
        } else {
          if (_args[flag] != null) result.add(_args[flag]!.first);
        }
      }
    }
    if (useEmptyNameArg) {
      if (_multipleArgValue) {
        if (_argEmpty.isNotEmpty) result.addAll(_argEmpty);
      } else {
        if (_argEmpty.isNotEmpty) result.add(_argEmpty.first);
      }
    }
    return result.isEmpty ? defaultValue : result;
  }

  String getEmptyNameArgValue([String defaultValue = '']) {
    return _argEmpty.isNotEmpty ? _argEmpty.first : defaultValue;
  }

  List<String> getEmptyNameArgMultipleValue([List<String> defaultValue = const <String>[]]) {
    return _argEmpty.isNotEmpty ? _argEmpty : defaultValue;
  }
}
