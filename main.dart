/*
1. 이전 코드에서 play.dart 를 우선 만들어서 스크린 위젯으로 추가할거야
   --> 왜냐면 이게 핵심이니까..
2. 위에게 만들어지면, 이후 다른 스크린 위젯 추가해서 꾸밀거야...

 */
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:advertising_id/advertising_id.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

String imgBgApp = 'assets/images/app/bg_05.webp';

final GetStorage _box = GetStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // GetStorage 초기화

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sliding Puzzle',
      theme: ThemeData(fontFamily: 'Acme'),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String? _html;

  @override
  void initState() {
    super.initState();
    //_loadHtml();

    if (Const.adid == Const.adidDefault) {
      (() async {
        if (Platform.isAndroid) {
          Const.adid = await AdvertisingId.id(true) ?? Const.adidDefault;
        } else if (Platform.isIOS) {
          try {
            final status = await AppTrackingTransparency.requestTrackingAuthorization();
            if (status == TrackingStatus.authorized) {
              Const.adid = await AppTrackingTransparency.getAdvertisingIdentifier();
            } else {
              debugPrint("TrackingStatus.authorized failed");
            }
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      })();
    }

    debugPrint(Const.adid);
  }

  Future<void> _loadHtml() async {
    final response = await http.get(Uri.parse('https://flutter.dev'));
    if (response.statusCode == 200) {
      debugPrint(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app/bg_05.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 메인 컨텐츠를 Center로 감싸서 중앙 정렬
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sliding Game",
                      style: TextStyle(
                        fontFamily: 'Acme',
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 0), // 그림자 위치 (x, y)
                            blurRadius: 20, // 흐림 정도
                            color: Colors.black, // 그림자 색
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),

                    // 게임 크기 버튼들
                    ...List.generate(5, (index) {
                      final size = index + 3; // 3부터 7까지
                      return Column(
                        children: [
                          Unit.getButtonType1("$size X $size", () {
                            Unit.showDialogLevel(context, size);
                          }),
                          SizedBox(height: 20),
                        ],
                      );
                    }),

                    SizedBox(height: 20),

                    // 랭크 버튼
                    Unit.getButtonType1("Rank", () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Color.fromRGBO(255, 255, 255, 1),
                        builder: (BuildContext context) {
                          return PopupRankList();
                        },
                      );
                    }),
                  ],
                ),
              ),

              // 정보 버튼을 우하단에 위치
              Positioned(
                right: 20,
                bottom: 20,
                child: IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white, size: 25),
                  onPressed: () async {
                    final content = await Unit.getInfo();
                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: SingleChildScrollView(child: content),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PlayScreen extends StatefulWidget {
  final int size;
  final int level;

  const PlayScreen({super.key, required this.size, required this.level});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late int puzlSize;
  late Puzzle myPuzl;
  late double numSize;

  @override
  void initState() {
    super.initState();
    puzlSize = widget.size;
    numSize = 45;
    if (puzlSize == 4) {
      numSize = 35;
    } else if (puzlSize == 5) {
      numSize = 30;
    } else if (puzlSize == 6) {
      numSize = 25;
    } else if (puzlSize == 7) {
      numSize = 22;
    }
    myPuzl = Puzzle(size: puzlSize, level: widget.level);
    Get.put(myPuzl);
  }

  @override
  void dispose() {
    if (Get.isRegistered<Puzzle>()) Get.delete<Puzzle>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app/bg_03.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 40, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Unit.getButtonType2(
                          myPuzl.status == 'pause' ? Icons.play_arrow : Icons.pause,
                          () {
                            if (myPuzl.status == "done") return;
                            if (myPuzl.isHintMode) return;
                            setState(() {
                              if (myPuzl.status == "pause")
                                myPuzl.status = "play";
                              else
                                myPuzl.status = "pause";
                            });
                          },
                        ),

                        SizedBox(width: 20),
                        Obx(() {
                          return Text(
                            myPuzl.formattedTime,
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,

                              shadows: [
                                Shadow(
                                  offset: Offset(0, 0), // 그림자 위치 (x, y)
                                  blurRadius: 20, // 흐림 정도
                                  color: Colors.black, // 그림자 색
                                ),
                              ], //
                            ),
                          );
                        }),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Moves",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,

                            shadows: [
                              Shadow(
                                offset: Offset(0, 0), // 그림자 위치 (x, y)
                                blurRadius: 20, // 흐림 정도
                                color: Colors.black, // 그림자 색
                              ),
                            ], //
                          ),
                        ),
                        SizedBox(width: 20),
                        Obx(() {
                          return Text(
                            myPuzl.moveCount.toString(),
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,

                              shadows: [
                                Shadow(
                                  offset: Offset(0, 0), // 그림자 위치 (x, y)
                                  blurRadius: 20, // 흐림 정도
                                  color: Colors.black, // 그림자 색
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Align(
                    alignment: Alignment.center, // 세로+가로 중앙
                    child: Container(
                      width: MediaQuery.of(context).size.width - 20,
                      height: MediaQuery.of(context).size.width - 20,
                      color: Colors.white.withAlpha(60),
                      child: Obx(() {
                        List<int> zpl = List.from(myPuzl.zeroPosList);
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: puzlSize, // 3개의 열
                            childAspectRatio: 1, // 아이템 가로 세로 비율
                            crossAxisSpacing: 3, // 열 간의 간격
                            mainAxisSpacing: 3, // 행 간의 간격
                          ),
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          itemCount: puzlSize * puzlSize,
                          itemBuilder: (BuildContext context, int index) {
                            int row = index ~/ puzlSize;
                            int col = index % puzlSize;

                            if (zpl[0] == row && zpl[1] == col) return Container();
                            return Material(
                              color: Colors.transparent, // 배경 투명하게
                              child: InkWell(
                                onTap: () {
                                  if (myPuzl.status == "done") return;
                                  if (myPuzl.status == "pause") return;
                                  if (myPuzl.isHintMode) return;

                                  myPuzl.move(row, col);
                                  if (myPuzl.status == "done") {
                                    String key = "rank_${puzlSize}_${myPuzl.level}";
                                    final now = DateTime.now();

                                    Map<String, dynamic> obj = {};
                                    obj['duration'] = myPuzl.formattedTime;
                                    obj['move'] = myPuzl.moveCount.value;
                                    obj['date'] = Utils.formatDateString(
                                      DateFormat('yyyy.M.d   HH:mm').format(DateTime.now()),
                                    );

                                    List rankList = _box.read(key) ?? [];
                                    rankList.add(obj);
                                    rankList.sort((a, b) {
                                      int durationCompare = a['duration'].compareTo(b['duration']);
                                      if (durationCompare != 0) return durationCompare;
                                      int moveCompare = (a['move'] as int).compareTo(
                                        b['move'] as int,
                                      );
                                      if (moveCompare != 0) return moveCompare;
                                      return b['date'].compareTo(a['date']);
                                    });
                                    if (rankList.length > 5) {
                                      rankList = rankList.sublist(0, 5);
                                    }
                                    print('rankList');
                                    print(rankList);
                                    _box.write(key, rankList);

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          backgroundColor: Colors.blue,
                                          child: SizedBox(
                                            height: 200, // 원하는 높이 지정
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(10),
                                                  child: Text(
                                                    "Congratulations!",
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),

                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.only(
                                                        bottomLeft: Radius.circular(20),
                                                        bottomRight: Radius.circular(20),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Padding(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                          ),
                                                          child: Text(
                                                            "You have successfully completed it!",
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                            ), // 원하는 크기로 조절
                                                          ),
                                                        ),
                                                        SizedBox(height: 20),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.spaceEvenly,
                                                          children: [
                                                            ElevatedButton(
                                                              child: Text("Close"),
                                                              onPressed: () {
                                                                Unit.showDialogAd(
                                                                  context,
                                                                  'close',
                                                                  this,
                                                                );
                                                              },
                                                            ),
                                                            ElevatedButton(
                                                              child: Text("Restart"),
                                                              onPressed: () {
                                                                Unit.showDialogAd(
                                                                  context,
                                                                  'restart',
                                                                  this,
                                                                );
                                                              },
                                                            ),
                                                            ElevatedButton(
                                                              child: Text("New"),
                                                              onPressed: () {
                                                                Unit.showDialogAd(
                                                                  context,
                                                                  'new',
                                                                  this,
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },

                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(120),
                                    border: Border(
                                      top: BorderSide(color: Colors.white, width: 2),
                                      left: BorderSide(color: Colors.white, width: 2),
                                      right: BorderSide(color: Colors.black, width: 2),
                                      bottom: BorderSide(color: Colors.black, width: 2),
                                    ),
                                  ),

                                  child: Center(
                                    child: Text(
                                      myPuzl.puzl[row][col]["num"].toString(),
                                      style: TextStyle(
                                        fontSize: numSize,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(-1, -1),
                                            blurRadius: 2.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),

              Unit.getButtonType1("New", () {
                setState(() {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                });
              }),
              SizedBox(height: 20),
              Unit.getButtonType1("Hint", () {
                setState(() {
                  myPuzl.hint();
                });
              }),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class Utils {
  static void goPagePush(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  static void goPageNew(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (Route<dynamic> route) => false,
    );
  }

  static String formatDateString(String dateStr) {
    final regex = RegExp(r'\b(\d{2}:\d{2})\b');
    Iterable<Match> matches = regex.allMatches(dateStr);

    if (matches.isNotEmpty) {
      String hm = matches.first.group(0) ?? "";
      String ymd = dateStr.replaceAll(hm, "").trim();

      String workStr = ymd;
      String delimiter = '/';
      if (!workStr.contains(delimiter)) delimiter = '.';
      List<String> dateParts = workStr.split(delimiter);

      for (int i = 0; i < dateParts.length; i++) {
        String val = dateParts[i].trim();
        if (val.length == 1) {
          dateParts[i] = "0$val";
        } else if (val.isEmpty) {
          dateParts.removeAt(i);
        } else {
          dateParts[i] = val;
        }
      }

      workStr = dateParts.join(delimiter);
      dateStr = dateStr.replaceAll(ymd, workStr);

      return dateStr;
    } else {
      return dateStr;
    }
  }
}

class Puzzle extends GetxController {
  int size;
  int level;
  RxList<int> zeroPosList = [0, 0].obs;
  var puzl = <List<Map<String, int>>>[];

  late List<int> zeroPosListForRestart;
  late List<List<Map<String, int>>> puzlForRestart;

  List<String> initActions = [];
  List<String> playActions = [];

  List<String> initStates = [];
  List<String> playStates = []; // status : ready, play, pause, done,

  String status = "ready";

  RxInt elapsedTime = 0.obs;
  RxInt moveCount = 0.obs;

  bool isHintMode = false;
  late Timer _timer;

  Puzzle({this.size = 3, this.level = 1}) {
    init();
  }

  void init() {
    zeroPosList.value = [size - 1, size - 1];
    // 초기화
    for (int i = 0; i < size; i++) {
      List<Map<String, int>> row = [];
      for (int j = 0; j < size; j++) {
        Map<String, int> tmp = {};
        tmp["num"] = ((i * size) + j + 1) % (size * size); // 1 % 9 -> %: mod, 나눈 나머진 값
        row.add(tmp);
      }
      puzl.add(row);
    }

    // shuffle : 섞기
    _shuffle(level);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (status == "play" && !isHintMode) elapsedTime.value++;
    });

    zeroPosListForRestart = List.from(zeroPosList);
    puzlForRestart =
        puzl.map((row) => row.map((map) => Map<String, int>.from(map)).toList()).toList();
  }

  void restart() {
    zeroPosList.value = List.from(zeroPosListForRestart);
    puzl =
        puzlForRestart.map((row) => row.map((map) => Map<String, int>.from(map)).toList()).toList();

    playActions = [];
    playStates = [];

    elapsedTime.value = 0;
    moveCount.value = 0;

    status = "play";
  }

  void _shuffle(int level) async {
    int shuffleCount = _getShuffleCountByLevel(level);

    String preDirect = "";
    //await Future.delayed(Duration(milliseconds: 1000));
    for (int i = 0; i < shuffleCount; i++) {
      List possibleDirect = getPossibleDirection();
      if (preDirect != "") possibleDirect.remove(getReverseDirect(preDirect));

      var random = Random();
      var choice = random.nextInt(possibleDirect.length);
      var choicedDirect = possibleDirect[choice];

      setPuzzle(choicedDirect);
      preDirect = choicedDirect;

      initActions.add(choicedDirect);
      String state = puzl.expand((row) => row).map((e) => e['num'].toString()).join(',');
      initStates.add(state);
      //await Future.delayed(Duration(milliseconds: 500)); // -> async
    }

    status = "play";
  }

  int _getShuffleCountByLevel(int level) {
    switch (level) {
      case 1:
        return 1; // 렙1
      case 2:
        return 2; // 렙2
      case 3:
        return 4; // 렙3
    }
    throw ArgumentError('Invalid level: $level');
  }

  List<String> getPossibleDirection() {
    List<String> res = [];
    int x = zeroPosList[0];
    int y = zeroPosList[1];
    //사용자 움직임 저장
    if (x == 0) {
      res.add('down');
    } else if (x == size - 1) {
      res.add('up');
    } else {
      res.add('up');
      res.add('down');
    }

    if (y == 0) {
      res.add('right');
    } else if (y == size - 1) {
      res.add('left');
    } else {
      res.add('left');
      res.add('right');
    }

    return res;
  }

  String getReverseDirect(String direct) {
    if (direct == "up")
      return "down";
    else if (direct == 'down')
      return 'up';
    else if (direct == 'left')
      return 'right';
    else
      return 'left';
  }

  //힌트 참고(반대움직임)
  void setPuzzle(String direct) {
    int x = zeroPosList[0];
    int y = zeroPosList[1];

    if (direct == 'up') {
      _swap(x, y, x - 1, y);
      x--;
    } else if (direct == 'down') {
      _swap(x, y, x + 1, y);
      x++;
    } else if (direct == 'left') {
      _swap(x, y, x, y - 1);
      y--;
    } else if (direct == 'right') {
      _swap(x, y, x, y + 1);
      y++;
    }
    zeroPosList.value = [x, y];
  }

  void _swap(int row1, int col1, int row2, int col2) {
    var temp = puzl[row1][col1];
    puzl[row1][col1] = puzl[row2][col2];
    puzl[row2][col2] = temp;
  }

  String _getPossibleMove(int x, int y) {
    String direct = "";

    if (x - 1 == zeroPosList[0] && y == zeroPosList[1]) {
      direct = "down";
    } else if (x + 1 == zeroPosList[0] && y == zeroPosList[1]) {
      direct = "up";
    } else if (x == zeroPosList[0] && y - 1 == zeroPosList[1]) {
      direct = "right";
    } else if (x == zeroPosList[0] && y + 1 == zeroPosList[1]) {
      direct = "left";
    }

    return direct;
  }

  void move(int x, int y) {
    if (status == "done") return;

    String direct = _getPossibleMove(x, y);
    if (direct.isNotEmpty) {
      setPuzzle(direct);
      moveCount++;
      _isGameOver();

      playActions.add(direct);
      String state = puzl.expand((row) => row).map((e) => e['num'].toString()).join(',');
      playStates.add(state);
    }
  }

  void _isGameOver() {
    int num = 1;
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (num == size * size) num = 0;
        if (puzl[i][j]["num"] != num) {
          return;
        }
        num++;
      }
    }
    status = "done";
  }

  /// HH:mm:ss 포맷으로 변환
  String get formattedTime {
    int hours = elapsedTime.value ~/ 3600;
    int minutes = (elapsedTime.value % 3600) ~/ 60;
    int seconds = elapsedTime.value % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void hint() async {
    isHintMode = true;

    List<int> tmpZeroPosList = List.from(zeroPosList);
    List<List<Map<String, int>>> tmpPuzl =
        puzl
            .map((row) => row.map((map) => Map<String, int>.from(map)).toList()) // 내부 List 복사
            .toList();

    List<String> allActions = [];
    allActions.addAll(List<String>.from(initActions)); // initActions 복사
    allActions.addAll(List<String>.from(playActions)); // playActions 복사

    List<String> allStates = [];
    allStates.addAll(List<String>.from(initStates)); // initActions 복사
    allStates.addAll(List<String>.from(playStates)); // playActions 복사

    for (int i = allActions.length - 1; i >= 0; i--) {
      i = _searchState(allStates, i, allStates[i]);
      String actDirect = allActions[i];
      setPuzzle(getReverseDirect(actDirect));
      await Future.delayed(Duration(milliseconds: 200));
    }

    await Future.delayed(Duration(milliseconds: 1000));
    zeroPosList.assignAll(tmpZeroPosList);
    puzl =
        tmpPuzl
            .map((row) => row.map((map) => Map<String, int>.from(map)).toList()) // 내부 List 복사
            .toList();

    isHintMode = false;
  }

  int _searchState(List<String> allStates, int index, String state) {
    for (int i = 0; i < index; i++) {
      if (allStates[i] == state) return i;
    }
    return index;
  }
}

class PopupRankList extends StatefulWidget {
  const PopupRankList({super.key});

  @override
  PopupRankListState createState() => PopupRankListState();
}

class PopupRankListState extends State<PopupRankList> {
  String rankKey = "3_1";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> buttonLabels = ['3 X 3', '4 X 4', '5 X 5', '6 X 6', '7 X 7'];
    final List<String> gridLabel = ['Time', 'Duration', 'Move'];

    String key = "rank_$rankKey";
    List rankList = _box.read(key) ?? [];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(buttonLabels.length, (i) {
                int ss = i + 3;
                int ll = 1;
                String thisKey = "${ss}_$ll";

                return Padding(
                  padding: EdgeInsets.only(right: i == buttonLabels.length - 1 ? 0.0 : 15.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        rankKey = thisKey;
                      });
                    },
                    child: Text(
                      "${buttonLabels[i]} Level.1",
                      style: TextStyle(color: rankKey == thisKey ? Colors.blue : Colors.black),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 30),

          Expanded(
            child:
                rankList.isEmpty
                    ? Text('\n\nno data', style: TextStyle(fontSize: 18, color: Colors.blue))
                    : DataTable(
                      headingRowHeight: 30.0,
                      dataRowMinHeight: 46.0,
                      dataRowMaxHeight: 46.0,
                      columnSpacing: 20,
                      horizontalMargin: 10,

                      border: const TableBorder(
                        horizontalInside: BorderSide(width: 0),
                        verticalInside: BorderSide(width: 0),
                      ),

                      columns: [
                        DataColumn(
                          label: Text('time', style: TextStyle(fontSize: 20, color: Colors.blue)),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text(
                            'duration',
                            style: TextStyle(fontSize: 20, color: Colors.blue),
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('moves', style: TextStyle(fontSize: 20, color: Colors.blue)),
                        ),
                      ],
                      rows:
                          rankList.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    row['date'].toString(),
                                    style: TextStyle(fontSize: 18, color: Colors.blue),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    row['duration'].toString(),
                                    style: TextStyle(fontSize: 18, color: Colors.blue),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    row['move'].toString(),
                                    style: TextStyle(fontSize: 18, color: Colors.blue),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                      /*
              [
                DataRow(
                  cells: [DataCell(Text('Alice')), DataCell(Text('24')), DataCell(Text('Seoul'))],
                ),
              ],
              */
                    ),
          ),
        ],
      ),
    );
  }
}

class Const {
  static String adidDefault = "00000000-0000-0000-0000-000000000000";
  static String adid = "00000000-0000-0000-0000-000000000000";
}

class Style {
  static const themes = {
    "red": {"colorMain": Color(0xFFDC143C), "colorText": Color(0xFFDC143C)},
    "blue": {"colorMain": Color(0xFF1E90FF), "colorText": Color(0xFF1E90FF)},
    "green": {"colorMain": Color(0xFF3CB371), "colorText": Color(0xFF20AA5E)},
    "yellow": {"colorMain": Color(0xFFDAA520), "colorText": Color(0xFFDAA520)},
    "orange": {"colorMain": Color(0xFFFF7F50), "colorText": Color(0xFFFF7F50)},
  };

  static final theme =
      themes["blue"] ?? {"colorMain": Color(0xFFFF7F50), "colorText": Color(0xFFDC143C)};

  static TextStyle textCarve = TextStyle(
    fontFamily: 'Acme',
    fontWeight: FontWeight.bold,
    shadows: const [Shadow(offset: Offset(-1, -1), blurRadius: 1.0, color: Colors.black)],
    color: theme['colorText'],
  );

  static TextStyle textCommon = TextStyle(
    fontFamily: 'Acme', // 글꼴 패밀리
    color: theme['colorText'],
  );

  static TextStyle textIcon = TextStyle(
    fontFamily: 'MaterialSymbols',
    fontWeight: FontWeight.bold,
    color: theme['colorText'],
  );

  static TextStyle textNumber = TextStyle(
    fontFamily: 'BebasNeue',
    fontWeight: FontWeight.bold,
    color: theme['colorText'],
    letterSpacing: 3.0,
  );
}

class Unit {
  static Widget getButtonType1(String textStr, VoidCallback callback) {
    return ElevatedButton(
      onPressed: () {
        callback();
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        fixedSize: Size(150, 30),
        backgroundColor: Colors.black.withAlpha(100),
        shadowColor: Colors.black,
        elevation: 5,
        // 그림자 깊이
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(textStr, style: TextStyle(fontSize: 24, color: Colors.white)),
    );
  }

  static Widget getButtonType2(IconData icon, VoidCallback callback) {
    return ElevatedButton(
      onPressed: () {
        callback();
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        fixedSize: Size(30, 30),
        // 정사각형 크기 (60x60)
        backgroundColor: Colors.black.withAlpha(100),
        shadowColor: Colors.black,
        elevation: 20,
        shape: CircleBorder(),
      ),
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }

  static String _getOptimalUserAgent() {
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1';
    } else {
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }
  }

  static void showDialogAd(BuildContext context, String mode, _PlayScreenState obj) {
    String url = 'https://flutter.dev';
    //String url = 'https://ads-partners.coupang.com/widgets.html?id=750895&template=carousel&trackingCode=&subId=&width=680&height=150&device_id=';
    debugPrint(url);

    // click 새 브라우저 띄우게
    // User agent 변경
    // 각 줄의 의미가 뭔지 확인
    final WebViewController controller =
        WebViewController()
          //..setUserAgent(_getOptimalUserAgent())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url))
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) async {
                final uri = Uri.parse(request.url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              },
            ),
          );

    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: SizedBox(
            height: 490,
            child: Column(
              children: [
                SizedBox(height: 50, child: Text('\n[AD]')),
                SizedBox(height: 350, child: WebViewWidget(controller: controller)),
                SizedBox(height: 20),
                Unit.getButtonType1('close', () {
                  Navigator.of(context).pop();
                  if (mode == 'close') {
                  } else if (mode == 'restart') {
                    obj.setState(() {
                      obj.myPuzl.restart();
                    });
                  } else if (mode == 'new') {
                    Get.offAll(() => StartScreen());
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showDialogLevel(BuildContext context, int size) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 300,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀 영역 (파란색 배경)
                    Container(
                      height: 55,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Level",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),

                    // 선택 리스트 영역 (하얀색)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final level = index + 1;
                          return ListTile(
                            title: Text("Level $level"),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayScreen(size: size, level: level),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                // 닫기 버튼 (오른쪽 상단 X 버튼)
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<Widget> getInfo() async {
    String texts = await rootBundle.loadString('assets/texts/license.txt');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.close, color: Colors.blueGrey, size: 24),
              onPressed: () {
                Get.back(); // 또는 Navigator.pop(context); 사용
              },
            ),
          ],
        ),
        Text(
          "Privacy policy",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () async {
            Uri url = Uri.parse("http://www.ozian.net/static/en/srv/privacy.html");
            await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: Text("view details", style: TextStyle(color: Colors.black, fontSize: 10)),
        ),
        SizedBox(height: 20),
        Text(
          "Open source license",
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
    Padding(
    padding: EdgeInsets.only(left: 24),
    child: Text(
    texts,
    style: TextStyle(
    color: Colors.black,
    fontSize: 10,
    ),
    ),
    )
    ]);
  }
}
