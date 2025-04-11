// This is an example environment file
// Copy this file to env.dart and replace the placeholder values with your actual credentials
// DO NOT commit the env.dart file to version control

class Env {
  // GitHub OAuth credentials
  static const String githubClientId = 'YOUR_GITHUB_CLIENT_ID';
  static const String githubClientSecret = 'YOUR_GITHUB_CLIENT_SECRET';
  static const String githubRedirectUri = 'devmate://callback';

  // GitHub OAuth scopes required by the application
  static const List<String> githubScopes = [
    'repo', // access to repositories
    'user', // access to user information
    'read:user', // reading user data
    'user:email', // access to email
  ];

  // GitHub API endpoints - usually don't need to be changed
  static const String githubAuthUrl =
      'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String githubApiUrl = 'https://api.github.com';
}
