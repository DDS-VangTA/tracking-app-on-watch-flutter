import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as locationPre;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int previousSteps = 0;
  int stepsCount = 0;
  late Stream<StepCount> stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String status = '?';
  int allSteps = 0;
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();

  @override
  FutureOr<void> init() {
    //change location setting
    changeLocationSetting();
  }

  void changeLocationSetting() {
    location.changeSettings(
        accuracy: locationPre.LocationAccuracy.high, distanceFilter: 2);
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
    location.enableBackgroundMode(enable: true);
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
    status = '?';
    stepsSensors = 0;
    notifyListeners();
  }

  calculateDistanceMoved() async {
    if (locationList.length >= 2) {
      double tempDistance = (Geolocator.distanceBetween(
          locationList[locationList.length - 2].latitude!,
          locationList[locationList.length - 2].longitude!,
          locationList.last.latitude!,
          locationList.last.longitude!));
      if (tempDistance >= 2.0) {
        distanceMoved += tempDistance;
      }
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
    getPreviousStep();
    print("on step count previous:$previousSteps");
    stepsCount = event.steps - previousSteps;
    allSteps = event.steps;
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
    // steps = 'Step Count not available';
    allSteps = 0;
    stepsCount = 0;
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

  void saveStepsPreData(int steps) async {
    print("pre steps to save:$steps");
    SharedPreferences _pref = await SharedPreferences.getInstance();
    _pref.setInt('previous_steps', steps);
  }

  void getPreviousStep() async {
    SharedPreferences _pref = await SharedPreferences.getInstance();
    previousSteps = _pref.getInt("previous_steps") ?? 0;
    print("pre steps get:$previousSteps");
  }

  // count steps by sensors_plus
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;
  int stepsSensors = 0;
  double exactDistance = 0.0;
  double previousDistance = 0.0;

  void listenStepsSensorsCount() {
    SensorsPlatform.instance.accelerometerEvents.listen((event) {
      exactDistance = calculateMagnitude(event.x, event.y, event.z);
      if (exactDistance > 6) {
        stepsSensors++;
      }
    });
  }

  double calculateMagnitude(double x, double y, double z) {
    double distance = sqrt(x * x + y * y + z * z);
    getPreviousValue();
    double mode = distance - previousDistance;
    setprefData(distance);
    return mode;
  }

  void setprefData(double predistance) async {
    SharedPreferences _pref = await SharedPreferences.getInstance();
    _pref.setDouble("previousDistance", predistance);
  }

  void getPreviousValue() async {
    SharedPreferences _pref = await SharedPreferences.getInstance();
    previousDistance = _pref.getDouble("previousDistance") ?? 0;
    notifyListeners();
  }
}
