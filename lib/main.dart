import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // get remote config
  final remoteConfig = FirebaseRemoteConfig.instance;

  // set expiration
  await remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(minutes: 1), minimumFetchInterval: const Duration(seconds: 10)));

  // setup default values
  remoteConfig.setDefaults(<String, dynamic>{'message': 'just default message'});

  // get last config data
  final message = remoteConfig.getString('message');

  runApp(MyApp(message));
  // fetch and activate config data, data will be used in next restart
  bool updated = await remoteConfig.fetchAndActivate();
  if (updated) {
    print("the config has been updated, new parameter values are available");
  } else {
    print("the config values were previously updated.");
  }

  final newMessage = remoteConfig.getString('message');
  print("message is: $newMessage");
}

class MyApp extends StatelessWidget {
  final _title = 'Firebase Test App';
  final String text;
  const MyApp(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: _title, theme: ThemeData(primaryColor: Colors.red), home: Scaffold(appBar: AppBar(title: Text(_title)), body: Center(child: Text(text))));
  }
}
