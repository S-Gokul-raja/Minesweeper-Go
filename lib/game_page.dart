import 'dart:developer';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'highscore.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late int level;
  bool isInit = false;
  List<Map<String, dynamic>> values = [];
  List<int> flags = [];
  List<int> bombs = [];
  late int score;
  late HighScore highScore;
  late double percentageOfBombs;
  late int revealedCount;
  static const int startLevel = 7, endLevel = 11;
  @override
  void initState() {
    level = startLevel;
    percentageOfBombs = 0.1;
    score = 0;
    generateValues();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!isInit) {
      setState(() {
        highScore = Provider.of<HighScore>(context);

        isInit = true;
      });
    }
    super.didChangeDependencies();
  }

  generateValues() {
    setState(() {
      values = [];
      bombs = [];
      flags = [];
      revealedCount = 0;
      for (int i = 0; i < level * level; i++) {
        values.add({'revealed': false, 'value': 0});
      }

      int bombsLength = level * level * percentageOfBombs > level * level
          ? level * level
          : (level * level * percentageOfBombs).toInt();
      //generate bombs
      for (int i = 0; i < bombsLength; i++) {
        int index = -1;
        do {
          log(index.toString());
          index = math.Random().nextInt(level * level);
        } while (bombs.contains(index));
        values[index]['value'] = -1;
        bombs.add(index);
        List<int> neighbours = [
          if (index - level >= 0) index - level,
          if (index + level < level * level) index + level,
          if ((index % level) - 1 >= 0) index - 1,
          if ((index % level) + 1 < level) index + 1,
          if (index - level >= 0 && ((index - level) % level) + 1 < level)
            index - level + 1,
          if (index - level >= 0 && ((index - level) % level) - 1 >= 0)
            index - level - 1,
          if (index + level < level * level &&
              ((index + level) % level) + 1 < level)
            index + level + 1,
          if (index + level < level * level &&
              ((index + level) % level) - 1 >= 0)
            index + level - 1,
        ];
        for (int j in neighbours) {
          if (values[j]['value'] != -1) {
            values[j]['value'] += 1;
          }
        }
      }
    });
  }

  nextLevel() async {
    if (score + 1 > highScore.score) {
      await highScore.setScore(score + 1);
    }
    setState(() {
      score += 1;

      level = level < endLevel ? level + 1 : level;
      percentageOfBombs *= level < endLevel ? 1 : 1.2;
      generateValues();
    });
  }

  colorForValue(value) {
    switch (value) {
      case -1:
        return Colors.black;
      case 0:
        return Colors.lightBlue[100];
      default:
        return Color.lerp(Colors.pink.shade100, Colors.pink, (value - 1) / 8);
    }
  }

  textForValue(value) {
    switch (value) {
      case -1:
        return '';
      case 0:
        return '';
      default:
        return value.toString();
    }
  }

  reset() {
    setState(() {
      level = startLevel;
      score = 0;
      generateValues();
    });
  }

  gameOver() async {
    if (score > highScore.score) {
      await highScore.setScore(score);
    }
    log("Game over");
    await Future.delayed(const Duration(seconds: 2)).then((_) {
      reset();
    });
  }

  revealAllSafeArea(int index) {
    log("reveal safe index: $index");
    setState(() {
      values[index]['revealed'] = true;
      revealedCount += 1;
    });
    List<int> neighbours = [
      if (index - level >= 0) index - level,
      if (index + level < level * level) index + level,
      if ((index % level) - 1 >= 0) index - 1,
      if ((index % level) + 1 < level) index + 1,
      if (index - level >= 0 && ((index - level) % level) + 1 < level)
        index - level + 1,
      if (index - level >= 0 && ((index - level) % level) - 1 >= 0)
        index - level - 1,
      if (index + level < level * level &&
          ((index + level) % level) + 1 < level)
        index + level + 1,
      if (index + level < level * level && ((index + level) % level) - 1 >= 0)
        index + level - 1,
    ];
    for (int i = 0; i < neighbours.length; i++) {
      if (!values[neighbours[i]]['revealed'] &&
          values[neighbours[i]]['value'] == 0) {
        revealAllSafeArea(neighbours[i]);
      }
    }
  }

  actionForValue(index) {
    if (flags.contains(index)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 2),
        content: Text("Can't reveal flagged"),
      ));
      return;
    }
    setState(() {
      switch (values[index]['value']) {
        case -1:
          values[index]['revealed'] = true;
          gameOver();
          break;
        case 0:
          if (!values[index]['revealed']) {
            revealAllSafeArea(index);
          }
          break;
        default:
          values[index]['revealed'] = true;
          revealedCount += 1;
          break;
      }
    });
  }

  stageWonByBombsDiscovered() {
    //bombs and flag has same index
    if (bombs.length != flags.length) {
      return false;
    }
    for (int i = 0; i < bombs.length; i++) {
      if (!flags.contains(bombs[i])) {
        return false;
      }
    }
    return true;
  }

  stageWonByExplored() {
    if (revealedCount != values.length - bombs.length) {
      return false;
    }
    return true;
  }

  revealAll() {
    setState(() {
      for (int i = 0; i < level * level; i++) {
        values[i]['revealed'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          height: Get.height - Get.bottomBarHeight - Get.statusBarHeight,
          width: Get.width,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AutoSizeText(
                              'BOMBS',
                              minFontSize: 12,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey),
                            ),
                            AutoSizeText(
                              bombs.length.toString(),
                              minFontSize: 12,
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.pink),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const AutoSizeText(
                              'AVAIL. FLAGS',
                              minFontSize: 12,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey),
                            ),
                            AutoSizeText(
                              (bombs.length - flags.length).toString(),
                              minFontSize: 12,
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.pink),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AutoSizeText(
                              'HIGH SCORE',
                              minFontSize: 12,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey),
                            ),
                            AutoSizeText(
                              highScore.score.toString(),
                              minFontSize: 12,
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.pink),
                            ),
                          ],
                        ),
                        AutoSizeText(
                          score.toString(),
                          minFontSize: 25,
                          style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: level,
                  childAspectRatio: 1,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: level * level,
                itemBuilder: (context, index) {
                  //log('itembuilder $index ');
                  return GestureDetector(
                    onLongPress: () async {
                      if (flags.contains(index)) {
                        setState(() {
                          flags.remove(index);
                        });
                      } else {
                        if (flags.length < bombs.length &&
                            !values[index]['revealed']) {
                          setState(() {
                            flags.add(index);
                          });
                        } else if (flags.length == bombs.length) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            duration: Duration(seconds: 2),
                            content: Text("Maximum flags used"),
                          ));
                        } else if (values[index]['revealed']) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            duration: Duration(seconds: 2),
                            content: Text("Can't flag revealed"),
                          ));
                        }
                      }
                      if (stageWonByBombsDiscovered() || stageWonByExplored()) {
                        revealAll();

                        await Future.delayed(const Duration(seconds: 2))
                            .then((_) {
                          nextLevel();
                        });
                      }
                    },
                    onTap: () async {
                      actionForValue(index);
                      if (stageWonByBombsDiscovered() || stageWonByExplored()) {
                        revealAll();

                        await Future.delayed(const Duration(seconds: 2))
                            .then((_) {
                          nextLevel();
                        });
                      }
                    },
                    child: Container(
                      color: (!values[index]['revealed'])
                          ? Colors.white
                          : colorForValue(values[index]['value']),
                      child: LayoutBuilder(
                        builder: (cotext, constraints) {
                          return Stack(
                            children: [
                              Center(
                                child: Text(
                                  (!values[index]['revealed'])
                                      ? ''
                                      : textForValue(values[index]['value']),
                                  style: TextStyle(
                                    fontSize: constraints.maxHeight / 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (values[index]['revealed'] &&
                                  values[index]['value'] == -1)
                                const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.bomb,
                                    color: Colors.pink,
                                  ),
                                ),
                              if (!values[index]['revealed'] &&
                                  flags.contains(index))
                                const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.solidFlag,
                                    color: Colors.pink,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
