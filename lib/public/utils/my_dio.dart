import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';

class MyDio {
  MyDio({
    this.baseOptions,
    this.headers,
    this.onResponse,
    this.onError,
    required this.isResponseSuccessful,
  }) {
    if (isInitialized) {
      log("⚠️ MyDio 已经初始化过...");
      return;
    }
    final options = baseOptions?.call(BaseOptions(
      responseType: ResponseType.json,
      contentType: 'application/json; charset=utf-8',
    ));
    dioOptions = options;
    _dio = Dio(options);
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (headers != null) {
          options.headers.addAll(headers!);
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        _logSuccess(response);
        await onResponse?.call(response);
        return handler.next(response);
      },
      onError: (err, handle) async {
        _logError(err);
        return onError?.call(err, handle);
      },
    ));
  }

  final BaseOptions Function(BaseOptions options)? baseOptions;
  final Map<String, dynamic>? headers;
  final Future<void> Function(Response<dynamic> response)? onResponse;
  final Future<void> Function(DioException error, ErrorInterceptorHandler handler)? onError;
  final bool Function(int code) isResponseSuccessful;

  BaseOptions? dioOptions;
  Map<String, dynamic>? dioHeaders;

  CancelToken cancelTokenPublic = CancelToken();
  Dio? _dio;

  bool get isInitialized => _dio != null;

  Dio get dio {
    if (!isInitialized) {
      throw StateError("❌ MyDio 未初始化，请先调用 MyDio.initialize()");
    }
    return _dio!;
  }

  void cancel() {
    cancelTokenPublic.cancel();
  }

  void getNewCancelToken() {
    if (cancelTokenPublic.isCancelled) {
      cancelTokenPublic = CancelToken();
    }
  }

  void _logError(DioException err) {
    String headers = const JsonEncoder.withIndent('  ').convert(err.requestOptions.headers);
    String data = const JsonEncoder.withIndent('  ').convert(err.requestOptions.data ?? err.requestOptions.queryParameters);

    log("❌" * 80);
    log("❌ 请求地址 => ${err.requestOptions.uri}");
    log("❌ 请求方式 => ${err.requestOptions.method}");
    log("❌ 请求头${headers == '{}' ? ' => $headers': ':$headers'}");
    log("❌ 请求参数${data == '{}' ? ' => $data': ':$data'}");
    log("❌ 错误信息 => ${err.message}");
    log("❌ ${err.error}");
    log("❌" * 80);
  }

  void _logSuccess(Response response) {
    String headers = const JsonEncoder.withIndent('  ').convert(response.requestOptions.headers);
    String parameters = const JsonEncoder.withIndent('  ').convert(response.requestOptions.data ?? response.requestOptions.queryParameters);
    String data = const JsonEncoder.withIndent('  ').convert(response.data);

    log("✅" * 80);
    log("✅ 请求地址 => ${response.requestOptions.uri}");
    log("✅ 请求方式 => ${response.requestOptions.method}");
    log("✅ 请求头${headers == '{}' ? ' => $headers': ':$headers'}");
    log("✅ 请求参数${parameters == '{}' ? ' => $parameters': ':$parameters'}");
    log("✅ 返回数据${data == '{}' ? ' => $data': ':$data'}");
    log("✅" * 80);
  }

  Future<void> get<T>(String path, {
    Future<dynamic> Function(int, String, T)? onSuccess,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
    Future<dynamic> Function(DioException)? onError,
    T Function(dynamic)? onModel,
  }) async {
    try {
      final response = await dio.get(path,
        queryParameters: data,
        cancelToken: cancelToken ?? cancelTokenPublic,
        onReceiveProgress: onReceiveProgress,
      );
      final responseModel = ResponseModel.fromJson(response.data);

      if (isResponseSuccessful(responseModel.code)) {
        final model = onModel != null ? onModel(responseModel.data) : responseModel.data as T;
        await onSuccess?.call(responseModel.code, responseModel.msg, model);
      } else {
        final err = DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: responseModel.msg,
          type: DioExceptionType.badResponse,
        );
        await onError?.call(err);
      }
    } on DioException catch (err) {
      await onError?.call(err);
    }
  }

  Future<void> post<T>(String path, {
    Future<dynamic> Function(int, String, T)? onSuccess,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    Future<dynamic> Function(DioException)? onError,
    T Function(dynamic)? onModel,
  }) async {
    try {
      final response = await dio.post(path,
        data: data,
        cancelToken: cancelToken ?? cancelTokenPublic,
      );
      final responseModel = ResponseModel.fromJson(response.data);

      if (isResponseSuccessful(responseModel.code)) {
        final model = onModel != null ? onModel(responseModel.data) : responseModel.data as T;
        await onSuccess?.call(responseModel.code, responseModel.msg, model);
      } else {
        final err = DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: responseModel.msg,
          type: DioExceptionType.badResponse,
        );
        await onError?.call(err);
      }
    } on DioException catch (err) {
      await onError?.call(err);
    }
  }

  Future<void> upload<T>(String path, {
    Future<dynamic> Function(int, String, T)? onSuccess,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    Future<dynamic> Function(DioException)? onError,
    T Function(dynamic)? onModel,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    try {
      final response = await dio.post(path,
        data: data == null ? null : FormData.fromMap(data),
        cancelToken: cancelToken ?? cancelTokenPublic,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
        ),
        onSendProgress: onSendProgress,
      ).timeout(const Duration(days: 1));
      final responseModel = ResponseModel.fromJson(response.data);

      if (isResponseSuccessful(responseModel.code)) {
        final model = onModel != null ? onModel(responseModel.data) : responseModel.data as T;
        await onSuccess?.call(responseModel.code, responseModel.msg, model);
      } else {
        final err = DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: responseModel.msg,
          type: DioExceptionType.badResponse,
        );
        await onError?.call(err);
      }
    } on DioException catch (err) {
      await onError?.call(err);
    }
  }
}

class ResponseModel {
  int code;
  dynamic data;
  String msg;

  ResponseModel({
    required this.code,
    required this.data,
    required this.msg,
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
    code: json["code"] ?? -1,
    data: json["data"] ?? {},
    msg: json["msg"] ?? '',
  );

  factory ResponseModel.empty() => ResponseModel(
    code: -1,
    data: {},
    msg: '',
  );

  ResponseModel copyWith({
    int? code,
    dynamic data,
    String? msg,
  }) => ResponseModel(
    code: code ?? this.code,
    data: data ?? this.data,
    msg: msg ?? this.msg,
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "data": data,
    "msg": msg,
  };
}