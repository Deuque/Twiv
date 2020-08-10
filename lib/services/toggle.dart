import 'package:Twiv/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ZAnimatedToggle extends StatefulWidget {
  final List<String> values;
  final ValueChanged onToggleCallback;
  ZAnimatedToggle({
    Key key,
    @required this.values,
    @required this.onToggleCallback,
  }) : super(key: key);

  @override
  _ZAnimatedToggleState createState() => _ZAnimatedToggleState();
}

class _ZAnimatedToggleState extends State<ZAnimatedToggle> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
//      width: width * .7,
//      height: width * .13,
    width: 100,
      height: 30,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              widget.onToggleCallback(1);
            },
            child: Container(
              width: 100,
              height: 30,
              decoration: ShapeDecoration(
                  color: themeProvider.themeMode().toggleBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * .1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  widget.values.length,
                      (index) => Text(widget.values[index],style: GoogleFonts.varelaRound(
                          color: themeProvider.aux42, fontWeight: FontWeight.w400, fontSize: 13),),
                ),
              ),
            ),
          ),
          AnimatedAlign(
            alignment: themeProvider.isLightTheme
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: Duration(milliseconds: 350),
            curve: Curves.ease,
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                  color: themeProvider.themeMode().toggleButtonColor,
                  boxShadow: [themeProvider.myShadow],
                      borderRadius: BorderRadius.circular(width * .1)),
              child: Text(
                themeProvider.isLightTheme
                    ? widget.values[0]
                    : widget.values[1],
                style: GoogleFonts.varelaRound(
                    color: themeProvider.aux6, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }
}