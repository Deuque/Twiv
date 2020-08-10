import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class ThemeProvider with ChangeNotifier {
  bool isLightTheme;

  ThemeProvider({this.isLightTheme});

  // the code below is to manage the status bar color when the theme changes
  getCurrentStatusNavigationBarColor() {
//    if (isLightTheme) {
//      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//        statusBarColor: Colors.grey,
//        statusBarBrightness: Brightness.light,
//        statusBarIconBrightness: Brightness.dark,
//        systemNavigationBarColor: Color(0xFFFFFFFF),
//        systemNavigationBarIconBrightness: Brightness.dark,
//      ));
//    } else {
//      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//        statusBarColor: Colors.transparent,
//        statusBarBrightness: Brightness.dark,
//        statusBarIconBrightness: Brightness.light,
//        systemNavigationBarColor: Color(0xFF26242e),
//        systemNavigationBarIconBrightness: Brightness.light,
//      ));
//    }
  }

  // use to toggle the theme
  toggleThemeData() async {
    final settings = await Hive.openBox('settings');
    settings.put('isLightTheme', !isLightTheme);
    isLightTheme = !isLightTheme;
    getCurrentStatusNavigationBarColor();
    notifyListeners();
  }

  // Global theme data we are always check if the light theme is enabled #isLightTheme
  ThemeData themeData() {
    return ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
//      primarySwatch: isLightTheme ? Colors.grey : Colors.grey,
//      primaryColor: isLightTheme ? Colors.white : Color(0xFF1E1F28),
      primaryColorDark: Color(0xFF214478),
      primaryColor: Color(0xFF214478),
      accentColor: Color(0xFF214478),
      brightness: isLightTheme ? Brightness.light : Brightness.dark,
      backgroundColor: isLightTheme ? Color(0xFFFFFFFF) : Color(0xFF26242e),
      scaffoldBackgroundColor:
      isLightTheme ? Color(0xFFFFFFFF) : Color(0xFF26242e),

    );
  }

  Color get aux1 => isLightTheme?Color(0xFFFFFFFF):Color(0xFF26242e);
  Color get aux2 => Color(0xFF214478);
  Color get aux4 => Color(0xFF435D6B);
  Color get aux41 => isLightTheme?Color(0xFFF2F5F8):Colors.grey;
  Color get aux42 => Colors.grey;
  Color get aux6 => isLightTheme?Colors.black87:Colors.white70;

  BoxShadow get myShadow => BoxShadow(
      color: isLightTheme?aux42.withOpacity(.5):Colors.black.withOpacity(.5),

      offset: Offset(0.2, 1.1),
      blurRadius: 8.0);

  // Theme mode to display unique properties not cover in theme data
  ThemeColor themeMode() {
    return ThemeColor(
      gradient: [
        if (isLightTheme) ...[Color(0xDDFF0080), Color(0xDDFF8C00)],
        if (!isLightTheme) ...[Color(0xFF8983F7), Color(0xFFA3DAFB)]
      ],
      textColor: isLightTheme ? Color(0xFF000000) : Color(0xFFFFFFFF),
      toggleButtonColor: isLightTheme ? Color(0xFFFFFFFF) : aux2 ,
      toggleBackgroundColor:
      isLightTheme ? Color(0xFFe7e7e8) : Color(0xFF222029),
      shadow: [
        if (isLightTheme)
          BoxShadow(
              color: Color(0xFFd8d7da),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 5)),
        if (!isLightTheme)
          BoxShadow(
              color: Color(0x66000000),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 5))
      ],
    );
  }
}

// A class to manage specify colors and styles in the app not supported by theme data
class ThemeColor {
  List<Color> gradient;
  Color backgroundColor;
  Color toggleButtonColor;
  Color toggleBackgroundColor;
  Color textColor;
  List<BoxShadow> shadow;

  ThemeColor({
    this.gradient,
    this.backgroundColor,
    this.toggleBackgroundColor,
    this.toggleButtonColor,
    this.textColor,
    this.shadow,
  });
}

// Provider finished