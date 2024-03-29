import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapcard/controller.dart';

// default text style on dark background
const TextStyle myStyle = TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold);

// modifiable values for different experience
final num randomnessPrecision = pow(10, 3);
const double mapZoom = 15;

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Google maps vars
  late final Completer<GoogleMapController> _mapController;
  late Rx<CameraPosition> initialPosition;

  // Controller
  late final StateController controller;

  @override
  void initState() {
    super.initState();
    _mapController = Completer<GoogleMapController>();
    initialPosition = const CameraPosition(target: LatLng(0, 0)).obs;
    controller = Get.put(StateController());
    setMapToMyLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Obx(
        () => !controller.isReady.value
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Stack(
                  children: [
                    mapCard(),
                    Positioned(
                      bottom: 10,
                      left: 75,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 150,
                        child: Column(
                          children: [
                            toRandomButton(),
                            toMeButton(),
                          ],
                        ),
                      ),
                    ),
                    if (!controller.dialogIsHidden.value) ...[
                      Positioned(
                        left: 60,
                        top: 100,
                        child: greyBoxWidget(),
                      ),
                      Positioned(
                        right: 80 - 50 + 10,
                        top: 100 - 35 + 10,
                        child: closeGreyBoxButton(),
                      )
                    ]
                  ],
                ),
              ),
      ),
    );
  }

  // Widgets

  Widget mapCard() {
    return Obx(
      () => GoogleMap(
        mapType: MapType.terrain,
        initialCameraPosition: initialPosition.value,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
        markers: {
          Marker(
            markerId: const MarkerId("object"),
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(controller.currentLat.value, controller.currentLong.value),
          )
        },
      ),
    );
  }

  Widget toRandomButton() {
    return InkWell(
      onTap: () => toRandom(),
      child: Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(96, 191, 234, 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 2,
              color: Colors.black,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Flexible(
              child: Text(
                'Teleport me to somewhere random',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget toMeButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      child: InkWell(
        onTap: () => toMe(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(142, 54, 230, 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                blurRadius: 2,
                color: Colors.black,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Bring me back home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget greyBoxWidget() {
    return Container(
      width: MediaQuery.of(context).size.width - 120,
      height: MediaQuery.of(context).size.height / 2,
      color: Colors.grey.withOpacity(0.6),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            child: Text(
              'Current Location',
              style: myStyle,
            ),
          ),
          Text(
            'Latitude :${controller.currentLat.value.toStringAsFixed(0)}',
            style: myStyle,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Longitude :${controller.currentLong.value.toStringAsFixed(0)}',
              style: myStyle,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Previous ',
              style: myStyle,
            ),
          ),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.previousLocations.length >= 3 ? 3 : controller.previousLocations.length,
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Lat :${controller.previousLocations.reversed.toList()[i].latitude.toStringAsFixed(0)}, '
                    'Long:${controller.previousLocations.reversed.toList()[i].longitude.toStringAsFixed(0)}',
                    style: myStyle,
                    textAlign: TextAlign.center,
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget closeGreyBoxButton() {
    return Container(
      height: 50,
      width: 50,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(
          Icons.close,
          color: Colors.white,
          size: 35,
        ),
        onPressed: () => controller.changeDialogIsHidden(true),
      ),
    );
  }

  // Functions

  Future<void> setMapToMyLocation() async {
    final Position myLocation = await locate();

    controller.changeLat(myLocation.latitude);
    controller.changeLong(myLocation.longitude);

    initialPosition.value = CameraPosition(
      target: LatLng(myLocation.latitude, myLocation.longitude),
      zoom: mapZoom,
    );

    controller.changeIsReady(true);
  }

  Future<void> toMe() async {
    final GoogleMapController mapController = await _mapController.future;
    final Position myLocation = await locate();
    controller.changeLat(myLocation.latitude);
    controller.changeLong(myLocation.longitude);

    initialPosition.value = CameraPosition(
      target: LatLng(myLocation.latitude, myLocation.longitude),
      zoom: mapZoom,
    );

    controller.changeDialogIsHidden(false);

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(myLocation.latitude, myLocation.longitude),
          zoom: mapZoom,
        ),
      ),
    );

    controller.addLocation(LatLng(myLocation.latitude, myLocation.longitude));
  }

  Future<void> toRandom() async {
    final GoogleMapController mapController = await _mapController.future;

    controller.changeLat(randomLat);
    controller.changeLong(randomLong);

    controller.addLocation(LatLng(controller.currentLat.value, controller.currentLong.value));

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(controller.currentLat.value, controller.currentLong.value),
          zoom: mapZoom,
        ),
      ),
    );

    controller.changeDialogIsHidden(false);
  }

  double get randomLat =>
      (Random().nextDouble() * 18 * randomnessPrecision - 9 * randomnessPrecision) / randomnessPrecision * 10;

  double get randomLong =>
      (Random().nextDouble() * 36 * randomnessPrecision - 18 * randomnessPrecision) / randomnessPrecision * 10;

  Future<Position> locate() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // Location services are disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location Services are disabled.'),
        ),
      );
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        // Permissions are denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions are denied'),
          ),
        );
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return Future.error('Location permissions are permanently denied.');
    }

    // permissions are granted
    return await Geolocator.getCurrentPosition();
  }
}
