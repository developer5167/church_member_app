class DepartmentName {
  final String id;
  final String name;
  final String? description;

  DepartmentName({required this.id, required this.name, this.description});

  factory DepartmentName.fromJson(Map<String, dynamic> json) {
    return DepartmentName(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class Department {
  final String id;
  final String department;
  final List<DepartmentName> departmentNames;

  Department({
    required this.id,
    required this.department,
    required this.departmentNames,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      department: json['department'],
      departmentNames: (json['departmentNames'] as List)
          .map((name) => DepartmentName.fromJson(name))
          .toList(),
    );
  }
}

class VolunteerRequestDepartment {
  final String id;
  final String departmentName;
  final String departmentHeading;
  final String? description;

  VolunteerRequestDepartment({
    required this.id,
    required this.departmentName,
    required this.departmentHeading,
    this.description,
  });

  factory VolunteerRequestDepartment.fromJson(Map<String, dynamic> json) {
    return VolunteerRequestDepartment(
      id: json['id'],
      departmentName: json['departmentName'],
      departmentHeading: json['departmentHeading'],
      description: json['description'],
    );
  }
}

class VolunteerRequest {
  final String id;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<VolunteerRequestDepartment> departments;

  VolunteerRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.departments,
  });

  factory VolunteerRequest.fromJson(Map<String, dynamic> json) {
    return VolunteerRequest(
      id: json['id'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      departments: json['departments'] != null
          ? (json['departments'] as List)
                .map((dept) => VolunteerRequestDepartment.fromJson(dept))
                .toList()
          : [],
    );
  }
}

class VolunteerStatus {
  final bool hasActiveRequest;
  final String message;
  final VolunteerRequest? request;
  final VolunteerRequest? lastCompletedRequest;

  VolunteerStatus({
    required this.hasActiveRequest,
    required this.message,
    this.request,
    this.lastCompletedRequest,
  });

  factory VolunteerStatus.fromJson(Map<String, dynamic> json) {
    return VolunteerStatus(
      hasActiveRequest: json['data']['hasActiveRequest'],
      message: json['message'],
      request: json['data']['request'] != null
          ? VolunteerRequest.fromJson(json['data']['request'])
          : null,
      lastCompletedRequest: json['data']['lastCompletedRequest'] != null
          ? VolunteerRequest.fromJson(json['data']['lastCompletedRequest'])
          : null,
    );
  }
}
