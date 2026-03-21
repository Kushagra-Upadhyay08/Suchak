import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';
import 'create_complaint_screen.dart';
import '../role_selection_screen.dart';
import '../common/map_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: complaintProvider.complaints.isEmpty
          ? const Center(child: Text("No complaints yet. Report one!"))
          : ListView.builder(
              itemCount: complaintProvider.complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaintProvider.complaints[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () => _showComplaintDetails(complaint),
                    title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Status: ${complaint.status}\nCreated: ${complaint.createdAt.toString().split('.')[0]}"),
                    trailing: Chip(
                      label: Text("${complaint.daysTaken}d"),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateComplaintScreen()));
        },
        label: const Text("Report Issue"),
        icon: const Icon(Icons.add_a_photo),
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(complaint.image),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(complaint.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Status: ${complaint.status}", style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint.description),
              const SizedBox(height: 10),
              Text("Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}"),
              if (complaint.status == 'RESOLVED' && complaint.resolutionImage != null) ...[
                const Divider(height: 40),
                const Text("Resolution Proof:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(complaint.resolutionImage!),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Resolved at: ${complaint.resolvedAt?.toLocal().toString().split('.')[0] ?? 'N/A'}"),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
