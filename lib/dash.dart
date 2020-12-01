import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:Twiv/services/ApiService.dart';
import 'package:Twiv/services/auxilliary.dart';
import 'package:Twiv/services/quality_provider.dart';
import 'package:Twiv/services/theme_provider.dart';
import 'package:Twiv/settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

import 'media_item.dart';

class Dash extends StatefulWidget {
  Dash({Key key}) : super(key: key);

  @override
  _MyState createState() => _MyState();
}

class _MyState extends State<Dash> with SingleTickerProviderStateMixin {
  bool centerTitle = false;
  bool istyping = false;
  bool initial = true;
  String url;
  String path;
  TextEditingController mcontrol = new TextEditingController();
  TextEditingController tcontrol = new TextEditingController();
  StreamController<List<File>> fcontrol = new StreamController();
  var taskId;
  var platform = const MethodChannel('dcinspirations.com/notifications');
  Map<dynamic, dynamic> sharedData = Map();
  String prevText = '';
  int id = 0;
  final GlobalKey<ScaffoldState> skey = new GlobalKey<ScaffoldState>();
  final clipboardContentStream = StreamController<String>.broadcast();
  Timer clipboardTriggerTime, checkDownloadTimer;
  int quality;
  AnimationController animationController;
  var pr;

  getPath() async {
    path = await initDownloadsDirectoryState();
    setState(() {});
  }

  Future<List<File>> filesInDirectory(Directory dir) async {
    List<File> files = <File>[];
    await for (FileSystemEntity entity
        in dir.list(recursive: false, followLinks: false)) {
      FileSystemEntityType type = await FileSystemEntity.type(entity.path);
      if (type == FileSystemEntityType.file) {
        files.add(entity);
      }
    }
    return files;
  }

  initDownloader() async {
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize(
        debug: true // optional: set false to disable printing logs to console
        );
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  initListeners() async {
    ReceivePort _port = ReceivePort();

    await IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (status == DownloadTaskStatus.complete) {
      } else if (status == DownloadTaskStatus.failed) {
        Fluttertoast.showToast(
            msg: 'An Error Occurred', toastLength: Toast.LENGTH_LONG);
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  downloadFile(String url) async {
    String ext = '';
    try {
      ext = url.substring(url.lastIndexOf('.'), url.indexOf('?'));
    } catch (e) {
      ext = url.substring(url.lastIndexOf('.'));
    }

    taskId = await FlutterDownloader.enqueue(
        url: url,
        fileName: '${DateTime.now().millisecondsSinceEpoch}$ext',
        savedDir: path,
        openFileFromNotification: true,
        showNotification: true);

    final tasks = await FlutterDownloader.loadTasks();
  }

  _init() async {
    // Case 1: App is already running in background:
    // Listen to lifecycle changes to subsequently call Java MethodHandler to check for shared data
    SystemChannels.lifecycle.setMessageHandler((msg) {
      if (msg.contains('resumed')) {
        _getSharedData().then((d) {
          if (d.isEmpty) return;
          String text = d['text'];
          if (!text.contains('https://twitter.com/')) {
            Fluttertoast.showToast(msg: 'Not a twitter url');
            return;
          }
          mcontrol.text = text;
          // Your logic here
          // E.g. at this place you might want to use Navigator to launch a new page and pass the shared data
        });
      }
      return Future.value('');
    });

    // Case 2: App is started by the intent:
    // Call Java MethodHandler on application start up to check for shared data
    var data = await _getSharedData();
    setState(() {
      sharedData = data;
      String text = data['text'];
      if (text != null && !text.contains('https://twitter.com/')) {
        Fluttertoast.showToast(msg: 'Not a twitter url');
        return;
      }
      mcontrol.text = text;
    });

    // You can use sharedData in your build() method now
  }

  Future<Map> _getSharedData() async =>
      await platform.invokeMethod('getSharedData');

  void setBackgroundChecks() {
    clipboardTriggerTime = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        Clipboard.getData('text/plain').then((clipboarContent) {
          if (prevText != clipboarContent.text + ' $id' &&
              clipboarContent.text.contains('https://twitter.com/')) {
            prevText = clipboarContent.text + ' $id';
            mcontrol.text = prevText;
//            if (initial) {
//              initial = false;
//            } else {
//              showNotification();
//            }
            showNotification();
          }
        });
      },
    );
  }

  Future<void> showNotification() async {
    try {
      final String result = await platform.invokeMethod(
          'showNotification', <String, String>{
        'message': prevText.substring(0, prevText.lastIndexOf(' '))
      });

      if (result == 'downloads') {
        if(!await Permission.storage.request().isGranted){
          return;
        }
        await ApiService.resolveUrl(mcontrol.text, quality).then((value) {

          if (value.error) {
            Fluttertoast.showToast(
                msg: value.errMessage, toastLength: Toast.LENGTH_LONG);
          } else if (value.data == 'null') {
            Fluttertoast.showToast(
                msg: 'Unable to retrieve data', toastLength: Toast.LENGTH_LONG);
          } else {
            downloadFile(value.data);
            Fluttertoast.showToast(
                msg: 'Downloading, Check notifications...',
                toastLength: Toast.LENGTH_LONG);
          }
        });
      }
    } on PlatformException catch (e) {
      // Unable to open the browser print(e);
    }
  }

  permissionHandler() async{
    await Permission.storage.request();
  }

  @override
  void initState() {
    permissionHandler();
    getPath();
//    initDownloader();
//    initListeners();
    super.initState();
    _init();
    initDownloader();
//    initListeners();
    setBackgroundChecks();
    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context);
    QualityProvider qp = Provider.of<QualityProvider>(context);
    quality = qp.quality;
    double tbh = MediaQuery.of(context).size.height*.25;
    pr = getDialog(context);
    void showToast(text,isloader, {snackaction}) {
      skey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF214478),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
             Visibility(
               visible: isloader,
               child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 30,
                  width: 30,
                  child: Center(
                      child: Image.asset(
                        'assets/loading.gif',
                        height: 30,
                        width: 30,
                      )),
                ),
             ),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.varelaRound(
                      color: Colors.white.withOpacity(.85),
                      fontWeight: FontWeight.w500,
                      fontSize: 15),
                ),
              ),
            ],
          ),
