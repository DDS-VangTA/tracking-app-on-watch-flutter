import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationController extends GetxController {
  Location location = Location();

  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  Rx<LocationData>? currentLocation;
  Rx<LocationData>? lastKnownLocation;
  var locationList = <LocationData>[].obs;

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
    currentLocation = (await location.getLocation()).obs;
    location.enableBackgroundMode(enable: true);
  }

  void getLocationStreamData() {
    location.onLocationChanged.listen((LocationData currentLocation) {
      print("add new location:${currentLocation}");
      locationList.add(currentLocation);
      getLastKnownLocation();
    });
  }

  void getLastKnownLocation() {
    if (locationList.length >= 2) {
      // lastKnownLocation = locationList.value[0] as Rx<LocationData>?;
      print(
          "last know location:lat:${locationList.value[0].latitude},lon:${locationList.value[0].longitude}");
    } else {
      lastKnownLocation = currentLocation;
    }
  }
}
