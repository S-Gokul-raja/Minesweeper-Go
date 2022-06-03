import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HighScore with ChangeNotifier {
  int score = 0;
  HighScore() {
    init();
  }
  init() async {
    Box<int> box = await Hive.openBox<int>('MineSweeperGo-HighScore',
        compactionStrategy: (entries, deletedEntries) {
      return deletedEntries > 15;
    });
    score = box.get('score') ?? 0;

    notifyListeners();
  }

  setScore(int newScore) async {
    Box<int> box = await Hive.openBox<int>('MineSweeperGo-HighScore',
        compactionStrategy: (entries, deletedEntries) {
      return deletedEntries > 15;
    });
    score = newScore;
    await box.put('score', newScore);
    log('set score : $score');
    notifyListeners();
  }
}
