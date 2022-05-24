import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracking_app_on_watch_flutter/controller/localtionController.dart';

class HomePage extends GetWidget {
  LocationController locationController = Get.find();

  void startRecord() {
    locationController.getLocationStreamData();
  }

  @override
  Widget build(BuildContext context) {
    locationController.checkLocationService();
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Center(
                child: Obx(
              () => Text(
                  "Current location:${locationController.currentLocation?.value.latitude},${locationController.currentLocation?.value.longitude}"),
            )),
            Center(
                child: Obx(
              () => Text(
                  "Last known location:${locationController.lastKnownLocation?.value.latitude},${locationController.lastKnownLocation?.value.longitude}"),
            )),
            ElevatedButton(
                onPressed: () {
                  print('Start record');
                  startRecord();
                },
                child: Text("Start"))
          ],
        ),
      ),
    );
  }
}
