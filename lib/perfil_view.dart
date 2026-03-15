import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilView extends StatelessWidget {
  final String userId;

  const PerfilView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("usuarios").doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final nombre = data?["nombre"] ?? "Sin nombre";
        final correo = FirebaseAuth.instance.currentUser?.email ?? "";

        return Scaffold(
          appBar: AppBar(title: const Text("Perfil")),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 20),
                Text(nombre, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text(correo, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
