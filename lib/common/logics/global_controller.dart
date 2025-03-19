import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_device_info/models/my_device_info_model.dart';
import 'package:my_flutter_basic/public/public.dart';

class GlobalController with WidgetsBindingObserver {
  static final GlobalController _instance = GlobalController._internal();
  factory GlobalController() => _instance;
  GlobalController._internal();

  static GlobalController get to => _instance;

  MyDio? myDio;

  // wss 通信
  MyWss? myWss;

  // 是否允许连接 wss
  bool isWssCanConnection = true;

  // baseUrls 数组
  List<String> baseUrlList = [];

  // wssUrls 数组
  List<String> wssUrlList = [];

  // 用户 token
  String userToken = '';

  // 热更新定时器
  Timer? timerHotUpdate;

  // 应用信息
  MyDeviceInfoModel? deviceInfo;

  // 切换到后台断开wss的时长
  Timer? _disconnectTimer;

  // 是否使用过APP
  String isUsedApp = '1';

  void onInit() {
    WidgetsBinding.instance.addObserver(this);
  }

  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        MyLogger.w('app 切换到了前台');
        _disconnectTimer?.cancel();
        _disconnectTimer = null;
        if (isWssCanConnection) {
          myWss?.connect();
        }
        break;
      case AppLifecycleState.paused:
        MyLogger.w('app 切换到了后台');
        _disconnectTimer = Timer(Duration(minutes: 1), () {
          MyLogger.w('1 分钟未回到前台，断开 WebSocket');
          myWss?.close();
        });
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}