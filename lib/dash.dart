import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:Twiv/services/auxilliary.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

import 'media_item.dart';

class Dash extends StatefulWidget {
  Dash({Key key}) : super(key: key);

  @override
  _MyState createState() => _MyState();
}

class _MyState extends State<Dash> {
  bool centerTitle = false;
  bool istyping = false;
  String url;
  String path;
  TextEditingController mcontrol = new TextEditingController();
  StreamController<List<File>> fcontrol = new StreamController();
  var taskId;
  var platform = const MethodChannel('dcinspirations.com/notifications');
  Map<dynamic, dynamic> sharedData = Map();
  String prevText='';
  int id = 0;
  final clipboardContentStream = StreamController<String>.broadcast();
  Timer clipboardTriggerTime;
  Stream get clipboardText => clipboardContentStream.stream;

  getPath()async{
    path = await localPath;
    setState(() {

    });
  }

  Future<List<File>> filesInDirectory(Directory dir) async {
    List<File> files = <File>[];
    await for (FileSystemEntity entity in dir.list(recursive: false, followLinks: false)) {
      FileSystemEntityType type = await FileSystemEntity.type(entity.path);
      if (type == FileSystemEntityType.file) {
        files.add(entity);
      }
    }
    return files;
  }

  initDownloader() async{
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize(
        debug: true // optional: set false to disable printing logs to console
    );
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
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
      if(status == DownloadTaskStatus.complete){
        Fluttertoast.showToast(msg: 'Download Complete');
      }else if(status == DownloadTaskStatus.failed){
        Fluttertoast.showToast(msg: 'An Error Occurred');
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  downloadFile(url) async {
    taskId = await FlutterDownloader.enqueue(
        url: url,
        fileName: '${DateTime.now().millisecondsSinceEpoch}',
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
          if(!text.contains('https://twitter.com/')){
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
    setState(() { sharedData = data;
    String text = data['text'];
    if(text!=null&&!text.contains('https://twitter.com/')){
      Fluttertoast.showToast(msg: 'Not a twitter url');
      return;
    }
    mcontrol.text = text;
    });

    // You can use sharedData in your build() method now
  }

  Future<Map> _getSharedData() async => await platform.invokeMethod('getSharedData');

  void setBackgroundChecks(String args){
    clipboardTriggerTime = Timer.periodic(
      const Duration(seconds: 5),
          (timer) {
        Clipboard.getData('text/plain').then((clipboarContent) {
          if(prevText!=clipboarContent.text+' $id'){
            prevText = clipboarContent.text+' $id';
            Fluttertoast.showToast(msg: 'i received it');
            clipboardContentStream.add(clipboarContent.text);
          }
        });
      },
    );
  }



  @override
  void initState() {
    getPath();
//    initDownloader();
//    initListeners();
    super.initState();
    _init();
    mcontrol.addListener(() {
      String val = mcontrol.text;
      if(val.isEmpty&&istyping){
        setState(() {
          istyping = false;
        });
      }
      if(val.isNotEmpty&&!istyping){
        setState(() {
          istyping = true;
        });
      }
    });



  }

  @override
  Widget build(BuildContext context) {
    double tbh = 190;
    return Scaffold(
      backgroundColor: aux1,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: aux1,
              iconTheme: IconThemeData(color: aux6),
              elevation: 0,
              expandedHeight: tbh,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                background: //
                    Stack(
                  children: <Widget>[
                    Container(
                      height: tbh-25,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(23)),
                        child: Image.asset(
                          'assets/bg2.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(left:23,right:23,top: 38,child: Row(
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
                                  color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w900, fontSize: 28),
                            ),
                            Text(
                              'twitter video downloader',
                              style: GoogleFonts.varelaRound(
                                  color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 17),
                            ),
                          ],
                        ),
                        InkWell(child: Icon(Icons.settings,color: Colors.white.withOpacity(0.85),size: 18,),)
                      ],
                    ),),
                    Positioned(
                      left: 28,
                      top: tbh-48,
                      right: 28,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(7.0)),
                          color: aux1,
                          boxShadow: [
                            BoxShadow(
                                color: aux42.withOpacity(.5),
                                offset: Offset(0.0, 1.1),
                                blurRadius: 8.0)
                          ],
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
                                  contentPadding: EdgeInsets.only(left: 10,right: 6),
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: 'Enter or paste tweet url',
                                    hintStyle: GoogleFonts.sourceSansPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87),
                                ),
                                style: GoogleFonts.sourceSansPro(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: aux4),
                                onSaved: (value)=>url=value,
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
                                onTap: ()=>mcontrol.clear(),
                                child: Padding(
                                  padding: const EdgeInsets.only(left:3.0,top: 5,right:7,bottom:5),
                                  child: Icon(Icons.close,color: aux42,size: 13,),
                                ),
                              ),
                            ),

                            Container(
                              height: double.maxFinite,
                              width: 50,
                              child: FlatButton(
                                onPressed: (){},
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.horizontal(right: Radius.circular(7))
                                  ),
                                color: aux4,
                                child:   Image.asset('assets/download.png',height: 14,width: 14,color: aux1,)
                              ),
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
                Text(
                  'Recently Downloaded',
                  style: GoogleFonts.varelaRound(
                      color: aux6, fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: path==null?Container(height: 80,width: 80,child: Center(child: Image.asset('assets/loading.gif',height: 30,width:30,)),):FutureBuilder<List<File>>(
          future: filesInDirectory(Directory(path)),
          builder: (_,snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return Container(height: 80,width: 80,child: Center(child: Image.asset('assets/loading.gif',height: 30,width:30,)),);
            }
            if(snapshot.hasData){
              List<File> modifiedList = snapshot.data;
              modifiedList.sort((a,b)=>b.lastModifiedSync().compareTo(a.lastModifiedSync()));
              return ListView(
                children: <Widget>[
                  for(final item in modifiedList) MediaItem(file: item)
                ],
              );
            }
            return Container(height: 10,width: 10,child: Center(child: Image.asset('assets/empty.png',color:aux41,height: 40,width:40,)),);
          },
        ),
      ),
    );
  }
}

class _SliverTextDelegate extends SliverPersistentHeaderDelegate {
  _SliverTextDelegate(this._text);

  final Text _text;

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      color: aux1,
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.only(left: 15.0,right:15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _text,
          SizedBox(height: 3,),
          Divider()
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTextDelegate oldDelegate) {
    return false;
  }
}
