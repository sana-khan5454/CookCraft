import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_recipe_screen.dart';

class ViewRecipesScreen extends StatelessWidget {
  const ViewRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Recipes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recipes found"));
          }

          final recipes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final doc = recipes[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'],
                      width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image),

                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text(data['time'] ?? ''),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditRecipeScreen(
                          docId: doc.id,
                          recipeData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}