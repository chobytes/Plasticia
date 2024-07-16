import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appstate.dart';

class MessageCardContainer extends StatefulWidget {

  final int index;
  final Widget content;
  final String keyword;
  const MessageCardContainer(
    {super.key,
    required this.index,
    required this.content,
    required this.keyword});
    
  @override
  // ignore: no_logic_in_create_state
  State<MessageCardContainer> createState() => _MessageCardContainerState(index, content, keyword);
}

class _MessageCardContainerState extends State<MessageCardContainer>{
  final int index;
  final Widget content;
  final String keyword;
  late final id;
  late Widget titleText;
  final titleTextStyle = const TextStyle(
    fontSize: 25,
    fontFamily: "Manrope"
  );
  _MessageCardContainerState(this.index, this.content, this.keyword);

  @override
  void initState() {
    super.initState();
    id = index;
    print("INIT index: $index id: ${ValueKey(id)}");
  }

  
  @override
  Widget build(BuildContext context) {
    print("BUILDING $index");
    var appState = context.watch<AppState>();
    var focusCardsDict = appState.focusCardsDict;
    if(keyword == ""){
      titleText = Text(
        "Scanning",
        style: titleTextStyle,);
    } else {
      titleText = Text(
        "Focusing on $keyword",
        style: titleTextStyle,);
    }
    var item = focusCardsDict[index];
    return Dismissible(
        key: ObjectKey(item),
        onDismissed: (direction) {
          print("REMOVE index: $index id: ${ValueKey(id)}");
          
          appState.removeFocusCard(index);
          
          //print(cards);          
        },
        child: Card(
          child: ExpansionTile(
            expandedCrossAxisAlignment: CrossAxisAlignment.end,
            expandedAlignment: Alignment.centerRight,
            childrenPadding: const EdgeInsets.all(10),
            initiallyExpanded: true,
            title: titleText,
            children: [Center(child: content,)]
          ),
        ),
      );
  }
}
