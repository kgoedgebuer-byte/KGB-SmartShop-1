// lib/main.dart
import 'package:flutter/material.dart';

void main() => runApp(const SmartShopApp());

class SmartShopApp extends StatelessWidget {
  const SmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGB SmartShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const SmartShopHome(),
    );
  }
}

class SmartShopHome extends StatelessWidget {
  const SmartShopHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KGB SmartShop')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welkom bij KGB SmartShop',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('De slimme boodschappenlijst die lokaal én offline werkt.'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hier komt jouw echte start-flow.')),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
