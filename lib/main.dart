import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();
  List records = [];
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Webview App"),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  webViewController?.goBack();
                });
              },
              icon: Icon(Icons.arrow_back)),
          const SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: () async {
                setState(() {
                  if (Platform.isAndroid) {
                    webViewController?.reload();
                  } else if (Platform.isIOS) {
                    webViewController?.loadUrl(
                        urlRequest: URLRequest(
                            url: Uri.parse("${webViewController?.getUrl()}")));
                  }
                });
              },
              icon: Icon(Icons.refresh)),
          const SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  webViewController?.goForward();
                });
              },
              icon: Icon(Icons.arrow_forward)),
          const SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  pullToRefreshController.endRefreshing();
                });
              },
              icon: Icon(Icons.close)),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: SafeArea(
          child: Column(children: <Widget>[
        TextField(
          decoration: InputDecoration(
              border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
          controller: urlController,
          onSubmitted: (value) async {
            Uri uri = Uri.parse(value);
            if (uri.scheme.isEmpty) {
              uri = Uri.parse("https://www.google.com/search?q=" + value);
            }
            await webViewController?.loadUrl(urlRequest: URLRequest(url: uri));
          },
        ),
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest:
                    URLRequest(url: Uri.parse("https://www.google.com/")),
                initialOptions: options,
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, uri) {
                  setState(() {
                    urlController.text =
                        uri!.scheme.toString() + "://" + uri.host + uri.path;
                  });
                },
                androidOnPermissionRequest:
                    (controller, origin, resources) async {
                  return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT);
                },
                onLoadStop: (controller, uri) async {
                  pullToRefreshController.endRefreshing();
                  setState(() {
                    urlController.text =
                        uri!.scheme.toString() + "://" + uri.host + uri.path;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  pullToRefreshController.endRefreshing();
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100) {
                    pullToRefreshController.endRefreshing();
                  }
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
              ),
              progress < 1.0
                  ? LinearProgressIndicator(value: progress)
                  : Container(),
            ],
          ),
        ),
      ])),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              Uri? uri = await webViewController!.getUrl();

              String myurl =
                  uri!.scheme.toString() + "://" + uri.host + uri.path;

              setState(() {
                records.add(myurl);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Successfully Bookmarked")));
            },
            child: Icon(Icons.bookmark),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Center(
                        child: Text("My Bookmark"),
                      ),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: records
                            .map((e) => Padding(
                                  padding: EdgeInsets.all(10),
                                  child: InkWell(
                                      onTap: () async {
                                        await webViewController!.loadUrl(
                                            urlRequest:
                                                URLRequest(url: Uri.parse(e)));
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(e)),
                                ))
                            .toList(),
                      ),
                    );
                  });
            },
            child: Icon(Icons.apps),
          ),
        ],
      ),
    );
  }
}