//      action: SnackBarAction(
//          textColor: aux2, label: 'VIEW CART', onPressed: snackaction),
        ),
      );
    }

    showSnackBar(text,{isloader=false}) {
      pr.hide();
      showToast(text,isloader);
      FocusScope.of(context).requestFocus(new FocusNode());
      pr.hide();
    }
    downloadClick(String text) async{
      if(!await Permission.storage.request().isGranted){
        showSnackBar(
            'Permissions not granted');
        return;
      }
      if (text.isNotEmpty) {

        await ApiService.resolveUrl(
            text, quality)
            .then((value) {
          if (value.error) {
            showSnackBar(value.errMessage);
            showNotification();
          } else if (value.data == 'null') {
            showSnackBar(
                'Unable to retrieve data');
          } else {
           // tcontrol.text = value.data;
            showSnackBar(
                'Downloading, Check notifications',isloader: true);
            downloadFile(value.data);
          }
        });
      }
    }

    return Scaffold(
      key: skey,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: tp.aux1,
              elevation: 0,
              expandedHeight: tbh,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                background: //
                    Stack(
                  children: <Widget>[
                    Container(
                      height: tbh - 30,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(30)),
                        child: Image.asset(
                          'assets/bg2.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 23,
                      right: 23,
                      top:48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Twiv',
                                textAlign: TextAlign.start,
                                style: GoogleFonts.varelaRound(
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28),
                              ),
                              Text(
                                'Download twitter videos',
                                style: GoogleFonts.varelaRound(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => Settings())).then((value) {
                              setState(() {});
                            }),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 11.0, top: 8, bottom: 8, right: 2),
                              child: Icon(
                                Icons.settings,
                                color: Colors.white.withOpacity(0.85),
                                size: 18,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
//                    Positioned(
//                      left: 28,
//                      top: tbh - 48,
//                      right: 28,
//                      child: Container(
//                        height: 48,
//                        decoration: BoxDecoration(
//                          borderRadius: BorderRadius.all(Radius.circular(7.0)),
//                          color: tp.aux1,
//                          boxShadow: [tp.myShadow],
//                        ),
//                        child: Row(
//                          children: <Widget>[
//                            Expanded(
//                              child: TextFormField(
//                                keyboardType: TextInputType.text,
//                                controller: mcontrol,
//                                maxLines: 1,
//                                textAlign: TextAlign.start,
//                                decoration: InputDecoration(
//                                  contentPadding:
//                                      EdgeInsets.only(left: 10, right: 6),
//                                  enabledBorder: InputBorder.none,
//                                  focusedBorder: InputBorder.none,
//                                  hintText: 'Enter or paste tweet url',
//                                  hintStyle: GoogleFonts.sourceSansPro(
//                                      fontSize: 16,
//                                      fontWeight: FontWeight.w400,
//                                      color: tp.aux6),
//                                ),
//                                style: GoogleFonts.sourceSansPro(
//                                    fontSize: 16,
//                                    fontWeight: FontWeight.w400,
//                                    color: tp.aux6),
//                                onSaved: (value) => url = value,
//                                validator: (String value) {
//                                  if (value.isEmpty) {
//                                    return 'Field required';
//                                  }
//                                },
//                              ),
//                            ),
//                            Visibility(
//                              visible: istyping,
//                              child: InkWell(
//                                onTap: () => mcontrol.clear(),
//                                child: Padding(
//                                  padding: const EdgeInsets.only(
//                                      left: 3.0, top: 5, right: 7, bottom: 5),
//                                  child: Icon(
//                                    Icons.close,
//                                    color: tp.aux42,
//                                    size: 13,
//                                  ),
//                                ),
//                              ),
//                            ),
//                            Container(
//                              height: double.maxFinite,
//                              width: 50,
//                              child: FlatButton(
//                                  onPressed: () async {
//
//                                  },
//                                  shape: RoundedRectangleBorder(
//                                      borderRadius: BorderRadius.horizontal(
//                                          right: Radius.circular(7))),
//                                  color: tp.aux4,
//                                  child: Image.asset(
//                                    'assets/download.png',
//                                    height: 14,
//                                    width: 14,
//                                    color: Colors.white.withOpacity(.90),
//                                  )),
//                            )
//                          ],
//                        ),
//                      ),
//                    ),
                    SearchBar(
                      downloadAction: downloadClick,
                      quality: quality,
                      onSaved: (value) => url = value,
                      mcontrol: mcontrol,
                    )
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTextDelegate(
                  text: Text(
                    'Recently Downloaded',
                    style: GoogleFonts.varelaRound(
                        color: tp.aux6,
                        fontWeight: FontWeight.w700,
                        fontSize: 17),
                  ),
                  refresh: () {
                    setState(() {});
                  },
              animationController: animationController),
              pinned: true,
              floating: true,
            ),
          ];
        },
        body: path == null
            ? Container(
          height: 80,
          width: 80,
          child: Center(
              child: Image.asset(
                'assets/loading.gif',
                height: 30,
                width: 30,
              )),
        )
            : FutureBuilder<List<File>>(
          future: filesInDirectory(Directory(path)),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 80,
                width: 80,
                child: Center(
                    child: Image.asset(
                      'assets/loading.gif',
                      height: 30,
                      width: 30,
                    )),
              );
            }
            if (snapshot.hasData&&snapshot.data.isNotEmpty) {
              List<File> modifiedList = snapshot.data;
              modifiedList.sort((a, b) =>
                  b.lastModifiedSync().compareTo(a.lastModifiedSync()));
              return ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 7),
                children: <Widget>[
                  for (final item in modifiedList) MediaItem(file: item,onDelete: (){
                    setState(() {

                    });
                  },)
                ],
              );
            }
            return Container(
              height: 10,
              width: 10,
              child: Center(
                  child: Image.asset(
                    'assets/empty.png',
                    color: tp.aux6.withOpacity(0.2),
                    height: 40,
                    width: 40,
                  )),
            );
          },
        ),

     // body:  TextFormField(
     //   keyboardType: TextInputType.text,
     //   controller: tcontrol,
     //   maxLines: 80,
     //   textAlign: TextAlign.start,
     //   decoration: InputDecoration(
     //     contentPadding:
     //     EdgeInsets.only(left: 10, right: 6),
     //     enabledBorder: InputBorder.none,
     //     focusedBorder: InputBorder.none,
     //     hintText: 'json body here',
     //     hintStyle: GoogleFonts.sourceSansPro(
     //         fontSize: 16,
     //         fontWeight: FontWeight.w400,
     //         color: tp.aux6),
     //   ),
     //   style: GoogleFonts.sourceSansPro(
     //       fontSize: 16,
     //       fontWeight: FontWeight.w400,
     //       color: tp.aux6),
     //   onSaved: (value) => url = value,
     //   validator: (String value) {
     //     if (value.isEmpty) {
     //       return 'Field required';
     //     }
     //   },
     // ),
      ),
    );
  }
}

