import 'package:flutter/material.dart';
// cspell: disable-next
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/data/swap_map.dart';

class WhoIsNextData {
  List<String> players;
  int rounds;
  WhoIsNext whoIsNext;
  Function saveFunction;

  WhoIsNextData(this.players, this.rounds, this.whoIsNext, this.saveFunction);
}

class WhoIsNextWidget extends StatefulWidget {
  final WhoIsNextData data;

  const WhoIsNextWidget(this.data, {super.key});

  @override
  State<WhoIsNextWidget> createState() => _WhoIsNextWidget();
}

class _WhoIsNextWidget extends State<WhoIsNextWidget> {
  int players = 4;
  late SwapMap swapMap;

  @override
  void initState() {
    players = widget.data.players.length;
    swapMap = SwapMap(widget.data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final landscape = screenSize.width > screenSize.height;
    var cardWidth = screenSize.width * 0.3;
    var crossAxisCount = 2;
    var mainAxisCount = (players / crossAxisCount).ceil();
    if (landscape) {
      cardWidth = screenSize.height * 0.2;
      (crossAxisCount, mainAxisCount) = (mainAxisCount, crossAxisCount);
    }
    final map = swapMap.get(landscape: landscape);
    final List<int> keyList = map.keys.toList();

    List<DraggableGridItem> children = [];
    for (var i in keyList) {
      final key = Key("$i");
      children.add(
        DraggableGridItem(
          isDraggable: true,
          child: Card(
            key: key,
            color: Colors.black12,
            child: InkWell(
              onLongPress: () => setState(() {
                swapMap.select(PlayerId(int.tryParse(key.toString()[3])!));
                widget.data.saveFunction();
              }),
              child: SizedBox(
                height: cardWidth,
                width: cardWidth,
                child: Center(child: map[i]),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: cardWidth * mainAxisCount,
      width: cardWidth * crossAxisCount,
      child: DraggableGridViewBuilder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        children: children,
        isOnlyLongPress: false,
        dragCompletion: (list, int beforeIndex, int afterIndex) {
          final i1 = keyList[beforeIndex];
          final i2 = keyList[afterIndex];
          swapMap.swap(PlayerId(i1), PlayerId(i2));
          widget.data.saveFunction();
          setState(() {});
        },
        dragPlaceHolder: (List<DraggableGridItem> list, int index) {
          return PlaceHolderWidget(
            child: Card(
              color: Colors.black12,
              child: SizedBox(height: cardWidth, width: cardWidth),
            ),
          );
        },
      ),
    );
  }
}
