import 'package:flutter/material.dart';
// cspell: disable-next
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';
import 'package:jasstafel/common/data/swap_map.dart';

class WhoIsNextWidget extends StatefulWidget {
  final List<String> players;
  final int rounds;

  const WhoIsNextWidget(this.players, this.rounds, {super.key});

  @override
  State<WhoIsNextWidget> createState() => _WhoIsNextWidget();
}

class _WhoIsNextWidget extends State<WhoIsNextWidget> {
  int players = 4;
  late SwapMap swapMap;

  void restoreData() async {
    await swapMap.restore(widget.rounds);
    setState(() {});
  }

  @override
  void initState() {
    players = widget.players.length;
    swapMap = SwapMap(widget.players);
    restoreData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var cardWidth = MediaQuery.of(context).size.width * 0.35;

    List<DraggableGridItem> children = [];
    swapMap.get().forEach((key, value) {
      children.add(DraggableGridItem(
          isDraggable: true,
          child: Card(
              key: key,
              color: Colors.black12,
              child: InkWell(
                  onLongPress: () => setState(() => swapMap.select(key)),
                  child: SizedBox(
                      height: cardWidth,
                      width: cardWidth,
                      child: Center(child: value))))));
    });

    return SizedBox(
        height: cardWidth * (players / 2).ceil(),
        width: cardWidth * 2,
        child: DraggableGridViewBuilder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            children: children,
            isOnlyLongPress: false,
            dragCompletion: (List<DraggableGridItem> list, int beforeIndex,
                int afterIndex) {
              List<int> newList = list
                  .map((element) => int.parse(element.child.key.toString()[3]))
                  .toList();

              swapMap.set(newList);
              setState(() {});
            },
            dragPlaceHolder: (List<DraggableGridItem> list, int index) {
              return PlaceHolderWidget(
                  child: Card(
                      color: Colors.black12,
                      child: SizedBox(
                        height: cardWidth,
                        width: cardWidth,
                      )));
            }));
  }
}
