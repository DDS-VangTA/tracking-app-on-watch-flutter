import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tracking_app_on_watch_flutter/model/record_status.dart';

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
      locationViewModel.timerStream = locationViewModel.stopWatchStream();
    });
  }

  void startRecord() {
    locationViewModel.stepsCount = 0;
    locationViewModel.startTime = DateTime.now();
    locationViewModel.initPlatformState();
    locationViewModel.getLocationStreamData();
    locationViewModel.onRecordStatusChanged(RecordStatus.RECORDING);
    startListenTimeMoving();
  }

  void pauseRecord() {
    locationViewModel.onRecordStatusChanged(RecordStatus.PAUSE);
    pauseListenTimeMoving();
  }

  void resumeRecord() {
    locationViewModel.onRecordStatusChanged(RecordStatus.RECORDING);
    resumeListenTimeMoving();
  }

  void finishRecord() {
    locationViewModel.endTime = DateTime.now();
    locationViewModel.onResetData();
    locationViewModel.saveStepsPreData(locationViewModel.allSteps);
    locationViewModel.onRecordStatusChanged(RecordStatus.NONE);
    stopListenTimeMoving();
  }

  void startListenTimeMoving() {
    locationViewModel.timerSubscription =
        locationViewModel.timerStream.listen((int newTick) {
      setState(() {
        locationViewModel.hoursStr =
            ((newTick / (60 * 60)) % 60).floor().toString().padLeft(2, '0');
        locationViewModel.minutesStr =
            ((newTick / 60) % 60).floor().toString().padLeft(2, '0');
        locationViewModel.secondsStr =
            (newTick % 60).floor().toString().padLeft(2, '0');
      });
    });
  }

  void stopListenTimeMoving() {
    locationViewModel.timerSubscription.cancel();
    // locationViewModel.timerStream.dispose();
    setState(() {
      locationViewModel.hoursStr = '00';
      locationViewModel.minutesStr = '00';
      locationViewModel.secondsStr = '00';
    });
  }

  void pauseListenTimeMoving() {
    locationViewModel.timerSubscription.pause();
  }

  void resumeListenTimeMoving() {
    print("call resume listen moving time");
    locationViewModel.timerSubscription.resume();
  }

  @override
  Widget build(BuildContext context) {
    locationViewModel = Provider.of<LocationViewModel>(context, listen: true);
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(32.0)),
            width: 200,
            height: 220,
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
                          '${locationViewModel.hoursStr}:${locationViewModel.minutesStr}:${locationViewModel.secondsStr}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    const Center(
                      child: Text('moving time',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          (locationViewModel.distanceMoved / 1000)
                              .toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                    ),
                    const Text(
                      'Km',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    const Padding(padding: EdgeInsets.only(left: 8)),
                    Expanded(
                      child: Center(
                        child: Text(
                            '${locationViewModel.velocity.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                      ),
                    ),
                    const Center(
                      child: Text('Km/h',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                      child: Text(locationViewModel.stepsCount.toString(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    const Center(
                      child: Text('record steps',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                      child: Text(locationViewModel.allSteps.toString(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    )),
                    const Center(
                      child: Text(' daily steps',
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
                const Padding(padding: EdgeInsets.only(top: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        onPressed: () {
                          print('Start record');
                          if (locationViewModel.recordStatus ==
                              RecordStatus.NONE) {
                            startRecord();
                          } else if (locationViewModel.recordStatus ==
                              RecordStatus.RECORDING) {
                            pauseRecord();
                          } else if (locationViewModel.recordStatus ==
                              RecordStatus.PAUSE) {
                            resumeRecord();
                          }
                        },
                        child: locationViewModel.recordStatus ==
                                RecordStatus.NONE
                            ? Text("Start", style: TextStyle(fontSize: 11))
                            : locationViewModel.recordStatus ==
                                    RecordStatus.RECORDING
                                ? Text("Pause", style: TextStyle(fontSize: 11))
                                : Text(
                                    "Resume",
                                    style: TextStyle(fontSize: 11),
                                  )),
                    locationViewModel.recordStatus == RecordStatus.PAUSE
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FloatingActionButton(
                                backgroundColor: Colors.red,
                                onPressed: () {
                                  print('Finish record');
                                  finishRecord();
                                },
                                child: const Text("Finish",
                                    style: TextStyle(fontSize: 11))),
                          )
                        : Container()
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
