import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ev_charging_app/core/models/station.dart';
import 'package:ev_charging_app/core/services/station_service.dart';

class StationDetailsPage extends StatefulWidget {
  final Station station;
  final Position? currentLocation;

  const StationDetailsPage({
    super.key,
    required this.station,
    this.currentLocation,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  final _stationService = StationService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await _stationService.isFavorite(widget.station.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isFavorite) {
        await _stationService.removeFromFavorites(widget.station.id);
      } else {
        await _stationService.addToFavorites(widget.station.id);
      }
      
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openInMaps() async {
    final station = widget.station;
    final currentLocation = widget.currentLocation;
    
    String url;
    if (currentLocation != null) {
      // If we have current location, provide navigation
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${currentLocation.latitude},${currentLocation.longitude}'
          '&destination=${station.latitude},${station.longitude}'
          '&travelmode=driving';
    } else {
      // Otherwise just show the station location
      url = 'https://www.google.com/maps/search/?api=1'
          '&query=${station.latitude},${station.longitude}';
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _isLoading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.station.latitude,
                      widget.station.longitude,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.station.id),
                      position: LatLng(
                        widget.station.latitude,
                        widget.station.longitude,
                      ),
                      infoWindow: InfoWindow(title: widget.station.name),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(widget.station.address),
                subtitle: Text(
                  'Lat: ${widget.station.latitude}, Long: ${widget.station.longitude}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Power',
                    Text(
                      '${widget.station.power} kW',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    'Price',
                    Text(
                      '${widget.station.pricePerKwh} MAD/kWh',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Status',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.station.available ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.station.available ? 'Available' : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.station.availableStatus ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),



                    ],
                  )
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Connector Types',
              Wrap(
                spacing: 8,
                children: widget.station.connectorTypes.map((type) {
                  return Chip(label: Text(type));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInMaps,
        icon: const Icon(Icons.directions),
        label: const Text('Navigate'),
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: content),
          ],
        ),
      ),
    );
  }
}
