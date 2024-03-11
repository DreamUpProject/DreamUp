import 'package:flutter/material.dart';

List<Errors> errorList = [];

class DebugPage extends StatefulWidget {
  const DebugPage({Key? key}) : super(key: key);

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'Debug Page',
        ),
      ),
      body: ListView(
        children: errorList
            .map<Widget>(
              (error) => Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.width * 0.025,
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        error.error,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${error.time.day}.${error.time.month} - ${error.time.hour}:${error.time.minute}',
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class Errors {
  final String error;
  final DateTime time;

  Errors({
    required this.error,
    required this.time,
  });
}
