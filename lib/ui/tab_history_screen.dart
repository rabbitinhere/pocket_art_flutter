import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/tab_history_provider.dart';
import '../model/artwork.dart';

class TabHistoryScreen extends StatefulWidget {
  const TabHistoryScreen({super.key});

  @override
  State<TabHistoryScreen> createState() => _TabHistoryScreenState();
}

class _TabHistoryScreenState extends State<TabHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TabHistoryProvider>(context, listen: false).initLoadYears();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        context.read<TabHistoryProvider>().loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TabHistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isInitLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: provider.yearList.length + 1,
            itemBuilder: (context, index) {
              if (index == provider.yearList.length) {
                return _buildFooter(provider);
              }

              final item = provider.yearList[index];
              return _buildTimelineItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(YearTimelineItem item) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // 左侧时间轴
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: const Color(0xFFE5E5E5))),
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007DFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(child: Container(width: 2, color: const Color(0xFFE5E5E5))),
              ],
            ),
          ),
          // 年份
          SizedBox(
            width: 60,
            child: Text(
              item.year >= 0 ? '${item.year}' : '${item.year.abs()} BCE',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // 图片区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(1, 2))],
              ),
              child: item.artworkList.isEmpty
                  ? const Center(child: Text('该时间段暂无艺术品数据', style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.artworkList.take(4).map((artwork) {
                        return GestureDetector(
                          onTap: () => context.push('/detail', extra: artwork),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: artwork.primaryImageSmall,
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFooter(TabHistoryProvider provider) {
    if (!provider.hasMoreData) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.isLoadingMore) ...[
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              const Text('Museum access limited (15s)...') // 对应原代码的提示
            ] else 
              const Text('Pull up to load more', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}