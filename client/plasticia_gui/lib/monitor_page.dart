import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appstate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_popup/flutter_popup.dart';

class MonitorPage extends StatefulWidget{
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  
  var _isCardVisible = false;
  // ignore: prefer_typing_uninitialized_variables
  late var appState;
  // ignore: unused_field
  Timer? _timer;
  
  final _chineseTextStyle = const TextStyle(
    fontFamily: "HK",
    fontSize: 18,
    fontWeight: FontWeight.bold);
  final _insertChineseTextStyle = const TextStyle(
    fontFamily: "HK",
    fontSize: 15,
    fontWeight: FontWeight.bold);

  final TextEditingController _keywordController = TextEditingController(); 

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

  void _toggleCardVisibility() {
    setState(() {
      _isCardVisible = !_isCardVisible;
    });
  }

  bool checkVaildity(){
      bool res = true;
      // 关键字不为空
      if(_keywordController.text.isEmpty){
        res = false;
        errorDialog(context, "关键字为空");
      }

      return res;
    }

  Future<dynamic> errorDialog(BuildContext context, String text) {
      return showDialog(
          context: context,
          builder:(BuildContext context){
            return  AlertDialog(
              title: const Text("构建错误"),
              content: Text(text),
            );
          }
      );
  }
  
  void startPolling() {
    const interval = Duration(seconds: 10);

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

            if(appState.monitorKeywordDict.isNotEmpty){
              var keywordsList = appState.monitorKeywordDict.values.toList();
              var res = await requestCorrelation(keywords_list: keywordsList, msg: msgList[i]["content"]);
              var indexList = appState.monitorKeywordDict.keys.toList();
              print(res);
              for(int j = 0; j < keywordsList.length; ++j){
                if(res[j] && appState.monitorStatusDict[indexList[j]] == false){
                  appState.changeStatus(indexList[j], msgList[i]);
                }
              }
            }
          }
        }
      }
      return response.body;
    }
    else{
      return "";
    }
  }

  Future<List> requestCorrelation({List? keywords_list, String? msg}) async {
    final keywords = keywords_list!.join(",");
    Map<String, dynamic> queryParameters = {
        'keywords': keywords,
        'msg': msg
    };
    var url = Uri.http("localhost:6155", "/monitor_keyword", queryParameters);
    var response = await http.get(url);
    if(response.statusCode == 200){
      var res = jsonDecode(response.body)["res"];
      return res;
    }
    else{
      return List.filled(keywords_list.length, false);
    } 
  }
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    
    void addCard(){
      appState.addMonitorCard(
        MonitorCard(
          index: appState.totalMonitorCards,
          keyword: _keywordController.text),
        _keywordController.text);
    }
    return Stack(
      
      children: [
        Stack(
          children: [
            Center(
              child:AnimatedOpacity(
                opacity: appState.monitorCardsDict.isEmpty ? 1.0: 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  "No Monitor",
                  style: TextStyle(
                    fontSize: 40,
                    color: Color.fromARGB(255, 187, 179, 192)
                  ),),
              )
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Consumer<AppState>(
                  builder: (BuildContext context, AppState value, Widget? child) { 
                    return MasonryGridView.count(
                    crossAxisCount: max(constraints.maxWidth - 400, 0) ~/ 600 + 1,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemCount: appState.monitorCardsDict.length,
                    itemBuilder: (context, index) {
                      return appState.monitorCardsDict.values.toList()[index];
                      },
                    );
                   },
                );
              }
                
            )
          ],
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          right: _isCardVisible ? 0 : -250, // 调整隐藏位置的偏移量
          child: AnimatedOpacity(
            opacity: _isCardVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.all(Radius.circular(5)), 
                      ),
                
                      child: Center(
                        child: Text(
                          'New Monitor',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                
                    ),
                    const SizedBox(height: 20,),
                    // 关键字
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "关键字",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              controller: _keywordController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8)
                              ),
                              style: _insertChineseTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          child: FilledButton(
                            onPressed: addCard,
                            child: const Text('Submit'),
                          ),
                        ),
                        const SizedBox(width: 15,),
                        Container(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: _toggleCardVisibility,
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 50,
          bottom: 50,
          child: _isCardVisible
              ? Container()
              : FilledButton(
                  onPressed: _toggleCardVisibility,
                  child: const Text('+ New Monitor'),
                ),
        ),
      ],
    );
  }
}

class MonitorCard extends StatefulWidget{
  final int index;
  final String keyword;
  const MonitorCard({super.key, required this.index, required this.keyword});

  @override

  // ignore: no_logic_in_create_state
  State<MonitorCard> createState() => _MonitorCardState(index, keyword);
}

class _MonitorCardState extends State<MonitorCard> {

  final int index;
  final String keyword;
  _MonitorCardState(this.index, this.keyword);

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
    print("keyword: $keyword index: $index");
    var appState = context.watch<AppState>();
    var status = appState.monitorStatusDict[index];
    var color = status == false ? const Color.fromARGB(255, 158, 59, 59) : const Color.fromARGB(255, 58, 109, 60);
    return Dismissible(
      key: ValueKey(index),
      onDismissed: (direction){
        print("Removing keyword: $keyword index: $index");
        appState.removeMonitorCard(index);
      },
      child: CustomPopup(
        content: status == false ? const Text('未检测到'): formatText(status),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3.0),
                borderRadius:  BorderRadius.circular(10), 
                 ),
              child: Column(
                children: [
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        keyword,
                        style: const TextStyle(
                          fontFamily: "HK",
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),),
                    ],),
                  SizedBox(height: 10,),
                ],
              )
            ),
          ),
        ),
      ));
  }
}