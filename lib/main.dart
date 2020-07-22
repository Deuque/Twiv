import 'dart:async';
import 'dart:isolate';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:Twiv/dash.dart';
//import 'package:system_alert_window/models/system_window_body.dart';
//import 'package:system_alert_window/models/system_window_footer.dart';
//import 'package:system_alert_window/system_alert_window.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Twiv',
      theme: ThemeData(
        primaryColorDark: Color(0xFF214478),
        primaryColor: Color(0xFF214478),
        accentColor: Color(0xFF214478),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Dash(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _platformVersion = 'Unknown';
  String prevText='';
  int id = 0;
  final clipboardContentStream = StreamController<String>.broadcast();
  Timer clipboardTriggerTime;
  Stream get clipboardText => clipboardContentStream.stream;
//
  var platform = const MethodChannel('dcinspirations.com/notifications');

//  initNotification()async{
//    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
//    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
//    var initializationSettingsIOS = IOSInitializaFlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;tionSettings();
//    var initializationSettings = InitializationSettings(
//        initializationSettingsAndroid, initializationSettingsIOS);
//    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//        onSelectNotification: selectNotification);
//
//    _createNotificationChannel();
//  }

//  Future selectNotification(String payload) async {
////    if (payload != null) {
////      debugPrint('notification payload: ' + payload);
////    }
//    Fluttertoast.showToast(msg: 'download started');
//    await flutterLocalNotificationsPlugin.cancel(0);
//  }

//  Future<void> _createNotificationChannel() async {
//    var androidNotificationChannel = AndroidNotificationChannel(
//      'TWIV1',
//      'TWIV NOT',
//      'TWIV NOTIFICATION',
//    );
//    await flutterLocalNotificationsPlugin
//        .resolvePlatformSpecificImplementation<
//        AndroidFlutterLocalNotificationsPlugin>()
//        ?.createNotificationChannel(androidNotificationChannel);
//
//  }

//  showNotification() async {
////    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
////        'TWIV1', 'TWIV NOT', 'TWIV NOTIFICATION',
////        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
////    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
////    var platformChannelSpecifics = NotificationDetails(
////        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
////    await flutterLocalNotificationsPlugin.show(
////        0, 'Tap to download media', prevText, platformChannelSpecifics,
////        payload: prevText);
////    id++;
//  }

    Future<void> showNotification() async {
      try {
        final String result = await platform.invokeMethod('showNotification', <String, String>{
          'message': prevText.substring(0,prevText.lastIndexOf(' '))
        });


        if(result=='downloadsssss'){
          Fluttertoast.showToast(msg: 'Downloading');
        }
      }
      on PlatformException catch (e) {
        // Unable to open the browser print(e);
      }
    }


  setBackgroundChecks(){
    clipboardTriggerTime = Timer.periodic(
      const Duration(seconds: 5),
          (timer) {
        Clipboard.getData('text/plain').then((clipboarContent) {
          if(prevText!=clipboarContent.text+' $id'){
            prevText = clipboarContent.text+' $id';
            showNotification();
            clipboardContentStream.add(clipboarContent.text);
          }
        });
      },
    );
  }

//  bool callBackFunction(String tag) {
//    print("Got tag " + tag);
//    SendPort port = IsolateManager.lookupPortByName();
//    port.send([tag]);
//    return true;
//  }
//
//  void callBack(String tag) {
//    print(tag);
//    switch (tag) {
//      case "download_btn":
//        SystemAlertWindow.closeSystemWindow();
//        break;
//      default:
//        Fluttertoast.showToast(msg: tag);
//        break;
//    }
//  }

  @override
  void initState() {
    super.initState();
//    setBackgroundChecks();
  }

  @override
  void dispose() {
  clipboardContentStream.close();

  clipboardTriggerTime.cancel();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('hey sexy lady')
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}



//class IsolateManager{
//
//  static const FOREGROUND_PORT_NAME = "foreground_port";
//
//  static SendPort lookupPortByName() {
//    return IsolateNameServer.lookupPortByName(FOREGROUND_PORT_NAME);
//  }
//
//  static bool registerPortWithName(SendPort port) {
//    assert(port != null, "'port' cannot be null.");
//    removePortNameMapping(FOREGROUND_PORT_NAME);
//    return IsolateNameServer.registerPortWithName(port, FOREGROUND_PORT_NAME);
//  }
//
//  static bool removePortNameMapping(String name) {
//    assert(name != null, "'name' cannot be null.");
//    return IsolateNameServer.removePortNameMapping(name);
//  }
//
//}

