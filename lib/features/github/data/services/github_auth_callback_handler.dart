import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'github_auth_service.dart';

/// Callback URL handler for GitHub OAuth
class GitHubAuthCallbackHandler {
  /// Handles the callback URL from GitHub OAuth
  static Future<void> handleCallback(Uri callbackUrl) async {
    try {
      final code = callbackUrl.queryParameters['code'];
      if (code == null) {
        throw Exception('Authorization code not found in callback URL');
      }

      final response = await http.post(
        Uri.parse(GitHubAuthService.githubTokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: {
          'client_id': GitHubAuthService.clientId,
          'client_secret': GitHubAuthService.clientSecret,
          'code': code,
          'redirect_uri': GitHubAuthService.redirectUrl,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to exchange code for token: ${response.body}');
      }

      final accessToken = response.body['access_token'];
      if (accessToken == null) {
        throw Exception('Access token not found in response');
      }

      await GitHubAuthService.saveToken(accessToken);
    } catch (e) {
      debugPrint('Error handling GitHub callback: $e');
      rethrow;
    }
  }
}
