import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/location_view_model.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late LocationViewModel locationViewModel;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationViewModel.checkLocationService();
    });
  }

  void startRecord() {
    locationViewModel.getLocationStreamData();
  }

  @override
  Widget build(BuildContext context) {
    locationViewModel = Provider.of<LocationViewModel>(context, listen: true);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                Center(
                  child: Text('${locationViewModel.distanceMoved.toString()} Km',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ),
                VerticalDivider(width: 100,),
                Center(
                  child: Text('${locationViewModel.velocity.toString()} Km/h',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ),
              ],
            ),
            Divider(height: 1),
            Center(
              child: Text('${locationViewModel.steps.toString()} steps',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
            Center(
              child: Text(
                  "Current location:${locationViewModel.currentLocation?.latitude},${locationViewModel.currentLocation?.longitude}"),
            ),
            Center(
              child: Text(
                  "Last known location:${locationViewModel.lastKnownLocation?.latitude},${locationViewModel.lastKnownLocation?.longitude}"),
            ),
            ElevatedButton(
                onPressed: () {
                  print('Start record');
                  startRecord();
                },
                child: Text("Start")),
            ElevatedButton(
                onPressed: () {
                  print('Stop record');
                  startRecord();
                },
                child: Text("Stop"))
          ],
        ),
      ),
    );
  }
}
