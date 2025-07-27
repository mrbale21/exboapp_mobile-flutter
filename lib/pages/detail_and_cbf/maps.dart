import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:logger/logger.dart';

var logger = Logger();

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double latitudeUser;
  final double longitudeUser;
  final String name;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.latitudeUser,
    required this.longitudeUser,
    required this.name,
  });

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];
  bool isJourneyStarted = false;
  LatLng userCurrentPosition = const LatLng(0, 0);
  double zoomLevel = 13.0;
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    fetchRoute();
    userCurrentPosition = LatLng(widget.latitudeUser, widget.longitudeUser);
    isJourneyStarted = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => adjustMapView());
  }

  Future<void> fetchRoute() async {
    const apiKey = '5b3ce3597851110001cf62486fc3375f95644d37b136b95330ddd323';
    final url =
        'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${widget.longitudeUser},${widget.latitudeUser}&end=${widget.longitude},${widget.latitude}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'];

        if (mounted) {
          setState(() {
            routePoints = coordinates
                .map<LatLng>((point) => LatLng(point[1], point[0]))
                .toList();
          });
        }
      } else {}
    } catch (e) {
      logger.e('error: $e');
    }
  }

  void trackUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    positionStream = Geolocator.getPositionStream().listen((Position position) {
      if (isJourneyStarted) {
        setState(() {
          userCurrentPosition = LatLng(position.latitude, position.longitude);
          // Hapus baris ini agar tidak mengubah zoom setiap kali posisi pengguna diperbarui
          // _mapController.move(userCurrentPosition, zoomLevel);
        });
      }
    });
  }

  void adjustMapView() {
    LatLng point1 = LatLng(widget.latitudeUser, widget.longitudeUser);
    LatLng point2 = LatLng(widget.latitude, widget.longitude);

    double distance = const Distance().as(LengthUnit.Kilometer, point1, point2);
    zoomLevel = distance < 1
        ? 15
        : distance < 5
            ? 13
            : 10;

    LatLng center = LatLng(
      (point1.latitude + point2.latitude) / 2,
      (point1.longitude + point2.longitude) / 2,
    );

    _mapController.move(center, zoomLevel);
  }

  void startJourney() {
    setState(() {
      isJourneyStarted = true;
    });
    trackUserLocation();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.latitudeUser, widget.longitudeUser),
              initialZoom: zoomLevel,
              maxZoom: 18, // Maksimum zoom yang diperbolehkan
              minZoom: 10, // Minimum zoom yang diperbolehkan
              interactionOptions: const InteractionOptions(
                // Mengizinkan semua interaksi
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.latitude, widget.longitude),
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  Marker(
                    point: userCurrentPosition,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.person_pin,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.0,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: isJourneyStarted ? null : startJourney,
              child: Text(
                  isJourneyStarted ? 'Perjalanan Dimulai' : 'Mulai Perjalanan'),
            ),
          ),
        ],
      ),
    );
  }
}
