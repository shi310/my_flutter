import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:my_flutter_basic/common/common.dart';
import 'package:my_flutter_basic/public/public.dart';

Future<void> getOptions({
  required List<String> urls,
  Future<dynamic> Function()? onSuccess,
  Future<dynamic> Function()? onError,
}) async {
  if (GlobalController.to.wssUrlList.isNotEmpty && GlobalController.to.baseUrlList.isNotEmpty) {
    MyLogger.w('配置已获取请勿重复操作...');
    await onSuccess?.call();
    return;
  }

  final client = HttpClient();
  final completer = Completer<String>();
  final tasks = <Future>[];

  for (var url in urls) {
    tasks.add(Future(() async {
      try {
        final uri = Uri.parse(url);
        final request = await client.getUrl(uri).timeout(MyConfig.time.out);
        final response = await request.close();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseData = await response.transform(utf8.decoder).join();
          if (!completer.isCompleted) {
            completer.complete(responseData);
          }
        } else {
          MyLogger.w('获取配置发生了错误 --> HTTP 状态码: ${response.statusCode}');
        }
      } catch (e) {
        MyLogger.w('获取配置发生了错误 --> $e');
      }
    }));
  }

  String data = '';

  try {
    data = await completer.future.timeout(MyConfig.time.out);
  } catch (e) {
    MyLogger.w('获取配置超时或发生其他错误 --> $e');
  }

  client.close();

  if (data.isNotEmpty) {
    data = data.aesDecrypt(MyConfig.key.aesKey);
    final json = jsonDecode(data);

    MyLogger.l();

    final List<dynamic> baseUrls = json['api'];
    GlobalController.to.baseUrlList.clear();
    for (var element in baseUrls) {
      GlobalController.to.baseUrlList.add(element.toString());
    }

    MyLogger.w('获取到 API 地址 --> ${GlobalController.to.baseUrlList}');

    final List<dynamic> wss = json['ws'];
    GlobalController.to.wssUrlList.clear();
    for (var element in wss) {
      GlobalController.to.wssUrlList.add(element.toString());
    }

    MyLogger.w('获取到 WSS 地址 --> ${GlobalController.to.wssUrlList}');
    MyLogger.l();

    await onSuccess?.call();
  } else {
    // showMyDialog(
    //   title: '连接失败',
    //   content: '请点击重新按钮重新尝试',
    //   onCancel: () {},
    //   onConfirm: () async {
    //     showMyLoading();
    //     await onError?.call();
    //     await getOptions(urls: urls, onError: onError, onSuccess: onSuccess);
    //     hideMyLoading();
    //   },
    // );
  }
}