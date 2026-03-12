import 'package:flutter/material.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos e Renda Extra'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Projetos em construção')),
    );
  }
}
