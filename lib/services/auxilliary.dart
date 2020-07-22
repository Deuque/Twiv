import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';

// my colors
Color get aux1 => Color(0xFFFFFFFF);

Color get aux11 => Colors.white38;

Color get aux12 => Colors.white70;

Color get aux2 => Color(0xFFE61111);

Color get aux22 => Color(0xFFAF0D0D);

Color get aux3 => Color(0xFFEEA3A3);

Color get aux33 => Color(0xFFFCF4F4);

Color get aux4 => Color(0xFF435D6B);
Color get aux41 => Color(0xFFF2F5F8);
Color get aux42 => Colors.grey;

Color get aux5 => Color(0xFFFBFBFB);

Color get aux6 => Colors.black87;

Color get aux7 => Color(0xFFD4EBFE);
Color get aux77 => Color(0xFF1E88E5);

Color get aux8 => Color(0xFFE5E5E5);

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
void showToast(BuildContext context, text, {snackaction}) {
  final scaffold = Scaffold.of(context);
  scaffold.showSnackBar(
    SnackBar(
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.check_circle,
            color: aux1,
          ),
          SizedBox(
            width: 6,
          ),
          Text(
            text,
            textAlign: TextAlign.start,
            style: GoogleFonts.asap(
                color: aux1, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
      action: SnackBarAction(
          textColor: aux2, label: 'VIEW CART', onPressed: snackaction),
    ),
  );
}

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
        padding: EdgeInsets.all(15),
        child: CircularProgressIndicator(),
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
