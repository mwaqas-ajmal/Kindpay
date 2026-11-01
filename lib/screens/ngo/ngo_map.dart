import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

class NgoMap extends StatefulWidget {

  const NgoMap({super.key});

  @override
  State<NgoMap> createState() =>
      _NgoMapState();
}

class _NgoMapState
    extends State<NgoMap> {

  LatLng currentLocation =

  LatLng(31.4504,73.1350);

  bool loading = true;

  final MapController mapController =
  MapController();

  List<Marker> ngoMarkers = [];

  @override
  void initState() {

    super.initState();

    loadMap();
  }

  // =====================================================

  Future<void> loadMap() async {

    await getLocation();

    await fetchNearbyNgos();

    setState(() {

      loading = false;
    });
  }

  // =====================================================

  Future<void> getLocation() async {

    try {

      bool serviceEnabled =

      await Geolocator
          .isLocationServiceEnabled();

      if(!serviceEnabled){
        return;
      }

      LocationPermission permission =

      await Geolocator.checkPermission();

      if(permission ==
          LocationPermission.denied){

        permission =

        await Geolocator
            .requestPermission();
      }

      Position position =

      await Geolocator
          .getCurrentPosition(

        desiredAccuracy:
        LocationAccuracy.high,
      );

      currentLocation = LatLng(

        position.latitude,

        position.longitude,
      );

    } catch(e){

      print(e);
    }
  }

  // =====================================================

  Future<void> fetchNearbyNgos() async {

    try {

      var response =

      await http.get(

        Uri.parse(

"https://digitalghallamandi.online/kind-pay/get_nearby_ngos.php",

        ),
      );

      var data =
      jsonDecode(response.body);

      ngoMarkers = [];

      // USER MARKER

      ngoMarkers.add(

        Marker(

          point: currentLocation,

          width: 80,
          height: 80,

          child: const Column(

            children: [

              Icon(

                Icons.my_location,

                color: Colors.blue,

                size: 40,
              ),

              Text(
                "You",
              ),
            ],
          ),
        ),
      );

      // NGO MARKERS

      for(var ngo in data['ngos']){

        double lat =

        double.parse(
            ngo['latitude']);

        double lng =

        double.parse(
            ngo['longitude']);

        ngoMarkers.add(

          Marker(

            point:
            LatLng(lat,lng),

            width: 120,
            height: 80,

            child: Column(

              children: [

                const Icon(

                  Icons.location_on,

                  color: Colors.green,

                  size: 42,
                ),

                Container(

                  padding:
                  const EdgeInsets.all(4),

                  color: Colors.white,

                  child: Text(

                    ngo['username'],

                    textAlign:
                    TextAlign.center,

                    style: const TextStyle(

                      fontSize: 11,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

    } catch(e){

      print(e);
    }
  }

  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text("Nearby NGOs"),
      ),

      floatingActionButton: Column(

        mainAxisAlignment:
        MainAxisAlignment.end,

        children: [

          FloatingActionButton(

            mini: true,

            child: const Icon(Icons.add),

            onPressed: () {

              mapController.move(

                mapController.camera.center,

                mapController.camera.zoom + 1,
              );
            },
          ),

          const SizedBox(height: 10),

          FloatingActionButton(

            mini: true,

            child: const Icon(Icons.remove),

            onPressed: () {

              mapController.move(

                mapController.camera.center,

                mapController.camera.zoom - 1,
              );
            },
          ),

          const SizedBox(height: 10),

          FloatingActionButton(

            child:
            const Icon(Icons.my_location),

            onPressed: () {

              mapController.move(

                currentLocation,

                15,
              );
            },
          ),
        ],
      ),

      body: loading

      ? const Center(
        child:
        CircularProgressIndicator(),
      )

      : FlutterMap(

        mapController:
        mapController,

        options: MapOptions(

          initialCenter:
          currentLocation,

          initialZoom: 13,
        ),

        children: [

          TileLayer(

            urlTemplate:

'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

            userAgentPackageName:
            'com.example.kindpay',
          ),

          MarkerLayer(
            markers: ngoMarkers,
          ),
        ],
      ),
    );
  }
}