/*
 * Copyright (C) 2023-present The WebF authors. All rights reserved.
 */


import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:webf/webf.dart';
import 'utils/sleep.dart';

String? pass = (AnsiPen()..green())('[TEST PASS]');
String? err = (AnsiPen()..red())('[TEST FAILED]');

final String __dirname = path.dirname(Platform.script.path);
final String testDirectory = Platform.environment['WEBF_TEST_DIR'] ?? __dirname;
final GlobalKey<RootPageState> rootPageKey = GlobalKey();

final String specFolder = 'pre_rendering_specs';
final specDir = Directory(path.join(testDirectory, specFolder));
final List<FileSystemEntity> specs = specDir.listSync();
final List<CodeUnit> codes = specs.map((spec) {
  final fileName = getFileName(spec.path);
  final List<FileSystemEntity> files = Directory(spec.path).listSync();

  bool haveEntry = files.any((entity) => entity.path.contains('index.html'));
  if (!haveEntry) {
    throw FlutterError('Can not find index.html in spec dir');
  }

  return CodeUnit(fileName, path.join(spec.path, 'index.html'));
}).toList();
PageController pageController = PageController();

// Test for UriParser.
class IntegrationTestUriParser extends UriParser {
  @override
  Uri resolve(Uri base, Uri relative) {
    if (base.toString().isEmpty && relative.path.startsWith('assets/')) {
      return Uri.file(relative.path);
    } else {
      return super.resolve(base, relative);
    }
  }
}

class PreRenderingPageState extends State<PreRenderingPage> {
  BuildContext? _context;
  WebFController controller;

  PreRenderingPageState(this.controller);

  void navigateBack() {
    Navigator.pop(_context!);
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return WebF(
      controller: controller,
      bundle: WebFBundle.fromUrl('file://${widget.path}'),
    );
  }
}

class PreRenderingPage extends StatefulWidget {
  final String path;
  final String name;
  final WebFController controller;

  PreRenderingPage(this.controller, this.name, this.path, {super.key});

  @override
  State<StatefulWidget> createState() {
    var state = PreRenderingPageState(controller);
    return state;
  }
}

class MultiplePageKey extends LabeledGlobalKey<PreRenderingPageState> {
  final String name;
  MultiplePageKey(this.name): super('$name');

  @override
  bool operator ==(other) {
    return other is MultiplePageKey && other.name == name;
  }

  @override
  int get hashCode => super.hashCode;
}

class PageController {
  Map<String, MultiplePageKey> _keys = {};

  MultiplePageKey createKey(String name) {
    MultiplePageKey key = MultiplePageKey(name);
    _keys[name] = key;
    return key;
  }

  PreRenderingPageState? state(String name) => _keys[name]!.currentState;
}

class RootPage extends StatefulWidget {
  RootPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return RootPageState();
  }
}

class RootPageState extends State<RootPage> {
  BuildContext? _context;
  Future<void> navigateToPage(String nextPage) {
    return Navigator.pushNamed(_context!, '/$nextPage');
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Center(child: Text('root'));
  }
}

class CodeUnit {
  final String name;
  final String path;
  CodeUnit(this.name, this.path);
}

Map<String, WidgetBuilder> buildRoutes(WebFController controller, PageController pageController, List<CodeUnit> codes) {
  Map<String, WidgetBuilder> routes = {};
  codes.forEach((code) {
    routes['/${code.name}'] = (context) => Scaffold(
      body: Scaffold(
          appBar: AppBar(title: Text(code.name)),
          body: PreRenderingPage(controller, code.name, code.path, key: pageController.createKey(code.name))
      ),
    );
  });
  routes['/'] = (context) => Scaffold(
      body: FirstRoute(key: rootPageKey)
  );
  return routes;
}

String getFileName(String path) {
  return path.split('/').last;
}

ContentType getFileContentType(String fileName) {
  if (fileName.contains('.html')) {
    return htmlContentType;
  }
  if (fileName.contains('.kbc')) {
    return webfBc1ContentType;
  }
  return javascriptContentType;
}

Future<void> runWithMultiple(AsyncCallback callback, int multipleTime) async {
  for (int i = 0; i < multipleTime; i ++) {
    await callback();
  }
}

class HomePageElement extends StatelessElement {
  HomePageElement(super.widget);

  static CodeUnit current = codes.first;
  static int currentIndex = 0;

  @override
  void mount(Element? parent, Object? newSlot) async {
    super.mount(parent, newSlot);

    await runWithMultiple(() async {
      await sleep(Duration(seconds: 1));
      Navigator.pushNamed(this, '/' + current.name);
      await sleep(Duration(seconds: 1));
      Navigator.pop(this);

      if (currentIndex < codes.length - 1) {
        current = codes[currentIndex + 1];
        currentIndex = currentIndex + 1;
      }

      await sleep(Duration(seconds: 1));
      // bool isLeaked = isMemLeaks(mems);
      //
      // print('memory leaks: ${isMemLeaks(mems)} $mems');
      // if (isLeaked) {
      //   exit(1);
      // }
      // mems.clear();
    }, codes.length);
  }
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  @override
  StatelessElement createElement() {
    return HomePageElement(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PreRendering'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Open route'),
          onPressed: () {
            Navigator.pushNamed(context, '/' + codes.first.name);
          },
        ),
      ),
    );
  }
}

typedef onPushCallback = void Function();
typedef onPopCallback = void Function();

class PreRenderingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
  }

// Add other overrides if you need them, like didReplace or didRemove
}

class PreRendering extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PreRenderingState();
  }
}

class PreRenderingState extends State<PreRendering> {
  late WebFController controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = WebFController(context,
      viewportWidth: 360,
      viewportHeight: 640,
      uriParser: IntegrationTestUriParser(),
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        PreRenderingNavigatorObserver()
      ],
      routes: buildRoutes(controller, pageController, codes),
    );
  }
}

void main() {
  runApp(PreRendering());
}
