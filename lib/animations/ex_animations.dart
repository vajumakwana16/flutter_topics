import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExAnimations extends StatelessWidget {
  const ExAnimations({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
          itemCount: 50,
          itemBuilder: (c,i){
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  style: ListTileStyle.drawer,
                  tileColor: Theme.of(context).highlightColor,
                  title: Text("Title $i").animate().fadeIn().slideX(duration: Duration(milliseconds: i*20))),
            );
          }),
    );
  }
}