class _SliverTextDelegate extends SliverPersistentHeaderDelegate {
  _SliverTextDelegate({this.text, this.refresh, this.animationController});

  final Text text;
  final refresh;
  final AnimationController animationController;

  @override
  double get minExtent => 85;

  @override
  double get maxExtent => 85;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context, listen: false);
    return new Container(
      color: tp.aux1,
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.only(left: 15.0, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text,
              InkWell(
                onTap: (){
                  animationController.reset();
                  animationController.forward();
                  refresh();
                },
                child:  AnimatedBuilder(
                    animation: animationController,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.refresh,
                        size: 17,
                      ),
                    ),
                    builder: (BuildContext context, Widget _widget) {
                      return new Transform.rotate(
                        angle: animationController.value * 6.3,
                        child: _widget,
                      );
                    },
                  )
              )
            ],
          ),
          Divider()
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTextDelegate oldDelegate) {
    return true;
  }
}

class SearchBar extends StatefulWidget {
  final downloadAction;
  final quality;
  final onSaved;
  final mcontrol;

  const SearchBar({Key key,  this.downloadAction,this.quality,this.onSaved,this.mcontrol}) : super(key: key);
  @override
  _SearchBarState createState() => _SearchBarState();
}




class _SearchBarState extends State<SearchBar> {
//  TextEditingController mcontrol = new TextEditingController();
  bool istyping=false;
  @override
  void initState() {
    super.initState();
    widget.mcontrol.addListener(() {
      String val = widget.mcontrol.text;
      if (val.isEmpty && istyping) {
        setState(() {
          istyping = false;
        });
      }
      if (val.isNotEmpty && !istyping) {
        setState(() {
          istyping = true;
        });
      }
    });

  }
  @override
  Widget build(BuildContext context) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context);
    double tbh = MediaQuery.of(context).size.height*.25;
    return Positioned(
      left: 28,
      top: tbh - 54,
      right: 28,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(7.0)),
          color: tp.aux1,
          boxShadow: [tp.myShadow],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.text,
                controller: widget.mcontrol,
                maxLines: 1,
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  contentPadding:
                  EdgeInsets.only(left: 10, right: 6),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Enter or paste tweet url',
                  hintStyle: GoogleFonts.sourceSansPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: tp.aux6),
                ),
                style: GoogleFonts.sourceSansPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: tp.aux6),
                onSaved: widget.onSaved,
                validator: (String value) {
                  if (value.isEmpty) {
                    return 'Field required';
                  }
                },
              ),
            ),
            Visibility(
              visible: istyping,
              child: InkWell(
                onTap: () => widget.mcontrol.clear(),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 3.0, top: 5, right: 7, bottom: 5),
                  child: Icon(
                    Icons.close,
                    color: tp.aux42,
                    size: 13,
                  ),
                ),
              ),
            ),
            Container(
              height: double.maxFinite,
              width: 50,
              child: FlatButton(
                  onPressed: () async {
                   widget.downloadAction(widget.mcontrol.text);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(7))),
                  color: tp.aux4,
                  child: Image.asset(
                    'assets/download.png',
                    height: 14,
                    width: 14,
                    color: Colors.white.withOpacity(.90),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
