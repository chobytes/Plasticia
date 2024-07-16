import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:plasticia_gui/appstate.dart';
import 'package:plasticia_gui/message_card_container.dart';
import 'package:provider/provider.dart';

class FocusPage extends StatefulWidget{
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => FocusPageState();
}

class FocusPageState extends State<FocusPage> {

  bool _isCardVisible = false;
  bool _isQQSelected = true;
  bool _isEmailSelected = false;
  // ignore: unused_field
  bool _isLoading = false;
  var _startTime = DateTime(1999);
  var _endTime = DateTime.now();
  var _method = "basic";

  final _chineseTextStyle = const TextStyle(
    fontFamily: "HK",
    fontSize: 18,
    fontWeight: FontWeight.bold);
  final _insertChineseTextStyle = const TextStyle(
    fontFamily: "HK",
    fontSize: 15,
    fontWeight: FontWeight.bold);
  final _underlinedInsertTextStyle = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline);
  
  
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _groupIDController = TextEditingController();

  void _toggleCardVisibility() {
    setState(() {
      _isCardVisible = !_isCardVisible;
    });
  }

  void _toggleQQ(bool? value) {
    setState(() {
      _isQQSelected = value!;
    });
  }

  void _toggleEmail(bool? value) {
    setState(() {
      _isEmailSelected = value!;
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _amountController.dispose();
    _userIDController.dispose();
    _groupIDController.dispose();
    super.dispose();
  }

  void _showDatePicker(datetime, isEnd) async {
    var date = await showDatePicker(
      context: context,
      initialDate: datetime,
      firstDate: DateTime(1999),
      lastDate: DateTime.now()
    );
    if(date == null) return;

    var time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if(time == null) return;
    
    date = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      0,
      0
    );

    setState(() {
      if(isEnd){
        _endTime = date!;
      } else {
        _startTime = date!;
      }
    });
    print(date);
  }
  
  String _datetimeToString(DateTime datetime) {
    final year = datetime.year.toString().padLeft(4, '0');
    final month = datetime.month.toString().padLeft(2, '0');
    final day = datetime.day.toString().padLeft(2, '0');
    final hour = datetime.hour.toString().padLeft(2, '0');
    final minute = datetime.minute.toString().padLeft(2, '0');
    return "$year-$month-$day $hour:$minute";
  }

  String _datetimeToStringWeb(DateTime datetime) {
    final year = datetime.year.toString().padLeft(4, '0');
    final month = datetime.month.toString().padLeft(2, '0');
    final day = datetime.day.toString().padLeft(2, '0');
    final hour = datetime.hour.toString().padLeft(2, '0');
    final minute = datetime.minute.toString().padLeft(2, '0');
    return "$year-$month-$day-$hour-$minute-00";
  }


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    const keyTextStyle = TextStyle(
      fontFamily: "HK",
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(255, 217, 217, 217));
    const valueTextStyle = TextStyle(
      fontFamily: "HK",
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(255, 255, 255, 255));
    const timeTextStyle = TextStyle(
      fontFamily: "HK",
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(255, 232, 232, 232));
    

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

    bool checkVaildity(){
      bool res = true;
      final numericRegex = RegExp(r'^\d+$');
      // 至少选择一个
      if(!_isQQSelected && !_isEmailSelected){
        res = false;
        errorDialog(context, "未选择Focus对象");
      }
      
      // 关键字不为空
      if(_keywordController.text.isEmpty && _method != "scan"){
        res = false;
        errorDialog(context, "关键字为空");
      }

      // 数量为0~99的整数
      if(!numericRegex.hasMatch(_amountController.text) || int.parse(_amountController.text) >= 10){
        res = false;
        errorDialog(context, "数量应小于10");
      }
      
      //发信人ID为整数
      if(_userIDController.text.isNotEmpty){
        if(int.tryParse(_userIDController.text) == null){
          res = false;
          errorDialog(context, "发信人ID格式错误");
        }  
      }
      
      //群聊ID为整数
      if(_groupIDController.text.isNotEmpty){
        if(int.tryParse(_groupIDController.text) == null){
          res = false;
          errorDialog(context, "群聊ID格式错误");
        }
      }
      
      

      return res;
    }
    
    Future<String> requestFocus({String? keyword, String? k, String? method, DateTime? startTime, DateTime? endTime}) async {
      
      Map<String, dynamic> queryParameters = {
          'keyword': keyword,
          'k': k,
          'method': method,
          'start_date': _datetimeToStringWeb(startTime!),
          'end_date': _datetimeToStringWeb(endTime!)
      };
      if(_userIDController.text.isNotEmpty){
        queryParameters['user_id'] = _userIDController.text;
      }
      if(_groupIDController.text.isNotEmpty){
        queryParameters['group_id'] = _groupIDController.text;
      }

      
      var url = Uri.http("localhost:6155", "/similar_msg", queryParameters);
      var response = await http.get(url);
      if(response.statusCode == 200){
        return response.body;
      }
      else{
        return "";
      }
    }

    Widget buildMessageCard(data){
      var senderInfoChildren = <Widget>[];
      if(data["privacy"] == "group"){
        senderInfoChildren.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 2,
              child: Text("群聊ID:", style: keyTextStyle,)
              ),
            Expanded(
              flex: 3,
              child: CustomPopup(
              content: Text.rich(
                TextSpan(
                  text: '添加至筛选',
                  style: _insertChineseTextStyle,
                  recognizer: TapGestureRecognizer()
                  ..onTap = (){
                    _groupIDController.text = data["group_id"].toString();
                    Navigator.of(context).pop();
                    }
                  )
                ),
                child: Text(data["group_id"].toString(), style: valueTextStyle),
              ),
              )
            ]
          )
        );
      }

      List<Widget> getContextMessage(data){
        var contextMessage = <Widget>[];
        var formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
        final time = formatter.parse(data["time"]);
        _isLoading = true;
        var successorResponseBody = requestFocus(
          keyword: "",
          k: "3",
          method: "scan",
          startTime: time,
          endTime: DateTime.now());
        var ancestorResponseBody = requestFocus(
          keyword: "",
          k: "3",
          method: "scan",
          startTime: DateTime(1999),
          endTime: time);
        Future.wait([successorResponseBody, ancestorResponseBody]).then((values) {
          // TODO
          setState(() {
            _isLoading = false; // 标记为加载完成
          });
        });
        
          
        return contextMessage;
      }

      senderInfoChildren.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
            child: Text("发信人昵称:", style: keyTextStyle,)
            ),
          Expanded(
            flex: 3,
            child: Text(data["sender"]["nickname"], style: valueTextStyle,)
            )
          ]
        )
      );
      senderInfoChildren.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
            child: Text("发信人ID:", style: keyTextStyle,)
            ),
          Expanded(
            flex: 3,
            child: CustomPopup(
              content: Text.rich(
                TextSpan(
                  text: '添加至筛选',
                  style: _insertChineseTextStyle,
                  recognizer: TapGestureRecognizer()
                  ..onTap = (){
                    _userIDController.text = data["sender"]["user_id"].toString();
                    Navigator.of(context).pop();
                    }
                  )
                ),
                child: Text(data["sender"]["user_id"].toString(), style: valueTextStyle),
              ),
            )
          ]
        )
      );
      
      senderInfoChildren.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: Text("发信时间:", style: keyTextStyle,)
            ),
          Expanded(
            flex: 3,
            child: CustomPopup(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '添加至起始时间',
                      style: _insertChineseTextStyle,
                      recognizer: TapGestureRecognizer()
                      ..onTap = (){
                          var formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
                          setState(() {
                            _startTime = formatter.parse(data["time"].toString());
                          });
                          Navigator.of(context).pop();
                        }
                    )
                  ),
                  Text(" | ", style: _insertChineseTextStyle),
                  Text.rich(
                    TextSpan(
                      text: '添加至结束时间',
                      style: _insertChineseTextStyle,
                      recognizer: TapGestureRecognizer()
                      ..onTap = (){
                          var formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
                          setState(() {
                            _endTime = formatter.parse(data["time"].toString());
                          });
                          Navigator.of(context).pop();
                        }
                    )
                  ),
                ],
              ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(data["time"].toString(), style: timeTextStyle),
                ),
              ),
            )
          ]
        )
      );
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: InkWell(
          onTap: (){
            print("Tapped");
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x00F7F2FA), 
              border: Border.all(color: Color.fromARGB(255, 136, 109, 155), width: 2.0), 
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              
              children: [
              Container(
                  width: 250,
                  child: Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)), 
                    ),
                    color: Color.fromARGB(255, 136, 109, 155),
                    margin: EdgeInsets.all(0),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: senderInfoChildren,
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  flex: 2,
                  child: Text(
                    "「  ${data["content"]}  」",
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: "HK",
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6750A4)),
                    ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void addCard(){
      if(checkVaildity()){
          var responseBody = requestFocus(
            keyword: _keywordController.text,
            k: _amountController.text,
            method: _method,
            startTime: _startTime,
            endTime: _endTime);
          var cardTextWidget = FutureBuilder<String>(
            future: responseBody,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = jsonDecode(snapshot.data!);
                var children = <Widget>[];
                for(var i = 0; i < data.length; ++i){
                  children.add(buildMessageCard(data[i]));
                }
                return Column(children: children,);

              } else if (snapshot.hasError) {
                return Column(
                  children: [
                    const SizedBox(height: 30,),
                    Text('${snapshot.error}'),
                    const SizedBox(height: 30,),
                  ],
                );
              }

              // 加载动画
              return const Column(
                children: [
                  SizedBox(height: 30,),
                  CircularProgressIndicator(),
                  SizedBox(height: 30,),
                ],
              );
            },
          );
          
        appState.addFocusCard(MessageCardContainer(
            key: PageStorageKey(appState.totalFocusCards),
            index: appState.totalFocusCards,
            content: cardTextWidget,
            keyword: _keywordController.text.isNotEmpty ? _keywordController.text : "")
          );
          
          // _toggleCardVisibility();
        ;
      }
    }
    
    return Stack(
      
      children: [
        Stack(
          children: [
            Center(
              child:AnimatedOpacity(
                opacity: appState.focusCardsDict.isEmpty ? 1.0: 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  "No Focus",
                  style: TextStyle(
                    fontSize: 40,
                    color: Color.fromARGB(255, 187, 179, 192)
                  ),),
              )
            ),
            /*
            ListView.builder(
              itemCount: appState.focusCardsList.length,
              itemBuilder: (context, index) {
                return appState.focusCardsDict.values.toList()[index];
              },
            ),
            */
            LayoutBuilder(
              builder: (context, constraints) {
                return Consumer<AppState>(
                  builder: (BuildContext context, AppState value, Widget? child) { 
                    return MasonryGridView.count(
                    crossAxisCount: max(constraints.maxWidth - 400, 0) ~/ 600 + 1,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    itemCount: appState.focusCardsDict.length,
                    itemBuilder: (context, index) {
                      print("BUILDER $index");
                      return appState.focusCardsDict.values.toList()[index];
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
                          'New Focus',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
              
                    
                    Text(
                      "信息流对象",
                      style: _chineseTextStyle,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 20,
                          width: 20,
                          child: Image.asset("assets/icon/qq.png")),
                        Checkbox(value: _isQQSelected, onChanged: null),
                        const SizedBox(width: 10,),
                        Container(
                          height: 20,
                          width: 20,
                          child: Image.asset("assets/icon/email.png")),
                        Checkbox(value: _isEmailSelected , onChanged: null),
                      ],
                    ),
                    const SizedBox(height: 20,),
                    Text(
                      "方式",
                      style: _chineseTextStyle),
                    // Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Elastic"),
                        Radio(
                          value: "basic",
                          groupValue: _method,
                          onChanged: (value){
                            setState(() {
                              _method = value!;
                            });
                          }),
                        const SizedBox(width: 10,),
                        const Text("Kimi"),
                        Radio(
                          value: "llm",
                          groupValue: _method,
                          onChanged: (value){
                            setState(() {
                              _method = value!;
                            });
                          }),
                        const SizedBox(width: 10,),
                        const Text("Scan"),
                        Radio(
                          value: "scan",
                          groupValue: _method,
                          onChanged: (value){
                            setState(() {
                              _method = value!;
                            });
                          }),
                        
                      ],
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
                              enabled: (_method != "scan"),
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

                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "数量",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                                hintText: "<10",
                              ),
                              style: _insertChineseTextStyle,
                              keyboardType: TextInputType.number,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),  
                    
                    // user_id
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "发信人ID",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              controller: _userIDController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                              ),
                              style: _insertChineseTextStyle,
                              keyboardType: TextInputType.number,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),

                    // group_id
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "群聊ID",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              controller: _groupIDController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                              ),
                              style: _insertChineseTextStyle,
                              keyboardType: TextInputType.number,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),

                    // 起始时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "起始时间",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: Center(
                              child: Text.rich(
                                TextSpan(
                                  text: _datetimeToString(_startTime),
                                  style: _underlinedInsertTextStyle,
                                  recognizer: TapGestureRecognizer()
                                  ..onTap = (){
                                    _showDatePicker(_startTime, false);
                                  }
                                )
                              ),
                            )
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),

                    // 结束时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "结束时间",
                            style: _chineseTextStyle,
                            ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 35,
                            child: Center(
                              child: Text.rich(
                                TextSpan(
                                  text: _datetimeToString(_endTime),
                                  style: _underlinedInsertTextStyle,
                                  recognizer: TapGestureRecognizer()
                                  ..onTap = (){
                                    _showDatePicker(_endTime, true);
                                  }
                                )
                              ),
                            )
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
                  child: const Text('+ New Focus'),
                ),
        ),
      ],
    );
  }
}