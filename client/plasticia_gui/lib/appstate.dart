import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool serviceEnabled = false;
  var focusCardsDict = <int, Widget>{};
  var monitorCardsDict = <int, Widget>{};
  var monitorKeywordDict = <int, String>{};
  var monitorStatusDict = <int, dynamic>{};
  var historyList = <Map<String, dynamic>>[];

  GlobalKey? historyListKey;

  int totalFocusCards = 0;
  int totalMonitorCards = 0;
  
  void toggleSerivice() {
    serviceEnabled = !serviceEnabled;
    notifyListeners();
  }

  void removeFocusCard(index){
    focusCardsDict.remove(index);
    notifyListeners();
  }

  void addFocusCard(card){
    focusCardsDict[totalFocusCards] = card;
    totalFocusCards += 1;
    notifyListeners();
  }

  void removeMonitorCard(index){
    monitorCardsDict.remove(index);
    monitorKeywordDict.remove(index);
    monitorStatusDict.remove(index);
    notifyListeners();
  }

  void addMonitorCard(card, keyword){
    monitorCardsDict[totalMonitorCards] = card;
    monitorKeywordDict[totalMonitorCards] = keyword;
    monitorStatusDict[totalMonitorCards] = false;
    totalMonitorCards += 1;
    notifyListeners();
  }

  void addHistory(msg){
    historyList.add(msg);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    notifyListeners();
  }

  void changeStatus(index, msg){
    monitorStatusDict[index] = msg;
    notifyListeners();
  }
}