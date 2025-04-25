import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skin_cancer_detector/SkinCancerDetectorApp.dart'; // Adjust path

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Skin Cancer Detector",
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => signInAnonymously(context),
              icon: const Icon(Icons.login),
              label: const Text("Sign In Anonymously"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signInAnonymously(BuildContext context) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in with temporary account.");
      print(userCredential.user?.uid);

      // Navigate safely using valid context
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SkinCancerDetectorApp(uid: userCredential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "operation-not-allowed":
          print("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          print("Unknown error: ${e.code}");
      }
    }
  }
}
