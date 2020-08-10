import 'package:Twiv/services/theme_provider.dart';
import 'package:Twiv/services/toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider tp = Provider.of<ThemeProvider>(context);

    // function to toggle circle animation
    changeThemeMode(bool theme) {
      if (!theme) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.reverse(from: 1.0);
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: tp.isLightTheme?SystemUiOverlayStyle(
        statusBarColor: Colors.grey,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ):SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF26242e),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: tp.aux1,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.chevron_left,
              color: tp.aux6,
            ),
          ),
          elevation: 2,
          title: Text(
            'Settings',
            style: GoogleFonts.varelaRound(
                color: tp.aux6, fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 10,
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
                      changeThemeMode(tp.isLightTheme);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
