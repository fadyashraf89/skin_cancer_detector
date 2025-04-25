import 'exports.dart';

class SkinCancerDetectorApp extends StatelessWidget {
  final String uid;

  const SkinCancerDetectorApp({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Cancer Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: ModelTestPage(uid: uid),
      debugShowCheckedModeBanner: false,
    );
  }
}
