import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import '../common/map_screen.dart';
import '../role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _filterStatus = 'ALL';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      print("Refreshing Dashboard Data...");
      await Future.wait([
        provider.fetchComplaints(),
        provider.fetchEngineers(),
      ]);
      print("Refresh Complete!");
    } catch (e) {
      print("Refresh Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "Admin Dashboard" : "Registered Engineers"),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _currentIndex == 0 ? _buildComplaintsSection() : _buildEngineersSection(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _refreshData(); // Re-fetch when switching tabs
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Complaints"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Engineers"),
        ],
      ),
    );
  }

  Widget _buildComplaintsSection() {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final filteredComplaints = _filterStatus == 'ALL' 
        ? complaintProvider.complaints 
        : complaintProvider.complaints.where((c) => c.status == _filterStatus).toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            itemCount: filteredComplaints.length,
            itemBuilder: (context, index) {
              final complaint = filteredComplaints[index];
              return _buildComplaintCard(complaint);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEngineersSection() {
    final engineers = Provider.of<ComplaintProvider>(context).engineers;
    if (engineers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: Text("No engineers registered yet. Pull to refresh.")),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: engineers.length,
      itemBuilder: (context, index) {
        final eng = engineers[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.engineering)),
            title: Text(eng.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Employee ID: ${eng.employeeId ?? 'N/A'}"),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: ['ALL', 'PENDING', 'VERIFIED', 'ASSIGNED', 'RESOLVED'].map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(status),
              selected: _filterStatus == status,
              onSelected: (val) => setState(() => _filterStatus = status),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        onTap: () => _showComplaintDetails(complaint),
        title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: ${complaint.status}"),
            Text("By: ${complaint.createdBy}"),
            if (complaint.reportCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    "${complaint.reportCount} citizens facing the same problem",
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        trailing: _buildActionButtons(complaint),
        isThreeLine: true,
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
              if (complaint.reportCount > 1)
                Text("${complaint.reportCount} combined reports", style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint.description),
              const SizedBox(height: 10),
              Text("Reported by: ${complaint.createdBy}"),
              Text("Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}"),
              if (complaint.verifiedAt != null) Text("Verified: ${complaint.verifiedAt!.toLocal().toString().split('.')[0]}"),
              if (complaint.assignedEngineerId != null) Text("Assigned To: ${complaint.assignedEngineerId}"),
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

  Widget _buildActionButtons(Complaint complaint) {
    if (complaint.status == 'PENDING') {
      return ElevatedButton(
        onPressed: () => Provider.of<ComplaintProvider>(context, listen: false).verifyComplaint(complaint.id),
        child: const Text("Verify"),
      );
    } else if (complaint.status == 'VERIFIED') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: () => _showAssignDialog(complaint.id),
        child: const Text("Assign"),
      );
    }
    return const Icon(Icons.check_circle, color: Colors.green);
  }

  void _showAssignDialog(String complaintId) {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final engineers = complaintProvider.engineers;
    User? selectedEngineer;

    if (engineers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No engineers found. Please ensure engineers are registered.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Assign Engineer"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select an engineer from the list below:"),
                const SizedBox(height: 20),
                DropdownButtonFormField<User>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Choose Engineer"),
                  value: selectedEngineer,
                  items: engineers.map((eng) {
                    return DropdownMenuItem<User>(
                      value: eng,
                      child: Text("${eng.name} (ID: ${eng.employeeId})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedEngineer = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: selectedEngineer == null ? null : () {
                  complaintProvider.assignComplaint(complaintId, selectedEngineer!.id);
                  Navigator.pop(context);
                }, 
                child: const Text("Confirm Assignment")
              )
            ],
          );
        }
      ),
    );
  }
}
