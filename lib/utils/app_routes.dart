import 'package:flutter/cupertino.dart';
import 'package:flutter_topics/ex_riverpod/ex_riverpod.dart';
import 'package:flutter_topics/main.dart';

import '../animations/ex_animations.dart';
import '../gemini_live/gemini_live.dart';

class AppRoutes{
  static const String exRiverPod = "/riverPod";
  static const String exAnimations = "/animations";
  static const String geminiLive = "/GeminiLive";

  static Map<String,WidgetBuilder> getRoutes() => {
       "/" : (c)=>Home(),
       exRiverPod : (c)=>ExRiverPod(),
       exAnimations : (c)=>ExAnimations(),
       geminiLive : (c)=>GeminiLive(),
  };
}