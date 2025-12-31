import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/tab_main_provider.dart';

class TabMainScreen extends StatefulWidget {
  const TabMainScreen({super.key});

  @override
  State<TabMainScreen> createState() => _TabMainScreenState();
}

class _TabMainScreenState extends State<TabMainScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 页面初始化时加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TabMainProvider>(context, listen: false).loadArtworks();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TabMainProvider>().loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Consumer<TabMainProvider>(
          builder: (context, provider, child) {
            if (provider.isInitLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Enter the artwork name',
                            fillColor: const Color(0xFFF0F0F0),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onSubmitted: (value) {
                            provider.setSearchKeyword(value);
                            provider.loadArtworks();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          provider.setSearchKeyword(_searchController.text);
                          provider.loadArtworks();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007DFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),
                // 列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.artworks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.artworks.length) {
                        return _buildFooter(provider);
                      }
                      final item = provider.artworks[index];
                      return GestureDetector(
                        onTap: () {
                          context.push('/detail', extra: item);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(2, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: item.primaryImageSmall,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(TabMainProvider provider) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: provider.isLoadingMore
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Loading...')
              ],
            )
          : Text(provider.hasMoreData ? 'Pull up to load more' : 'No more data', style: TextStyle(color: Colors.grey[600])),
    );
  }
}