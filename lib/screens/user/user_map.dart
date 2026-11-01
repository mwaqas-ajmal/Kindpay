import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';

class UserMap extends StatefulWidget {
  const UserMap({super.key});

  @override
  State<UserMap> createState() => _UserMapState();
}

class _UserMapState extends State<UserMap> {
  LatLng currentLocation = LatLng(31.4504, 73.1350);
  bool loading = true;
  final MapController mapController = MapController();
  List<Marker> ngoMarkers = [];

  @override
  void initState() {
    super.initState();
    loadMap();
  }

  Future<void> loadMap() async {
    await getLocation();
    await fetchNearbyNgos();
    setState(() {
      loading = false;
    });
  }

  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchNearbyNgos() async {
    try {
      var response = await http.get(
        Uri.parse("https://digitalghallamandi.online/kind-pay/get_nearby_ngos.php"),
      );

      var data = jsonDecode(response.body);
      ngoMarkers = [];

      // USER MARKER
      ngoMarkers.add(
        Marker(
          point: currentLocation,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("You", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );

      // NGO MARKERS
      for (var ngo in data['ngos']) {
        double lat = double.parse(ngo['latitude']);
        double lng = double.parse(ngo['longitude']);

        ngoMarkers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 130,
            height: 80,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ngo['username'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom nav bar height + margin (≈ 80dp) so FABs and map content never hide beneath it
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Nearby NGOs",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      // ── FABs sitting above the bottom nav bar ──
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: "zoom_in",
              backgroundColor: AppTheme.cardColor,
              foregroundColor: AppTheme.primary,
              onPressed: () {
                mapController.move(
                  mapController.camera.center,
                  mapController.camera.zoom + 1,
                );
              },
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.small(
              heroTag: "zoom_out",
              backgroundColor: AppTheme.cardColor,
              foregroundColor: AppTheme.primary,
              onPressed: () {
                mapController.move(
                  mapController.camera.center,
                  mapController.camera.zoom - 1,
                );
              },
              child: const Icon(Icons.remove_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "my_location",
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                mapController.move(currentLocation, 15);
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Loading map...",
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.kindpay',
                ),
                MarkerLayer(markers: ngoMarkers),
              ],
            ),
    );
  }
}