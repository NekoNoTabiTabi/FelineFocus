class ReelsConfig {
  // Define which apps have reels and their detection patterns
  static const Map<String, List<String>> reelsApps = {
    // YouTube
    'com.google.android.youtube': [
      'shorts',
      'short',
      '/shorts/',
      'shortsshelf',
      'reel_recycler',
      'reel',
      'reel_playback_loading_spinner'
      'reel_player_page_container'
    ],
    
    // Instagram
    'com.instagram.android': [
      'reels',
      'reel',
      '/reels/',
      'clipsviewer',
      'clipstab',
    ],
    
    // Facebook
    'com.facebook.katana': [
      'reels',
      'reel',
      '/reels/',
      'watch',
      'videohome',
    ],
    
    // TikTok (essentially all content is short-form)
    'com.zhiliaoapp.musically': [
      'tiktok', // Block entire app since it's all short-form
      'video',
      'feed',
    ],
    
    // Snapchat
    'com.snapchat.android': [
      'spotlight',
      'discover',
      'story',
      'stories',
    ],
    
    // Twitter/X
    'com.twitter.android': [
      'video',
      'moment',
    ],
    
    // Reddit
    'com.reddit.frontpage': [
      'video',
      '/r/popular',
    ],
  };

  // Get user-friendly names for apps
  static const Map<String, String> appNames = {
    'com.google.android.youtube': 'YouTube Shorts',
    'com.instagram.android': 'Instagram Reels',
    'com.facebook.katana': 'Facebook Reels',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.snapchat.android': 'Snapchat Spotlight',
    'com.twitter.android': 'Twitter/X Videos',
    'com.reddit.frontpage': 'Reddit Videos',
  };

  // Check if an app has reels/short-form content
  static bool hasReelsContent(String packageName) {
    return reelsApps.containsKey(packageName);
  }

  // Get detection keywords for an app
  static List<String> getKeywords(String packageName) {
    return reelsApps[packageName] ?? [];
  }

  // Get all apps that have reels
  static List<String> getAllReelsApps() {
    return reelsApps.keys.toList();
  }

  // Get friendly name for app
  static String getFriendlyName(String packageName) {
    return appNames[packageName] ?? packageName;
  }
}