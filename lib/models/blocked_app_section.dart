class BlockedAppSection {
  final String packageName;
  final String appName;
  final List<String> blockedKeywords; // Keywords to detect in window titles/activities
  final bool blockEntireApp; // If true, block the entire app regardless of section

  BlockedAppSection({
    required this.packageName,
    required this.appName,
    required this.blockedKeywords,
    this.blockEntireApp = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'blockedKeywords': blockedKeywords,
      'blockEntireApp': blockEntireApp,
    };
  }

  factory BlockedAppSection.fromJson(Map<String, dynamic> json) {
    return BlockedAppSection(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      blockedKeywords: List<String>.from(json['blockedKeywords'] as List),
      blockEntireApp: json['blockEntireApp'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    if (blockEntireApp) {
      return '$appName (Entire App)';
    } else if (blockedKeywords.isEmpty) {
      return appName;
    } else {
      return '$appName (${blockedKeywords.join(", ")})';
    }
  }
}