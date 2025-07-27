import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';

class UserRecommendationsPage extends StatelessWidget {
  const UserRecommendationsPage({super.key});

  List<List<String>> _getRecommendedItems(List<Map<String, dynamic>> users) {
    List<List<String>> recommendedItems = [];
    for (var userDoc in users) {
      recommendedItems.add([userDoc['placeName']]);
    }
    return recommendedItems;
  }

  List<List<String>> _getRelevantItems(List<Map<String, dynamic>> users) {
    List<List<String>> relevantItems = [];
    for (var userDoc in users) {
      relevantItems.add([userDoc['placeName']]);
    }
    return relevantItems;
  }

  double calculateAveragePrecision(
      List<String> recommendedItems, List<String> relevantItems) {
    double totalPrecision = 0.0;
    int relevantCount = 0;

    for (int i = 0; i < recommendedItems.length; i++) {
      if (relevantItems.contains(recommendedItems[i])) {
        relevantCount++;
        totalPrecision += relevantCount / (i + 1);
      }
    }

    return relevantCount > 0 ? totalPrecision / relevantCount : 0.0;
  }

  double calculateMeanAveragePrecision(
      List<List<String>> recommendedItems, List<List<String>> relevantItems) {
    double totalMap = 0.0;

    for (int i = 0; i < recommendedItems.length; i++) {
      totalMap +=
          calculateAveragePrecision(recommendedItems[i], relevantItems[i]);
    }

    return recommendedItems.isNotEmpty
        ? totalMap / recommendedItems.length
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'User Klik',
                  style: AppWidget.boldTextFeildStyle(),
                ),
                IconButton(
                  icon: const Icon(Icons.countertops),
                  onPressed: () async {
                    // Mengambil data dengan async/await untuk menangani BuildContext
                    final snapshot = await FirebaseFirestore.instance
                        .collection('UserChoices')
                        .get();
                    final users =
                        snapshot.docs.map((doc) => doc.data()).toList();

                    List<List<String>> recommendedItems =
                        _getRecommendedItems(users);
                    List<List<String>> relevantItems = _getRelevantItems(users);
                    double mapScore = calculateMeanAveragePrecision(
                        recommendedItems, relevantItems);

                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('MAP Score'),
                          content: Text(
                              'Mean Average Precision (MAP): ${mapScore.toStringAsFixed(4)}'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('UserChoices')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No data found'));
                  }

                  final users = snapshot.data!.docs;
                  Map<String, List<Map<String, dynamic>>> groupedData = {};

                  for (var userDoc in users) {
                    final data = userDoc.data() as Map<String, dynamic>;
                    final userID = data['userID'] ?? 'No User';

                    if (!groupedData.containsKey(userID)) {
                      groupedData[userID] = [];
                    }

                    groupedData[userID]!.add(data);
                  }

                  return ListView.builder(
                    itemCount: groupedData.keys.length,
                    itemBuilder: (context, index) {
                      final userID = groupedData.keys.elementAt(index);
                      final userDataList = groupedData[userID]!;
                      userDataList.sort(
                          (a, b) => (a['rank'] ?? 0).compareTo(b['rank'] ?? 0));
                      return UserRecommendationsList(
                          userID: userID, userDataList: userDataList);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserRecommendationsList extends StatelessWidget {
  final String userID;
  final List<Map<String, dynamic>> userDataList;

  const UserRecommendationsList(
      {super.key, required this.userID, required this.userDataList});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'User ID: $userID',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      children: userDataList.map((data) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Container(
            height: 75,
            width: 270,
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            child: Container(
              margin: const EdgeInsets.only(left: 10, top: 5, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Place Name: ${data['placeName']}',
                      overflow: TextOverflow.ellipsis),
                  Text('Click Count: ${data['clickCount']}'),
                  Text('Rank: ${data['rank']}'),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
