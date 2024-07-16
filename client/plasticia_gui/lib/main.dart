import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appstate.dart';
import 'focus_page.dart';
import 'monitor_page.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';



void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
     const initialSize = Size(1500, 900);
     appWindow.minSize = Size(600, 400);
     appWindow.size = initialSize;
     appWindow.alignment = Alignment.center;
     appWindow.show();
   });
}

class WindowButtons extends StatelessWidget {
  

  WindowButtons({Key? key}) : super(key: key);

  final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF805306),
    mouseOver: const Color(0xFFF6A00C),
    mouseDown: const Color(0xFF805306),
    iconMouseOver: const Color(0xFF805306),
    iconMouseDown: const Color(0xFFFFD500));

  final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: const Color(0xFF805306),
      iconMouseOver: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: "Manrope",
          dividerColor: Colors.transparent,),
        home: const SplashScreen(),
      ),
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _fadeIn();
  }

  void _fadeIn() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });

      Future.delayed(const Duration(seconds: 2), () {
        _navigateToHome();
      });
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2){
          return FadeTransition(
            opacity: animation1,
            child: const HomeScreen(),
          );
        }
      ),
    );
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.white,
          ),
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            child: Padding(
              padding: const EdgeInsets.all(100.0),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: SizedBox(
                    width: 1200,
                    child: Image.asset('assets/plasticia-logo.png')),
                ), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  var selectedIndex = 0;

  Future<List> checkSever() async{
    var serverStatus = [false, false, false];
    var url = Uri.http("localhost:6155", "/check_status");
    var response = await http.get(url);
    if(response.statusCode == 200){
      serverStatus[0] = true;
      if(response.body == "Napcat"){
        serverStatus[1] = true;
      } else if (response.body == "Elastic"){
        serverStatus[2] = true;
      } else {
        serverStatus[1] = true;
        serverStatus[2] = true;
      }
    }
    return serverStatus;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
  
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const OverviewPage();
        break;
      case 1:
        page = const FocusPage();
        break;
      case 2:
        page = const MonitorPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // ignore: no_leading_underscores_for_local_identifiers
    void _showDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('运行信息', style: TextStyle(fontFamily: "HK", fontWeight: FontWeight.bold)),
            content: FutureBuilder(
              future: checkSever(),
              builder: (context, snapshot){
                if(snapshot.hasData){
                  var status = snapshot.data as List;
                  return Row(
                    children: [
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Plasticia Server", style: TextStyle(fontFamily: "Manrope")),
                          Text("Napcat Server", style: TextStyle(fontFamily: "Manrope")),
                          Text("Elastic Server", style: TextStyle(fontFamily: "Manrope"))
                      ]),
                      const SizedBox(width: 20,),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        
                        children: [
                          Text(
                            status[0] ? "Online" : "Offline",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.bold,
                              color: !status[0] ? const Color.fromARGB(255, 158, 59, 59) : const Color.fromARGB(255, 58, 109, 60))),
                          Text(
                            status[1] ? "Online" : "Offline",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.bold,
                              color: !status[0] ? const Color.fromARGB(255, 158, 59, 59) : const Color.fromARGB(255, 58, 109, 60))),
                          Text(
                            status[2] ? "Online" : "Offline",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.bold,
                              color: !status[0] ? const Color.fromARGB(255, 158, 59, 59) : const Color.fromARGB(255, 58, 109, 60))),
                        ],
                      )
                    ],);
                } else {
                  // 加载动画
                  return const Column(
                    children: [
                      SizedBox(height: 30,),
                      CircularProgressIndicator(),
                      SizedBox(height: 30,),
                    ],
                  );
                }
              }),
            actions: [
              TextButton(
                child: const Text('关闭', style: TextStyle(fontFamily: "HK", fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    
    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      
      body:LayoutBuilder(
          builder: (context, constraints) {
          return Column(
            children: [
              SizedBox(
                height: 32,
                child: WindowTitleBarBox(
                  child: Row(
                    children: [Expanded(child: MoveWindow()), WindowButtons()],
                  ),
                ),
              ),
              SizedBox(
                height: constraints.maxHeight - 32,
                child: Row(
                    children: [
                      SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 200,
                              child: NavigationRail(
                                extended: constraints.maxWidth >= 600,
                                destinations: const [
                                  NavigationRailDestination(
                                    icon: Icon(Icons.home),
                                    label: Text('Overview'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.favorite),
                                    label: Text('Focus'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.remove_red_eye),
                                    label: Text('Monitor'),
                                  ),
                                ],
                                selectedIndex: selectedIndex,
                                onDestinationSelected: (value) {
                                  setState(() {
                                    selectedIndex = value;
                                  });
                                },
                              ),
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    _showDialog(context);
                                  },
                                ),
                              )
                            ],
                          )
                          ],
                        ),
                      ),
                      Expanded(child: mainArea),
                    ],
                  ),
              ),
            ],
          );
          },
        ),
        
    );
  
  }
}

