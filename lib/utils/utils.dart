import 'package:flutter/material.dart';

class Utils {
  static GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  //snackBar
  static showMsg({msg}) {
    SnackBar snackBar = SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(8.0).copyWith(
        bottom: MediaQuery.sizeOf(navKey.currentContext!).height * 0.8,
      ),
    );
    ScaffoldMessenger.of(navKey.currentContext!).showSnackBar(snackBar);
  }

  //add gap
  static addGap({gap,isHorizontal = false}) {
    return isHorizontal ? SizedBox(width: double.parse(gap.toString())) : SizedBox(height: double.parse(gap.toString()));
  }

  static buildButton({title,onPressed})=>ElevatedButton(onPressed: onPressed, child: Text(title));


}