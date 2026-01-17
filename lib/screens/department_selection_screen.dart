import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flavor/flavor_config.dart';
import '../models/volunteer_models.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  State<DepartmentSelectionScreen> createState() =>
      _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen> {
  List<Department> departments = [];
  Set<String> selectedDepartmentIds = {};
  bool loading = false;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => loading = true);
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final response = await ApiService.getVolunteerDepartments(token);
        setState(() {
          departments = response
              .map((dept) => Department.fromJson(dept))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
      _showErrorDialog('Failed to load departments. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _toggleDepartment(String departmentNameId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (selectedDepartmentIds.contains(departmentNameId)) {
        selectedDepartmentIds.remove(departmentNameId);
      } else {
        if (selectedDepartmentIds.length < 5) {
          selectedDepartmentIds.add(departmentNameId);
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select a maximum of 5 departments'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _submitRequest() async {
    if (selectedDepartmentIds.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please select at least one department');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => submitting = true);

    try {
      final token = await Storage.getToken();
      if (token != null) {
        await ApiService.submitVolunteerRequest(
          token,
          selectedDepartmentIds.toList(),
        );

        HapticFeedback.selectionClick();
        if (!mounted) return;

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Request Submitted!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Thank you for your willingness to serve! We have received your volunteer request and our team will contact you soon.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(
                    context,
                    true,
                  ); // Return to profile with success flag
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlavorConfig.instance.values.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      final errorMessage = e.toString().replaceFirst("Exception: ", "");
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.values.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Select Departments',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        size: 48,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Join Our Team',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select up to 5 departments where you\'d like to serve',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${selectedDepartmentIds.length} / 5 selected',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Departments List
                Expanded(
                  child: departments.isEmpty
                      ? Center(
                          child: Text(
                            'No departments available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: departments.length,
                          itemBuilder: (context, index) {
                            final department = departments[index];
                            return _buildDepartmentSection(
                              department,
                              primaryColor,
                            );
                          },
                        ),
                ),

                // Submit Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (submitting || selectedDepartmentIds.isEmpty)
                            ? null
                            : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDepartmentSection(Department department, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            department.department,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${department.departmentNames.length} ${department.departmentNames.length == 1 ? 'role' : 'roles'} available',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.group_work, color: primaryColor, size: 24),
          ),
          children: department.departmentNames.map((deptName) {
            final isSelected = selectedDepartmentIds.contains(deptName.id);
            return _buildDepartmentNameTile(deptName, isSelected, primaryColor);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDepartmentNameTile(
    DepartmentName deptName,
    bool isSelected,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: () => _toggleDepartment(deptName.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deptName.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  if (deptName.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      deptName.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
