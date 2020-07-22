import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auxilliary.dart';

class MyAlert extends StatelessWidget{

  final title,message;

  const MyAlert({Key key, this.title, this.message}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.start,
        style: GoogleFonts.roboto(
            color: aux6, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content:Text(
      message,
      textAlign: TextAlign.start,
      style: GoogleFonts.roboto(
      color: aux6, fontSize: 15, fontWeight: FontWeight.w400)),
      actions: <Widget>[
        FlatButton(
          child: Text(
              'continue',
              textAlign: TextAlign.start,
              style: GoogleFonts.roboto(
                  color: aux77, fontSize: 13, fontWeight: FontWeight.w300)),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        FlatButton(
          child: Text(
              'cancel',
              textAlign: TextAlign.start,
              style: GoogleFonts.roboto(
                  color: aux42, fontSize: 13, fontWeight: FontWeight.w400)),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        )
      ],
    );
  }

}