import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapcard/map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.to(() => const MapPage()),
          child: const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'Welcome to this case study!\nClick here to go to the next page!',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
