import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as locationPre;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../base/viewmodel.dart';
import '../utilitis/number_const.dart';

class LocationViewModel extends BaseViewModel {
  static final LocationViewModel _instance = LocationViewModel._internal();

  factory LocationViewModel() {
    return _instance;
  }

  LocationViewModel._internal();

  locationPre.Location location = locationPre.Location();
  bool _serviceEnabled = false;
  locationPre.PermissionStatus _permissionGranted =
      locationPre.PermissionStatus.denied;
  locationPre.LocationData? currentLocation;
  locationPre.LocationData? lastKnownLocation;
  List<locationPre.LocationData> locationList = [];

  double velocity = 0.0;
  double distanceMoved = 0.0;
  double stepsCount = 0;
  late Stream<StepCount> stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String status = '?', steps = '?';
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();

  @override
  FutureOr<void> init() {
    //change location setting
    changeLocationSetting();
  }

  void changeLocationSetting() {
    location.changeSettings(
        accuracy: locationPre.LocationAccuracy.high,
        distanceFilter: 2);
  }

  Future<void> checkLocationService() async {
    print("call check location service");
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    checkLocationPermission();
  }

  Future<void> checkLocationPermission() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    // location.enableBackgroundMode(enable: true);
    currentLocation = (await location.getLocation());
    notifyListeners();
  }

  void getLocationStreamData() {
    location.onLocationChanged.listen((locationPre.LocationData newLocation) {
      print(
          "add new location:${newLocation.latitude},${newLocation.longitude}");
      currentLocation = newLocation;
      locationList.add(newLocation);
      calculateDistanceMoved();
      calculateVelocity();
      getLastKnownLocation();
      notifyListeners();
    });
  }

  void getLastKnownLocation() {
    if (locationList.length >= 2) {
      lastKnownLocation = locationList[locationList.length - 2];
    } else {
      lastKnownLocation = currentLocation;
    }
    notifyListeners();
  }

  onResetData() {
    locationList = [];
    velocity = 0.0;
    distanceMoved = 0.0;
    stepsCount = 0;
    steps = 0.toString();
    status = '?';
    notifyListeners();
  }

  calculateDistanceMoved() async {
    if (locationList.length >= 2) {
      distanceMoved += (Geolocator.distanceBetween(
          locationList[locationList.length - 2].latitude!,
          locationList[locationList.length - 2].longitude!,
          locationList.last.latitude!,
          locationList.last.longitude!));
      notifyListeners();
    }
  }

  calculateVelocity() {
    // V  = s/t
    //V : Vận tốc (km/h)
    if (locationList.length >= 2) {
      double distance = Geolocator.distanceBetween(
          locationList[locationList.length - 2].latitude!,
          locationList[locationList.length - 2].longitude!,
          locationList.last.latitude!,
          locationList.last.longitude!);
      velocity = distance / NumberConst.updatePositionTime;
      //Doi tu m/s => Km/h;
      velocity = velocity * 3.6;
      print("velocity:$velocity");
      notifyListeners();
    }
  }

  onDistanceMovedChanged(double distance) {
    distanceMoved = distance;
    notifyListeners();
  }

  void onStepCount(StepCount event) {
    print("step count event:$event");
    print("start time:${startTime}");
    print("end time:${endTime}");
    print("step timestap:${event.timeStamp}");
    print(
        "compare timestap with start time:${event.timeStamp.isAfter(startTime)}");
    print(
        "compare timestap with current time:${event.timeStamp.isBefore(DateTime.now())}");

    // if (event.timeStamp.isAfter(startTime) &&
    //     event.timeStamp.isBefore(DateTime.now())) {
    //   stepsCount++;
      steps = event.steps.toString();
    // }
    // if (event.timeStamp.isAfter(startTime) &&
    //     event.timeStamp.isBefore(DateTime.now())) {
    //   steps = event.steps.toString();
    // } else {
    //   steps = 0.toString();
    // }
    notifyListeners();
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print("PedestrianStatus event:$event");
    status = event.status;
    notifyListeners();
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    status = 'Pedestrian Status not available';
    print("PedestrianStatus status :$status");
    notifyListeners();
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    steps = 'Step Count not available';
    notifyListeners();
  }

  Future<void> initPlatformState() async {
    print("call do steps count");
    if (await Permission.activityRecognition.request().isGranted) {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusStream
          .listen(onPedestrianStatusChanged)
          .onError(onPedestrianStatusError);

      stepCountStream = Pedometer.stepCountStream;
      stepCountStream.listen(onStepCount).onError(onStepCountError);
      notifyListeners();
    } else {
      print("request activity recognition");
      await Permission.activityRecognition.request();
    }
  }
}
