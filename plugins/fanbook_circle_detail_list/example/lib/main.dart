import 'package:fanbook_circle_detail_list/fanbook_circle_detail_list.dart';
import 'package:fanbook_circle_detail_list/scrollable_positioned_list/item_positions_notifier.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PinNotifier pinNotifier = PinNotifier(false);

  @override
  void dispose() {
    pinNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FanbookCircleDetailList(
        pinNotifier: pinNotifier,
        emptyReplyWidget: const Text("empty"),
        detailWidget: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            """
          其实按标准库的分类，首先就可以略知一二它们的作用。
std[1]::ops[2]::Deref[3] ，看得出来，Deref 是被归类为 ops 模块。查看文档，你就会看到，这个模块下放的都是 可重载的操作符。这些操作符都有对应的 trait[4] 。比如Add trait 对应的就是 +，而 Deref trait 则对应 共享（不可变）借用 的解引用操作，比如 *v。相应的，也有 DerefMut trait，对应独占（可变）借用的解引用操作。因为 Rust 所有权语义是贯穿整个语言特性，所以 拥有（Owner）/不可变借用（&T）/可变借用（&mut T)的语义 都是配套出现的。
std[5]::convert[6]::AsRef[7] ，看得出来，AsRef 被归类到 convert 模块。查看文档，你就会发现，这个模块下放的都是拥有类型转换的 trait[8] 。比如熟悉的 From/Into 、TryFrom/TryInto ，而 AsRef/AsMut也是作为配对出现在这里，就说明，该trait 是和类型转化有关。再根据 Rust API Guidelines[9] 里的命名规范可以推理，以 as_ 开头的方法，代表从 borrowed -> borrowed ，即 reference -> reference的一种转换，并且是无开销的。并且这种转换不能失败。
std[10]::borrow[11]::Borrow[12] ，看得出来，Borrow 被归类到 borrow 模块中。而该模块的文档则非常简陋，只写了一句话：这是用于使用借来的数据。所以该 trait 多多少少和表达借用语义是相关的。提供了三个 trait[13] : Borrow[14] / BorrowMut[15]/ ToOwned[16] ，可以说是和所有权语义完全对应了。
std[17]::borrow[18]::Cow[19] ，看得出来，Cow 也被归类为 borrow 模块中。根据描述，Cow 是 一种 clone-on-write 的智能指针。被放到 borrow 模块，主要还是为了尽可能的使用 借用 而避免 拷贝，是一种优化。
分类我们清楚了，接下来逐个深入了解。
          """,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        replyItemBuilder: (BuildContext context, int index) {
          return Text("$index");
        },
        initialIndex: 0,
        replyItemCount: 100,
        pinItemHeight: 40,
        buildPinItem: (_) => Container(
            alignment: Alignment.center,
            color: Colors.amber,
            child: const Text("PIN",
                style: TextStyle(color: Colors.white, fontSize: 25))),
        onUnderscroll: () {},
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
