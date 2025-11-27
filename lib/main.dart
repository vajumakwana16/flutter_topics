import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter_topics/ex_riverpod/ex_riverpod.dart';
import 'package:flutter_topics/utils/error_widget.dart';
import 'package:flutter_topics/utils/utils.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'utils/app_routes.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    print("Error : ${details.exceptionAsString()}");
    return AppErrorWidget(details: details);
  };
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        navigatorKey: Utils.navKey,
        title: 'Flutter Demo',
        theme: getTheme(context),
        routes: AppRoutes.getRoutes(),
        debugShowCheckedModeBanner: false,
        initialRoute: "/",
        // home: Home(),
      ),
    );
  }

  ThemeData? getTheme(c) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
    appBarTheme: AppBarTheme(
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(c).textTheme.titleLarge!.copyWith(color: Colors.white,fontWeight: FontWeight.bold),
        backgroundColor: Colors.cyan),
    textTheme: TextTheme(
      titleMedium: TextStyle(fontFamily: 'lato', fontWeight: FontWeight.w400),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  static const List items = [
    ["RiverPod", AppRoutes.exRiverPod],
    ["exAnimations", AppRoutes.exAnimations],
    ["GeminiLive", AppRoutes.geminiLive],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Learning Flutter")),
      body: SafeArea(
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                tileColor: Colors.cyan.shade500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                title: Text(item[0],style: TextStyle(color: Colors.white)),
                onTap: () =>
                    Navigator.pushNamed(Utils.navKey.currentContext!, item[1]),
                trailing: Icon(Icons.arrow_forward_ios_outlined,color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}