import 'package:flutter/material.dart';
import '../model/artwork.dart';
import '../http/network_service.dart';

class SwipeProvider extends ChangeNotifier {
  List<Artwork?> artworksCache = []; // 对应原代码的 artworks 数组
  List<int> _artworkIDs = [];
  
  int currentIndex = -1;
  Artwork? currentArtwork;
  Artwork? nextArtwork;
  Artwork? prevArtwork;

  bool isLoading = false;
  String errorMessage = '';
  
  bool get canSwipePrevious => currentIndex > 0;
  bool get canSwipeNext => _artworkIDs.isNotEmpty && currentIndex < _artworkIDs.length - 1;

  Future<void> initialize() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // 重置状态
      artworksCache = [];
      currentIndex = -1;
      currentArtwork = null;
      nextArtwork = null;
      prevArtwork = null;

      // 1. 获取 ID 列表
      final response = await NetworkService().request('/search?q=&isHighlight=true');
      final data = ArtworkListResp.fromJson(response.data);
      // 随机打乱并取前50个
      data.objectIDs.shuffle();
      _artworkIDs = data.objectIDs.take(50).toList();
      // 初始化缓存数组大小
      artworksCache = List.filled(_artworkIDs.length, null);

      // 2. 找到第一个有图的
      if (_artworkIDs.isNotEmpty) {
        for (int i = 0; i < _artworkIDs.length; i++) {
          final success = await _loadArtworkByIndex(i);
          if (success) break;
        }
      }

      _preloadNextArtwork();

    } catch (e) {
      errorMessage = 'Load failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _loadArtworkByIndex(int index) async {
    if (index < 0 || index >= _artworkIDs.length) return false;

    // 缓存命中且有图
    if (artworksCache[index] != null) {
      if (artworksCache[index]!.primaryImageSmall.isNotEmpty) {
        if (currentIndex == -1) currentIndex = index;
        _updatePointers();
        return true;
      } else {
        return false; // 已加载过但没图
      }
    }

    try {
      final id = _artworkIDs[index];
      final response = await NetworkService().request('/objects/$id');
      final artwork = Artwork.fromJson(response.data);
      
      artworksCache[index] = artwork;

      if (artwork.primaryImageSmall.isEmpty) return false;

      if (currentIndex == -1) currentIndex = index;
      _updatePointers();
      notifyListeners();
      return true;
    } catch (e) {
      print('Fetch detail failed for $index: $e');
      return false;
    }
  }

  void _updatePointers() {
    currentArtwork = (currentIndex >= 0 && currentIndex < artworksCache.length) ? artworksCache[currentIndex] : null;
    prevArtwork = (currentIndex - 1 >= 0) ? artworksCache[currentIndex - 1] : null;
    nextArtwork = (currentIndex + 1 < artworksCache.length) ? artworksCache[currentIndex + 1] : null;
  }

  void _preloadNextArtwork() {
    final nextIndex = currentIndex + 1;
    if (nextIndex < _artworkIDs.length && artworksCache[nextIndex] == null) {
      _loadArtworkByIndex(nextIndex);
    }
  }

  Future<void> confirmSwipeToNext() async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < _artworkIDs.length) {
      isLoading = true; // 局部 loading
      notifyListeners();
      
      // 寻找下一个有图的
      for (int i = nextIndex; i < _artworkIDs.length; i++) {
        final success = await _loadArtworkByIndex(i);
        if (success) {
          currentIndex = i;
          _updatePointers();
          break;
        }
      }
      isLoading = false;
      _preloadNextArtwork();
      notifyListeners();
    }
  }

  void confirmSwipeToPrevious() {
    final prevIndex = currentIndex - 1;
    for (int i = prevIndex; i >= 0; i--) {
      if (artworksCache[i] != null && artworksCache[i]!.primaryImageSmall.isNotEmpty) {
        currentIndex = i;
        _updatePointers();
        notifyListeners();
        return;
      }
    }
  }
}