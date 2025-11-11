import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
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
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(Icons.shopping_cart, "Verkoop starten"),
          _buildCard(Icons.inventory, "Voorraad beheren"),
          _buildCard(Icons.bar_chart, "Rapporten bekijken"),
          _buildCard(Icons.settings, "Instellingen"),
          _buildCard(Icons.person, "Gebruikers & login"),
        ],
      ),
    );
  }

  Widget _buildCard(IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: 
BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          debugPrint("$title ingedrukt");
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: 
FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Text(
            '🔥 Fout bij opstart:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

