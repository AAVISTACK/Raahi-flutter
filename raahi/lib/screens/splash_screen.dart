import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';
  import 'package:firebase_auth/firebase_auth.dart';

  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});
    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen> {
    @override
    void initState() {
      super.initState();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final user = FirebaseAuth.instance.currentUser;
        context.go(user != null ? '/home' : '/phone-login');
      });
    }
    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: SizedBox.shrink(),
      );
    }
  }
  