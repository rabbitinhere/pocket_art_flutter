import 'package:flutter/material.dart';
import '../model/artwork.dart';
import '../http/network_service.dart';
import 'package:dio/dio.dart';
import 'dart:math';

class TabMainProvider extends ChangeNotifier {
  List<Artwork> artworks = [];
  bool isInitLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  
  List<int> _allObjectIDs = [];
  int _currentPage = 0;
  String _searchKeyword = "";

  void setSearchKeyword(String value) {
    _searchKeyword = value;
  }

  Future<void> loadArtworks() async {
    isInitLoading = true;
    notifyListeners();

    try {
      artworks.clear();
      final String url = _searchKeyword.isEmpty 
          ? '/search?q=&isHighlight=true' 
          : '/search?q=${Uri.encodeComponent(_searchKeyword)}&isHighlight=true';

      final response = await NetworkService().request(url);
      final respData = ArtworkListResp.fromJson(response.data);
      
      _allObjectIDs = respData.objectIDs;
      _currentPage = 0;
      hasMoreData = _allObjectIDs.isNotEmpty;

      if (hasMoreData) {
        await loadNextPage();
      }
    } catch (e) {
      print('Load artworks failed: $e');
    } finally {
      isInitLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMoreData || isLoadingMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      int start = _currentPage * 5;
      int end = start + 5;

      if (start >= _allObjectIDs.length) {
        hasMoreData = false;
        return;
      }

      end = min(end, _allObjectIDs.length);
      
      // 并发请求详情
      final tasks = <Future<Response>>[];
      for (int i = start; i < end; i++) {
        tasks.add(NetworkService().request('/objects/${_allObjectIDs[i]}'));
      }

      final results = await Future.wait(tasks);
      
      for (var res in results) {
        try {
          artworks.add(Artwork.fromJson(res.data));
        } catch(e) {
          print('Parse artwork failed: $e');
        }
      }

      _currentPage++;
      if (_currentPage * 5 >= _allObjectIDs.length) {
        hasMoreData = false;
      }

    } catch (e) {
      print('Load next page failed: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}