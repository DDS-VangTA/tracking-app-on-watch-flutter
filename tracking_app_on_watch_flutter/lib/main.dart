import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app_on_watch_flutter/view/home_page.dart';
import 'package:tracking_app_on_watch_flutter/viewmodel/location_view_model.dart';

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => LocationViewModel())],
    child: Builder(builder: (context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: HomePage(),
      );
    }),
  ));
}
