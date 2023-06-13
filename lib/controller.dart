import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StateController extends GetxController {
  // to track if the google map has been initialized
  RxBool isReady = false.obs;

  // to track if the dialog is shown or hidden
  RxBool dialogIsHidden = true.obs;

  // To track current and past locations
  RxList<LatLng> previousLocations = (<LatLng>[]).obs;
  RxDouble currentLong = 0.0.obs;
  RxDouble currentLat = 0.0.obs;

  void changeIsReady(bool newValue) {
    isReady.value = newValue;
    refresh();
  }

  void changeDialogIsHidden(bool newValue) {
    dialogIsHidden.value = newValue;
    refresh();
  }

  void addLocation(LatLng location) {
    previousLocations.add(location);
    refresh();
  }

  void changeLong(double newValue) {
    currentLong.value = newValue;
    refresh();
  }

  void changeLat(double newValue) {
    currentLat.value = newValue;
    refresh();
  }
}
