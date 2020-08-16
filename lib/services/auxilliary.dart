import 'dart:io';

import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';

// my colors
Color get mytrans => Color(0x99000000);


//date formatter
dateFormatter(String time) {
  DateTime timestamp = DateTime.parse(time);
  var dateformat = new DateFormat.yMMMMd("en_US");
  return dateformat.format(timestamp);
}

dateFormatter2(String time) {
  DateTime timestamp = DateTime.parse(time);
  var dateformat = new DateFormat('MMM dd, yy');
  var dateformat2 = new DateFormat('hh:mma');
  return dateformat.format(timestamp)+' at '+dateformat2.format(timestamp).toLowerCase();
}

//toast builder
//void showToast(BuildContext context, text, {snackaction}) {
//  final scaffold = Scaffold.of(context);
//  scaffold.showSnackBar(
//    SnackBar(
//      backgroundColor: Color(0xFF214478),
//      behavior: SnackBarBehavior.floating,
//      shape: RoundedRectangleBorder(
//        borderRadius: BorderRadius.circular(8)
//      ),
//      content: Row(
//        crossAxisAlignment: CrossAxisAlignment.center,
//        children: <Widget>[
//          Text(
//            text,
//            textAlign: TextAlign.start,
//            style: GoogleFonts.varelaRound(
//                color: Colors.white.withOpacity(.85), fontWeight: FontWeight.w500, fontSize: 15),
//          ),
//        ],
//      ),
////      action: SnackBarAction(
////          textColor: aux2, label: 'VIEW CART', onPressed: snackaction),
//    ),
//  );
//}

//money resolver
moneyResolver(String s) {
  String newamount = s.substring(0, 1);
  List sarray = s.split('');
  for (int a = 1; a < sarray.length; a++) {
    if ((sarray.length - a) != 0 && (sarray.length - a) % 3 == 0) {
      newamount = newamount + "," + sarray[a];
      continue;
    }
    newamount = newamount + sarray[a];
  }
  return newamount;
}

// my progress dialog
ProgressDialog getDialog(BuildContext context) {
  var pr = ProgressDialog(context,
      type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
  pr.style(
      message: 'Please wait..',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: Container(
                      height: 40,
                      width: 40,
                      child: Center(
                          child: Image.asset(
                        'assets/loading.gif',
                        height: 30,
                        width: 30,
                      )),
                    ),

      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress: 0.0,
      maxProgress: 100.0,
      messageTextStyle: GoogleFonts.poppins(
          color: Colors.black, fontSize: 14.0, fontWeight: FontWeight.w600));
  return pr;
}

extension FileExtention on FileSystemEntity{
  String get name {
    return this?.path?.split("/")?.last;
  }
  String get extension {
    return this.path?.substring(this.path.lastIndexOf('.')+1);
  }
}

//file direcory
Future<String> get localPath async {
  final directory = await getExternalStorageDirectory();
  final savedDir = Directory(directory.path+'/media');
  bool hasExisted = await savedDir.exists();
  if (!hasExisted) {
    savedDir.create();
  }

  return directory.path+'/media';
}
Future<String> initDownloadsDirectoryState() async {
  Directory downloadsDirectory;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
  } on PlatformException {
    print('Could not get the downloads directory');
  }
  final savedDir = Directory(downloadsDirectory.path+'/Twiv');
  bool hasExisted = await savedDir.exists();
  if (!hasExisted) {
    savedDir.create();
  }

  return savedDir.path;
      }