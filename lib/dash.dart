import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:Twiv/services/ApiService.dart';
import 'package:Twiv/services/theme_provider.dart';
import 'package:Twiv/services/toggle.dart';
import 'package:Twiv/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:Twiv/services/auxilliary.dart';

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
  Timer clipboardTriggerTime,checkDownloadTimer;

  getPath() async {
    path = await localPath;
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
        Fluttertoast.showToast(msg: 'Download Complete',toastLength: Toast.LENGTH_LONG);
      } else if (status == DownloadTaskStatus.failed) {
        Fluttertoast.showToast(msg: 'An Error Occurred',toastLength: Toast.LENGTH_LONG);
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  downloadFile(String url) async {
    String ext = '';
    try{
      ext = url.substring(url.lastIndexOf('.'),url.indexOf('?'));
    }catch(e){
      ext = url.substring(url.lastIndexOf('.'));
    }
    taskId = await FlutterDownloader.enqueue(
        url: url,
        fileName: '${DateTime.now().millisecondsSinceEpoch}$ext',
        savedDir: path,
        openFileFromNotification: false,
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
          if (prevText != clipboarContent.text + ' $id' && clipboarContent.text.contains('https://twitter.com/')) {
            prevText = clipboarContent.text + ' $id';
            mcontrol.text = prevText;
            if(initial){
              initial = false;
            }else{
              showNotification();
            }
          }
        });
      },
    );
  }

  Future<void> showNotification() async {
    try {
      final String result = await platform.invokeMethod('showNotification', <String, String>{
        'message': prevText.substring(0,prevText.lastIndexOf(' '))
      });


      if(result=='downloads'){

        await ApiService.resolveUrl(mcontrol.text).then((value) {

          if(value.error){
            Fluttertoast.showToast(msg: value.errMessage, toastLength: Toast.LENGTH_LONG);
          }else if(value.data == 'null'){
            Fluttertoast.showToast(msg: 'Unable to retrieve data', toastLength: Toast.LENGTH_LONG);
          }else{
//            checkIfDownloaded();
            downloadFile(value.data);
            Fluttertoast.showToast(msg: 'Downloading, Check notifications...', toastLength: Toast.LENGTH_LONG);
          }

        });
      }
    }
    on PlatformException catch (e) {
      // Unable to open the browser print(e);
    }
  }

  @override
  void initState() {
    getPath();
//    initDownloader();
//    initListeners();
    super.initState();
    _init();
    initDownloader();
    mcontrol.addListener(() {
      String val = mcontrol.text;
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
    setBackgroundChecks();
  }



  @override
  Widget build(BuildContext context) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context);
    double tbh = 180;
    var pr = getDialog(context);
    void _bottomSheet() {
      showModalBottomSheet(
          backgroundColor: tp.aux1,
          isScrollControlled: true,
          isDismissible: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
          ),
          context: context,
          builder: (context) => StatefulBuilder(
                builder: (context, setState1) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Settings',
                            style: GoogleFonts.varelaRound(
                                color: tp.aux6,
                                fontWeight: FontWeight.w700,
                                fontSize: 17),
                          ),
                          Divider(),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Dark Mode',
                                style: GoogleFonts.varelaRound(
                                    color: tp.aux6,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15),
                              ),
                              ZAnimatedToggle(
                                values: ['Off', 'On'],
                                onToggleCallback: (v) async {
                                  await tp.toggleThemeData();
                                  setState(() {});
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ));
    }
    void showToast(text, {snackaction}) {
      skey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF214478),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                textAlign: TextAlign.start,
                style: GoogleFonts.varelaRound(
                    color: Colors.white.withOpacity(.85), fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ],
          ),
//      action: SnackBarAction(
//          textColor: aux2, label: 'VIEW CART', onPressed: snackaction),
        ),
      );
    }
    showSnackBar(text){
      showToast(text);
      FocusScope.of(context).requestFocus(new FocusNode());
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
                      height: tbh - 25,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(23)),
                        child: Image.asset(
                          'assets/bg2.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 23,
                      right: 23,
                      top: 38,
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
                                'twitter video downloader',
                                style: GoogleFonts.varelaRound(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => Settings()))
                                .then((value) {setState(() {

                                });}),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white.withOpacity(0.85),
                              size: 18,
                            ),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      left: 28,
                      top: tbh - 48,
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
                                controller: mcontrol,
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
                                onSaved: (value) => url = value,
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
                                onTap: () => mcontrol.clear(),
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
                                  onPressed: () async{
                                    if(mcontrol.text.isNotEmpty){
                                      pr.show();
                                      await ApiService.resolveUrl(mcontrol.text).then((value) {
                                        pr.hide();

                                        if(value.error){
                                          showSnackBar(value.errMessage);
                                        }else if(value.data == 'null'){
                                          showSnackBar('Unable to retrieve data');
                                        }else{
                                          downloadFile(value.data);
                                          showSnackBar('Downloading, Check notifications...');
                                        }

                                      });
                                    }
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
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTextDelegate(
                text:Text(
                  'Recently Downloaded',
                  style: GoogleFonts.varelaRound(
                      color: tp.aux6,
                      fontWeight: FontWeight.w700,
                      fontSize: 17),
                ),
                 refresh: (){
                  setState(() {

                  });
                  }
              ),
              pinned: true,
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
                  if (snapshot.hasData) {
                    List<File> modifiedList = snapshot.data;
                    modifiedList.sort((a, b) =>
                        b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                    return ListView(
                      children: <Widget>[
                        for (final item in modifiedList) MediaItem(file: item)
                      ],
                    );
                  }
                  return Container(
                    height: 10,
                    width: 10,
                    child: Center(
                        child: Image.asset(
                      'assets/empty.png',
                      color: tp.aux41,
                      height: 40,
                      width: 40,
                    )),
                  );
                },
              ),

//      body:  TextFormField(
//        keyboardType: TextInputType.text,
//        controller: tcontrol,
//        maxLines: 80,
//        textAlign: TextAlign.start,
//        decoration: InputDecoration(
//          contentPadding:
//          EdgeInsets.only(left: 10, right: 6),
//          enabledBorder: InputBorder.none,
//          focusedBorder: InputBorder.none,
//          hintText: 'Enter or paste tweet url',
//          hintStyle: GoogleFonts.sourceSansPro(
//              fontSize: 16,
//              fontWeight: FontWeight.w400,
//              color: tp.aux6),
//        ),
//        style: GoogleFonts.sourceSansPro(
//            fontSize: 16,
//            fontWeight: FontWeight.w400,
//            color: tp.aux6),
//        onSaved: (value) => url = value,
//        validator: (String value) {
//          if (value.isEmpty) {
//            return 'Field required';
//          }
//        },
//      ),
      ),
    );
  }
}

class _SliverTextDelegate extends SliverPersistentHeaderDelegate {
  _SliverTextDelegate({this.text,this.refresh});

  final Text text;
  final refresh;

  @override
  double get minExtent => 75;

  @override
  double get maxExtent => 75;

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
          SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text,
              InkWell(onTap: refresh,child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(Icons.refresh,size: 17,),
              ),)
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
