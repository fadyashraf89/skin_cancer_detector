import 'exports.dart';

class SkinCancerDetectorApp extends StatelessWidget {
  const SkinCancerDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Cancer Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ModelTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
