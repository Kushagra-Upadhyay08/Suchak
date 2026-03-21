import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';

class ResolveScreen extends StatefulWidget {
  final Complaint complaint;
  const ResolveScreen({super.key, required this.complaint});

  @override
  State<ResolveScreen> createState() => _ResolveScreenState();
}

class _ResolveScreenState extends State<ResolveScreen> {
  XFile? _image;
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _captureProof() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Compress to 50%
      maxWidth: 1024,   // Limit width
      maxHeight: 1024,  // Limit height
    );
    if (image != null) {
      setState(() {
        _image = image;
        _isLoading = true; // Show loading while getting location
      });
      try {
        await _getCurrentLocation();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location services are disabled.")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permissions are denied")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permissions are permanently denied")));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10)); // 10 second timeout
      setState(() => _currentPosition = position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not get current location: $e")));
    }
  }

  void _submitResolution() async {
    if (_image == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Capture proof image first")));
      return;
    }

    setState(() => _isLoading = true);
    final bytes = await File(_image!.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final result = await Provider.of<ComplaintProvider>(context, listen: false).resolveComplaint(
      widget.complaint.id,
      base64Image,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    setState(() => _isLoading = false);
    if (result['success'] == true) {
      Navigator.pop(context);
    } else {
      // The distance check failed on the server
      final double? dist = result['distance'] != null ? result['distance'].toDouble() : null;
      final String msg = dist != null 
          ? "Too far! You are ${dist.toStringAsFixed(1)}m away. You must be within 30m."
          : "Distance Check Failed: Please ensure you are at the site.";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resolve Complaint")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Issue: ${widget.complaint.title}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _image != null 
              ? Image.file(File(_image!.path), height: 250)
              : OutlinedButton.icon(onPressed: _captureProof, icon: const Icon(Icons.camera_alt), label: const Text("Capture Proof (Real-time)")),
            const SizedBox(height: 20),
            if (_isLoading) 
              const Center(child: Column(children: [CircularProgressIndicator(), Text("Fetching Location... Readying Proof...")])),
            if (_currentPosition != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 10),
                    Text("Verified at: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (!_isLoading) SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _image == null || _currentPosition == null ? Colors.grey : Colors.green),
                onPressed: _image == null || _currentPosition == null ? null : _submitResolution, 
                child: Text(_image == null ? "Capture Proof" : (_currentPosition == null ? "Getting Location..." : "Mark as Resolved"))
              )
            ),
          ],
        ),
      ),
    );
  }
}
