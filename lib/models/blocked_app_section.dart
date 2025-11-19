class BlockedAppSection {
  final String packageName;
  final String appName;
  final bool blockEntireApp; // Block the entire app

  BlockedAppSection({
    required this.packageName,
    required this.appName,
    this.blockEntireApp = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'blockEntireApp': blockEntireApp,
    };
  }

  factory BlockedAppSection.fromJson(Map<String, dynamic> json) {
    return BlockedAppSection(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      blockEntireApp: json['blockEntireApp'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    if (blockEntireApp) {
      return '$appName (Entire App)';
    } else {
      return appName;
    }
  }
}