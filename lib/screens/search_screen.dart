import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = "";

  // ✅ VOICE SEARCH OBJECT
  late stt.SpeechToText speech;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  // 🎤 START VOICE
  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(onResult: (result) {
        setState(() {
          query = result.recognizedWords.toLowerCase();
        });
      });
    }
  }

  // 🛑 STOP VOICE
  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Search Recipes"),
        backgroundColor: Colors.green,
      ),

      body: Column(
        children: [

          // 🔍 SEARCH BAR + MIC
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search recipe...",
                prefixIcon: const Icon(Icons.search),

                // 🎤 MIC BUTTON
                suffixIcon: IconButton(
                  icon: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    if (isListening) {
                      stopListening();
                    } else {
                      startListening();
                    }
                  },
                ),

                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => query = value.toLowerCase());
              },
            ),
          ),

          // 📋 RESULTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final recipes = snapshot.data!.docs.where((doc) {
                  final name =
                  doc['name'].toString().toLowerCase();
                  return name.contains(query);
                }).toList();

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text(
                      "No recipes found 😔",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final doc = recipes[index];
                    final data =
                    doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5)
                        ],
                      ),

                      child: ListTile(
                        leading: const Icon(
                          Icons.restaurant,
                          color: Colors.green,
                        ),

                        title: Text(
                          data['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),

                        subtitle:
                        Text(data['description'] ?? ""),

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),

                        // ✅ NAVIGATION FIXED
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(
                                    data: data,
                                    docId: doc.id,
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
          ),
        ],
      ),
    );
  }
}