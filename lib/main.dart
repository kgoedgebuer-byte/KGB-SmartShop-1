import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB5-v8V7O_lmWzmc2G51JQuSZYV6_hpCbA",
      authDomain: "kgb-smartshop-4051d.firebaseapp.com",
      projectId: "kgb-smartshop-4051d",
      storageBucket: "kgb-smartshop-4051d.appspot.com",
      messagingSenderId: "590564234631",
      appId: "1:590564234631:web:6be75396bb48908939af22",
    ),
  );
  runApp(const KGBSmartShopApp());
}

class KGBSmartShopApp extends StatelessWidget {
  const KGBSmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGB SmartShop',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            '✅ Firebase geladen – SmartShop draait!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
