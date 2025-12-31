import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:dio/dio.dart';

class NetworkService {
  // 单例模式
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  late Dio _dio;

  // 队列控制
  final Queue<Function> _requestQueue = Queue();
  bool _isProcessing = false;
  int _lastRequestTime = 0;
  final int _minDelay = 20;
  final int _maxDelay = 50;

  NetworkService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://collectionapi.metmuseum.org/public/collection/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // 统一请求入口，加入队列
  Future<Response> request(String path, {Map<String, dynamic>? queryParameters}) {
    final completer = Completer<Response>();

    _addToQueue(() async {
      try {
        print('[HTTP START] URL: $path');
        final response = await _dio.get(path, queryParameters: queryParameters);
        completer.complete(response);
      } catch (e) {
        print('[HTTP ERROR] URL: $path, Error: $e');
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  void _addToQueue(Function requestFn) {
    _requestQueue.add(requestFn);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _requestQueue.isEmpty) return;

    _isProcessing = true;

    while (_requestQueue.isNotEmpty) {
      // 模拟随机延迟
      final randomInterval = _minDelay + Random().nextInt(_maxDelay - _minDelay + 1);
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLast = now - _lastRequestTime;
      final waitTime = max(0, randomInterval - timeSinceLast);

      if (waitTime > 0) {
        await Future.delayed(Duration(milliseconds: waitTime));
      }

      final task = _requestQueue.removeFirst();
      _lastRequestTime = DateTime.now().millisecondsSinceEpoch;
      
      // 等待当前任务执行完毕（包括网络IO时间），或者你不希望阻塞队列发送，可以去掉await
      // 这里为了严格控制频率，我们await它
      await task(); 
    }

    _isProcessing = false;
  }
}