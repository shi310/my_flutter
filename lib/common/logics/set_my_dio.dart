import 'package:my_flutter_basic/common/common.dart';
import 'package:my_device_info/my_device_info.dart';
import 'package:my_flutter_basic/public/public.dart';

Future<void> setMyDio({
  Future<dynamic> Function()? onSuccess,
  bool isShowMyDialog = true,
}) async {
  if (GlobalController.to.baseUrlList.isEmpty) {
    MyLogger.w('传入的链接组为空，无法配置Dio...');
    return;
  }
  await getBaseUrl(
    urls: GlobalController.to.baseUrlList,
    onSuccess: (baseUrl) async {
      await _setMyDio(baseUrl: baseUrl);
      await onSuccess?.call();
    },
    onError: () async {
      // if (isShowMyDialog) {
      //   showMyDialog(
      //     title: '与服务器连接失败',
      //     content: '请稍后在重试',
      //     confirmText: '重试',
      //     onConfirm: () async {
      //       showMyLoading();
      //       await setMyDio(onSuccess: onSuccess);
      //       hideMyLoading();
      //     },
      //     onCancel: () {},
      //   );
      // }
    }
  );
}

Future<void> _setMyDio({
  required String baseUrl,
}) async {
  final info = await MyDeviceInfo.getDeviceInfo();
  String device = '${info.brand}, ${info.id}, ${info.model}, ${info.systemVersion}';
  GlobalController.to.myDio = MyDio(
    baseOptions: (option) => option.copyWith(
      baseUrl: baseUrl,
      connectTimeout: MyConfig.time.out,
      receiveTimeout: MyConfig.time.out,
      sendTimeout: MyConfig.time.out,
    ),
    headers: {
      'x-token': GlobalController.to.userToken,
      'x-device': device,
      'x-timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    },
    onResponse: (response) async {
      if (response.data is Map<String, dynamic>) {
        final responseModel = ResponseModel.fromJson(response.data);
        if ([4].contains(responseModel.code)) {

        } else if ([2].contains(responseModel.code)) {

        }
      }
    },
    onError: (err, handle) async {
      return handle.reject(err);
    },
    isResponseSuccessful: (code) {
      return code == 0;
    },
  );
}

