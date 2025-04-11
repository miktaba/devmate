// This is a fallback environment file with placeholder values
// It's used when env.dart is not available
// The actual env.dart file should be created from env.example.dart

class Env {
  // GitHub OAuth credentials (placeholders)
  static const String githubClientId = 'PLACEHOLDER_ID';
  static const String githubClientSecret = 'PLACEHOLDER_SECRET';
  static const String githubRedirectUri = 'devmate://callback';

  // GitHub OAuth scopes required by the application
  static const List<String> githubScopes = [
    'repo', // access to repositories
    'user', // access to user information
    'read:user', // reading user data
    'user:email', // access to email
  ];

  // GitHub API endpoints
  static const String githubAuthUrl =
      'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String githubApiUrl = 'https://api.github.com';
}
