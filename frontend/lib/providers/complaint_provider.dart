import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  List<User> _engineers = [];
  final ApiService _apiService = ApiService();

  List<Complaint> get complaints => _complaints;
  List<User> get engineers => _engineers;

  Future<void> fetchComplaints() async {
    final response = await _apiService.get('/complaints');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _complaints = data.map((json) => Complaint.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchEngineers() async {
    try {
      final response = await _apiService.get('/auth/engineers');
      print('Fetch Engineers Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Engineers Count: ${data.length}');
        _engineers = data.map((json) => User.fromJson(json)).toList();
        notifyListeners();
      } else {
        print('Fetch Engineers Failed: ${response.body}');
      }
    } catch (e) {
      print('Fetch Engineers Error: $e');
    }
  }

  Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String description,
    required String image,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiService.post('/complaints', {
      'title': title,
      'description': description,
      'image': image,
      'location': {'latitude': latitude, 'longitude': longitude},
    });

    if (response.statusCode == 201) {
      await fetchComplaints();
      return {'success': true};
    } else if (response.statusCode == 409) {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'isDuplicate': true,
        'existingComplaint': data['existingComplaint'],
      };
    }
    return {'success': false};
  }

  Future<bool> confirmDuplicate(String originalId) async {
    final response = await _apiService.post('/complaints/$originalId/confirm-duplicate', {});
    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> verifyComplaint(String id) async {
    final response = await _apiService.put('/complaints/$id/verify', {});
    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> assignComplaint(String id, String engineerId) async {
    final response = await _apiService.put('/complaints/$id/assign', {'engineerId': engineerId});
    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> resolveComplaint(String id, String resolutionImage, double lat, double lon) async {
    final response = await _apiService.put('/complaints/$id/resolve', {
      'resolutionImage': resolutionImage,
      'currentLocation': {'latitude': lat, 'longitude': lon},
    });

    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }
}
