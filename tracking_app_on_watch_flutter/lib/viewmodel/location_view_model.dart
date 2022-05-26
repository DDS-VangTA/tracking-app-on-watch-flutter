import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as locationPre;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_app_on_watch_flutter/model/record_status.dart';

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
  RecordStatus recordStatus = RecordStatus.NONE;

  bool flag = true;
  late Stream<int> timerStream;
  late StreamSubscription<int> timerSubscription;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';

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

  void onRecordStatusChanged(RecordStatus status) {
    recordStatus = status;
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
    //the first time received event
    if (previousSteps == 0) {
      saveStepsPreData(event.steps);
    }
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

  // count time moving
  Stream<int> stopWatchStream() {
    StreamController<int>? streamController;
    Timer? timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void stopTimer() {
      if (timer != null) {
        timer?.cancel();
        timer = null;
        counter = 0;
        streamController?.close();
      }
    }

    void pauseTimer(){
      stopTimer();
    }

    void tick(_) {
      counter++;
      streamController?.add(counter);
      if (!flag) {
        stopTimer();
      }
    }

    void startTimer() {
      timer = Timer.periodic(timerInterval, tick);
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onResume: startTimer,
      onPause: stopTimer,
    );

    return streamController.stream;
  }
}
