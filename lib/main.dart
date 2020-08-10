import 'dart:async';
import 'dart:isolate';

import 'dart:ui';
import 'package:Twiv/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:Twiv/dash.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory =
      await pathProvider.getApplicationDocumentsDirectory();

  Hive.init(appDocumentDirectory.path);

  final settings = await Hive.openBox('settings');
  bool isLightTheme = settings.get('isLightTheme') ?? true;
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider(isLightTheme: isLightTheme)),
  ], child: AppStart()));

}

class AppStart extends StatelessWidget {
  const AppStart({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return MyApp(
      themeProvider: themeProvider,
    );
  }
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({Key key, @required this.themeProvider}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Twiv',
      theme: themeProvider.themeData().copyWith(textTheme: GoogleFonts.varelaRoundTextTheme(Theme.of(context).textTheme)),
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

