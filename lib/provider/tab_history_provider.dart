import 'dart:math';
import 'package:flutter/material.dart';
import '../model/artwork.dart';
import '../http/network_service.dart';

class YearTimelineItem {
  final int year;
  final List<Artwork> artworkList;
  YearTimelineItem(this.year, this.artworkList);
}

class TabHistoryProvider extends ChangeNotifier {
  List<YearTimelineItem> yearList = [];
  bool isInitLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  
  int _currentPage = 0;
  final int _startYear = 1800;
  final int _endYear = -2000;
  final int _step = 100;
  final int _perPage = 5;
  
  int get _totalPeriods => ((_startYear - _endYear) / _step).floor() + 1;

  Future<void> initLoadYears() async {
    isInitLoading = true;
    notifyListeners();
    try {
      yearList.clear();
      _currentPage = 0;
      hasMoreData = true;
      await loadNextPage();
    } catch (e) {
      print('History init failed: $e');
      hasMoreData = false;
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
      int start = _currentPage * _perPage;
      int end = start + _perPage;
      
      final List<Future<YearTimelineItem>> tasks = [];

      for (int i = start; i < min(end, _totalPeriods); i++) {
        final dateEnd = _startYear - i * _step;
        final dateBegin = dateEnd - _step;
        
        tasks.add(_fetchArtworksForYearRange(dateBegin, dateEnd).then((artworks) {
          return YearTimelineItem(dateEnd, artworks);
        }));
      }

      final newItems = await Future.wait(tasks);
      yearList.addAll(newItems);
      
      _currentPage++;
      if (_currentPage * _perPage >= _totalPeriods) {
        hasMoreData = false;
      }

    } catch (e) {
      print('Load history page failed: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<Artwork>> _fetchArtworksForYearRange(int begin, int end) async {
    try {
      final response = await NetworkService().request(
        '/search?q=&dateBegin=$begin&dateEnd=$end'
      );
      final data = ArtworkListResp.fromJson(response.data);
      
      if (data.objectIDs.isEmpty) return [];

      // 取前4个
      final ids = data.objectIDs.take(4).toList();
      final detailTasks = ids.map((id) => NetworkService().request('/objects/$id'));
      
      final results = await Future.wait(detailTasks);
      return results.map((e) => Artwork.fromJson(e.data)).toList();
    } catch (e) {
      print('Fetch range $begin-$end failed: $e');
      return [];
    }
  }
}