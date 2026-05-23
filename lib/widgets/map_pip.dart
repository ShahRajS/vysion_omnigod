import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPip extends StatefulWidget {
  const MapPip({
    required this.polyline,
    required this.currentPosition,
    this.destination,
    this.visible = true,
    super.key,
  });

  final List<LatLng> polyline;
  final LatLng? currentPosition;
  final LatLng? destination;
  final bool visible;

  @override
  State<MapPip> createState() => _MapPipState();
}

class _MapPipState extends State<MapPip> {
  Offset _position = Offset.zero;
  bool _expanded = false;
  GoogleMapController? _mapController;

  static const _collapsedWidth = 180.0;
  static const _collapsedHeight = 240.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position == Offset.zero) {
      final size = MediaQuery.of(context).size;
      _position = Offset(
        size.width - _collapsedWidth - 20,
        size.height - _collapsedHeight - 100,
      );
    }
  }

  @override
  void didUpdateWidget(MapPip old) {
    super.didUpdateWidget(old);
    if (widget.currentPosition != null &&
        widget.currentPosition != old.currentPosition) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(widget.currentPosition!),
      );
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  double get _width {
    if (_expanded) return MediaQuery.of(context).size.width - 40;
    return _collapsedWidth;
  }

  double get _height {
    if (_expanded) return MediaQuery.of(context).size.height * 0.5;
    return _collapsedHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final initialPos = widget.currentPosition ?? const LatLng(0, 0);

    final markers = <Marker>{};
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    final polylines = <Polyline>{};
    if (widget.polyline.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.polyline,
          color: Colors.blue,
          width: 4,
        ),
      );
    }

    return Positioned(
      left: _expanded ? 20 : _position.dx,
      top: _expanded ? MediaQuery.of(context).size.height * 0.3 : _position.dy,
      child: GestureDetector(
        onPanUpdate: _expanded
            ? null
            : (details) {
                setState(() {
                  final size = MediaQuery.of(context).size;
                  _position = Offset(
                    (_position.dx + details.delta.dx)
                        .clamp(0, size.width - _collapsedWidth),
                    (_position.dy + details.delta.dy)
                        .clamp(0, size.height - _collapsedHeight),
                  );
                });
              },
        onDoubleTap: _toggleExpanded,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPos,
                  zoom: 16,
                ),
                onMapCreated: (controller) => _mapController = controller,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                markers: markers,
                polylines: polylines,
              ),
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
