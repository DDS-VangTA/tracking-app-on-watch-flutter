import 'package:flutter/material.dart';
import 'package:wear/wear.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: WatchShape(
            builder: (BuildContext context, WearShape shape, Widget? child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back_ios),
                  ),
                  Text(
                    'Shape: ${shape == WearShape.round ? 'round' : 'square'}',
                  ),
                  child!,
                ],
              );
            },
            child: AmbientMode(
              builder: (BuildContext context, WearMode mode, Widget? child) {
                return Text(
                  'Mode: ${mode == WearMode.active ? 'Active' : 'Ambient'}',
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tracking_app_on_watch_flutter/view/home_page.dart';
// import 'package:tracking_app_on_watch_flutter/viewmodel/location_view_model.dart';
//
// void main() {
//   runApp(MultiProvider(
//     providers: [ChangeNotifierProvider(create: (_) => LocationViewModel())],
//     child: Builder(builder: (context) {
//       return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Flutter Demo',
//         home: HomePage(),
//       );
//     }),
//   ));
// }
