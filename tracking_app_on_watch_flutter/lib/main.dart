import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracking_app_on_watch_flutter/binding/home_page_binding.dart';
import 'package:tracking_app_on_watch_flutter/view/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialBinding: HomePageBinding(),
      initialRoute: '/home_page',
      getPages: [
        GetPage(
            page: () => HomePage(),
            name: '/home_page',
            binding: HomePageBinding()),
      ],
    );
  }
}
