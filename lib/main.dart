import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'game_page.dart';
import 'highscore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MineSweeperGo());
}

class MineSweeperGo extends StatelessWidget {
  const MineSweeperGo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HighScore(),
      builder: (context, _) {
        return const MaterialApp(
          title: 'MineSweeper Go',
          debugShowCheckedModeBanner: false,
          home: GamePage(),
        );
      },
    );
  }
}
