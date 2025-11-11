import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-V8V7Op_lm2c65103uSZYV6_hpcDA",
      authDomain: "kgb-smartshop-4e510.firebaseapp.com",
      projectId: "kgb-smartshop-4e510",
      storageBucket: "kgb-smartshop-4e510.appspot.com",
      messagingSenderId: "590654234631",
      appId: "1:590654234631:web:6be75396bb4898893a9f22",
    ),
  );
  runApp(const SmartShopApp());
}

class SmartShopApp extends StatelessWidget {
  const SmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShop Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SmartShopDashboard(),
    );
  }
}

class SmartShopDashboard extends StatelessWidget {
  const SmartShopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartShop Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            icon: Icons.shopping_cart,
            title: "Verkoop starten",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Verkoopmodule komt 
binnenkort")),
              );
            },
          ),
          _buildCard(
            icon: Icons.inventory,
            title: "Voorraad beheren",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Voorraadbeheer wordt 
geladen...")),
              );
            },
          ),
          _buildCard(
            icon: Icons.bar_chart,
            title: "Rapporten bekijken",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rapporten volgen later")),
              );
            },
          ),
          _buildCard(
            icon: Icons.settings,
            title: "Instellingen",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Instellingen worden 
voorbereid")),
              );
            },
          ),
          _buildCard(
            icon: Icons.person,
            title: "Gebruikers & login",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Login-module binnenkort 
online")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: 
BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.green),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: 
FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

