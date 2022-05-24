import 'package:get/get.dart';
import 'package:tracking_app_on_watch_flutter/controller/localtionController.dart';

class HomePageBinding extends Bindings {
  @override
  dependencies() {
    Get.lazyPut<LocationController>(() => LocationController());
  }
}
