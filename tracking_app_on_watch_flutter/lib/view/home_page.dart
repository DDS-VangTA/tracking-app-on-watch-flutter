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
    locationViewModel.stepsCount = 0;
    locationViewModel.startTime = DateTime.now();
    locationViewModel.initPlatformState();
    locationViewModel.getLocationStreamData();
    locationViewModel.listenStepsSensorsCount();
  }

  void stopRecord() {
    locationViewModel.endTime = DateTime.now();
    locationViewModel.onResetData();
    locationViewModel.saveStepsPreData(locationViewModel.allSteps);
  }

  @override
  Widget build(BuildContext context) {
    locationViewModel = Provider.of<LocationViewModel>(context, listen: true);
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(32.0)),
            width: 200,
            height: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          (locationViewModel.distanceMoved / 1000)
                              .toStringAsFixed(2),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                    ),
                    Text(
                      'Km',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    Padding(padding: EdgeInsets.only(left: 8)),
                    Expanded(
                      child: Center(
                        child: Text(
                            '${locationViewModel.velocity.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                      ),
                    ),
                    Center(
                      child: Text('Km/h',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                      child: Text(locationViewModel.stepsCount.toString(),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    Center(
                      child: Text('record steps',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                      child: Text(locationViewModel.allSteps.toString(),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    Center(
                      child: Text(' daily steps',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                      child: Text(locationViewModel.stepsSensors.toString(),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    Center(
                      child: Text(' sensors steps',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                // Center(
                //   child: Text(
                //       "Current:\nlat:${locationViewModel.currentLocation?.latitude},\nlon:${locationViewModel.currentLocation?.longitude}"),
                // ),
                // Center(
                //   child: Text(
                //       "Last known:${locationViewModel.lastKnownLocation?.latitude},${locationViewModel.lastKnownLocation?.longitude}"),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          print('Start record');
                          startRecord();
                        },
                        child: Text("Start")),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(primary: Colors.red),
                          onPressed: () {
                            print('Stop record');
                            stopRecord();
                          },
                          child: Text("Stop")),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
