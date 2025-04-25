import 'exports.dart';

class HistoryPage extends StatelessWidget {
  final String uid;
  const HistoryPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('history').doc(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction History'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final predictionsArray = List.from(data?['predictions'] ?? []);

          if (predictionsArray.isEmpty) {
            return const Center(child: Text("No history found."));
          }

          return ListView.builder(
            itemCount: predictionsArray.length,
            itemBuilder: (context, index) {
              final entry = predictionsArray[index];
              final preds = List.from(entry['predictions'] ?? []);
              final base64Image = entry['imageBase64'];
              final timestamp = entry['timestamp'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (base64Image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(base64Image),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text("⏰ Timestamp: $timestamp"),
                      const SizedBox(height: 10),
                      ...preds.map((pred) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🔍 Label: ${pred['label']}"),
                            Text("✅ Confidence: ${(100 * pred['confidence']).toStringAsFixed(2)}%"),
                            const Divider(),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
