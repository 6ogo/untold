import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';


class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        // Create instances of the providers
        EmailAuthProvider(), // This is now correct
        GoogleProvider(clientId: '182858145641-f5u406jqcc9tksgd6ski8prf0ed3t50k'),
        //FacebookProvider(clientId: 'YOUR_FACEBOOK_APP_ID'),
        // Add other providers here
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, _) {
          Navigator.pushReplacementNamed(context, '/camera');
        }),
      ],
    );
  }
}