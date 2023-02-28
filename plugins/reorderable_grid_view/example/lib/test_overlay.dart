import 'package:flutter/material.dart';

class TestOverlay extends StatefulWidget {
  const TestOverlay({Key? key}) : super(key: key);

  @override
  _TestOverlayState createState() => _TestOverlayState();
}

class _TestOverlayState extends State<TestOverlay> {
  bool _hasInsert = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TestOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called");
  }

  double curPos = 0;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        TextButton(onPressed: () {
          print("insert overlay");
          var overlay = Overlay.of(context)!;
          curPos += 5;
          // 这么奇怪吗？？
          // passed by reference??
          double tmp = curPos;
          overlay.insert(OverlayEntry(builder: (context) {
            return Positioned(
              left: tmp,
              top: tmp,
              child: SizedBox(
                width: 50,
                height: 50,
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.green,
                ),
              ),
            );
          }));
          // double tmp = curPos + 10;
          // overlay.insert(OverlayEntry(builder: (context) {
          //   return Positioned(
          //     left: tmp,
          //     top: tmp,
          //     child: SizedBox(
          //       width: 50,
          //       height: 50,
          //       child: Text("Floating"),
          //     ),
          //   );
          // }));
        }, child: Text("add")),
        Container(
          width: 100,
          height: 100,
          color: Colors.red,
        ),
      ],
    );
  }
}