class OverviewPage extends StatefulWidget{
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  var serviceVariant = List.filled(5, false, growable: true);
  Timer? _timer;
  late AppState appState;
  @override
  void initState() {
    super.initState();
    startPolling();
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = Provider.of<AppState>(context);
  }

  void startPolling() {
    const interval = Duration(seconds: 5);

    _timer = Timer.periodic(interval, (timer) {

      print("Polling data...");
      requestNewMsg();
    });
  }
  
  Future<String> requestNewMsg() async {
    var url = Uri.http("localhost:6155", "/recent_msg");
    var response = await http.get(url);
    if(response.statusCode == 200){
      var msgList = jsonDecode(response.body);
      if(msgList.length > 0){
        for(int i = 0; i < msgList.length; ++i){
          if(msgList[i]["msg_type"] == "text" && msgList[i]["content"] != null)
          {
            print("New msg: ${msgList[i]["content"]}");
            appState.addHistory(msgList[i]);
          }
        }
      }
      return response.body;
    }
    else{
      return "";
    }
  }

  

  @override
  void dispose() {
    _timer?.cancel(); // 在组件销毁时取消定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: SizedBox(height: 0)),
          Title(),
          SizedBox(height: 100,),

          Expanded(flex: 2,child: HistoryListView()),
        ],
      ),
    );
  }

  Row bulidRow(name, appState) {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(name, style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
            ),
            const Expanded(child: SizedBox(width: 100)),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Switch(
                value: appState.serviceEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    appState.toggleSerivice();
                  });
                },
              ),
            )
          ],
        );
  }
}

class Title extends StatelessWidget {
  const Title({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, right: 30.0),
      child: SizedBox(
        width: 600,
        child: Image.asset('assets/plasticia-logo.png')),
    );
      
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.9],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  Widget formatText(data){
    var contentTextStyle = const TextStyle(
                      fontFamily: "HK",
                      fontSize: 18,
                      fontWeight: FontWeight.bold);
    var annotationTextStyle = const TextStyle(
                      fontFamily: "HK",
                      fontSize: 12,);
    var sender = data["sender"]["nickname"];
    var user_id = data["sender"]["user_id"];
    var content = data["content"];
    var time = data["time"];
    if(data['privacy'] == "group"){
      var group_id = data["group_id"];
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:[
          Text("「 $content 」", style: contentTextStyle,),
          Text("来自: $sender （$user_id）在 $group_id 群中于 $time 发送", style: annotationTextStyle,),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children:[
          Text("「 $content 」", style: contentTextStyle,),
          Text("来自: $sender （$user_id）于 $time 发送", style: annotationTextStyle,),
        ],
      );
    }
    

  }
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstOut,
      child: AnimatedList(
        key: _key,
        reverse: false,
        padding: EdgeInsets.only(bottom: 10),
        initialItemCount: appState.historyList.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.historyList[appState.historyList.length - index - 1];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  
                },
                label: CustomPopup(
                  content: formatText(pair),
                  child: Text(
                    pair["content"],
                    style: const TextStyle(
                      fontFamily: "HK",
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


