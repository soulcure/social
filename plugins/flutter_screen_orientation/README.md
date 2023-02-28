# flutter_screen_orientation

实时监测Android/IOS屏幕方向的插件

- 只有当竖屏锁定关闭的情况下，才进行监听，这是最常用的


## Getting Started

pubspec.yaml中引入依赖：

```
dependencies:
  flutter_screen_orientation: <最新版本>
```


最新版本查看地址：

https://pub.dev/packages/flutter_screen_orientation/install


初始化插件：

```
 FlutterScreenOrientation.instance().init();
```

可以写在main.dart里面

开始监听：

```
FlutterScreenOrientation.instance().listenerOrientation((e) {
      if (e == FlutterScreenOrientation.portraitUp) {
        this.setState(() {
          current = "摄像头在上";
        });
      } else if (e == FlutterScreenOrientation.portraitDown) {
        this.setState(() {
          current = "摄像头在下";
        });
      } else if (e == FlutterScreenOrientation.landscapeLeft) {
        this.setState(() {
          current = "摄像头在左";
        });
      } else if (e == FlutterScreenOrientation.landscapeRight) {
        this.setState(() {
          current = "摄像头在右";
        });
      }
 });
```

每次调用listenerOrientation都会将之前的覆盖。
退出当前页面会自动销毁回调。
只有当竖屏锁定关闭的情况下，才进行监听，这是最常用的



