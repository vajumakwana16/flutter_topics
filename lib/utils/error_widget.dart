import 'package:flutter/material.dart';
import 'package:flutter_topics/utils/utils.dart';

class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const AppErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Error Report"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/"),
            icon: Icon(Icons.home),
          ),
        ],
      ),
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Utils.buildButton(title: "Back To Home", onPressed: () {}),
          Utils.buildButton(title: "Send", onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Oops! An error occurred.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(), // optional: show actual error
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Utils.addGap(gap: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}