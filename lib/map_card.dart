import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// default text style on dark background
const TextStyle myStyle = TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold);

// modifiable values for different experience
final num randomnessPrecision = pow(10, 3);
const double mapZoom = 15;

class MapCard extends StatefulWidget {
  const MapCard({Key? key}) : super(key: key);

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> {
  // Google maps vars
  late final Completer<GoogleMapController> _controller;
  late CameraPosition initialPosition;

  // to track if the google map has been initialized
  bool isReady = false;

  // to track if the dialog is shown or hidden
  bool dialogIsHidden = true;

  // To track current and past locations
  List<LatLng> previousLocations = [];
  double currentLong = 0;
  double currentLat = 0;


  @override
  void initState() {
    super.initState();
    _controller = Completer<GoogleMapController>();
    initialPosition = const CameraPosition(target: LatLng(0, 0));
    setMapToMyLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !isReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                if (!dialogIsHidden) ...[
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
    );
  }

  // Widgets

  Widget mapCard() {
    return GoogleMap(
      mapType: MapType.terrain,
      initialCameraPosition: initialPosition,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      markers: {
        Marker(
          markerId: const MarkerId("object"),
          icon: BitmapDescriptor.defaultMarker,
          position: LatLng(currentLat, currentLong),
        )
      },
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
            'Latitude :${currentLat.toStringAsFixed(0)}',
            style: myStyle,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Longitude :${currentLong.toStringAsFixed(0)}',
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
              itemCount: previousLocations.length >= 3 ? 3 : previousLocations.length,
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Lat :${previousLocations.reversed.toList()[i].latitude.toStringAsFixed(0)}, '
                    'Long:${previousLocations.reversed.toList()[i].longitude.toStringAsFixed(0)}',
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
        onPressed: () => setState(() => dialogIsHidden = true),
      ),
    );
  }

  // Functions

  Future<void> setMapToMyLocation() async {
    final Position myLocation = await locate();
    setState(() {
      currentLat = myLocation.latitude;
      currentLong = myLocation.longitude;
      initialPosition = CameraPosition(
        target: LatLng(myLocation.latitude, myLocation.longitude),
        zoom: mapZoom,
      );
      isReady = true;
    });
  }

  Future<void> toMe() async {
    final GoogleMapController controller = await _controller.future;
    final Position myLocation = await locate();
    setState(() {
      currentLat = myLocation.latitude;
      currentLong = myLocation.longitude;
      initialPosition = CameraPosition(
        target: LatLng(myLocation.latitude, myLocation.longitude),
        zoom: mapZoom,
      );
      dialogIsHidden = false;
    });

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(myLocation.latitude, myLocation.longitude),
          zoom: mapZoom,
        ),
      ),
    );
    previousLocations.add(LatLng(currentLat, currentLong));
  }

  Future<void> toRandom() async {
    final GoogleMapController controller = await _controller.future;

    setState(() {
      currentLat = randomLat;
      currentLong = randomLong;
    });
    previousLocations.add(LatLng(currentLat, currentLong));

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLat, currentLong),
          zoom: mapZoom,
        ),
      ),
    );
    dialogIsHidden = false;
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
