import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/artwork.dart';
import '../provider/swipe_provider.dart';

class TabSwipeScreen extends StatefulWidget {
  const TabSwipeScreen({super.key});

  @override
  State<TabSwipeScreen> createState() => _TabSwipeScreenState();
}

class _TabSwipeScreenState extends State<TabSwipeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _animation;
  double _dragOffsetY = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_animController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SwipeProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final provider = context.read<SwipeProvider>();
    if (provider.isLoading) return;

    setState(() {
      _dragOffsetY += details.delta.dy;
      // 阻尼
      if (_dragOffsetY > 0 && !provider.canSwipePrevious) {
        _dragOffsetY *= 0.3;
      } else if (_dragOffsetY < 0 && !provider.canSwipeNext) {
        _dragOffsetY *= 0.3;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final provider = context.read<SwipeProvider>();
    if (provider.isLoading) return;

    final threshold = MediaQuery.of(context).size.height / 4;
    double endY = 0;
    bool changePage = false;
    bool isNext = false;

    if (_dragOffsetY < -threshold && provider.canSwipeNext) {
      // 上滑 -> 下一张
      endY = -MediaQuery.of(context).size.height;
      changePage = true;
      isNext = true;
    } else if (_dragOffsetY > threshold && provider.canSwipePrevious) {
      // 下滑 -> 上一张
      endY = MediaQuery.of(context).size.height;
      changePage = true;
      isNext = false;
    }

    // 动画
    _animation = Tween<Offset>(
      begin: Offset(0, _dragOffsetY),
      end: Offset(0, endY),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));

    _animController.reset();
    _animController.forward().then((_) {
      if (changePage) {
        if (isNext) {
          provider.confirmSwipeToNext();
        } else {
          provider.confirmSwipeToPrevious();
        }
      }
      setState(() {
        _dragOffsetY = 0; // 重置
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<SwipeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentArtwork == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage, style: const TextStyle(color: Colors.white)),
                  ElevatedButton(onPressed: provider.initialize, child: const Text('Retry')),
                ],
              ),
            );
          }

          return GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Stack(
              children: [
                // 1. 上一张 (位置在上)
                if (provider.prevArtwork != null)
                  Transform.translate(
                    offset: Offset(0, -MediaQuery.of(context).size.height + (_animation.value.dy != 0 ? _animation.value.dy : _dragOffsetY)),
                    child: _SingleArtworkView(artwork: provider.prevArtwork!),
                  ),

                // 2. 当前张
                if (provider.currentArtwork != null)
                  Transform.translate(
                    offset: Offset(0, _animation.value.dy != 0 ? _animation.value.dy : _dragOffsetY),
                    child: _SingleArtworkView(artwork: provider.currentArtwork!),
                  ),

                // 3. 下一张 (位置在下)
                if (provider.nextArtwork != null)
                  Transform.translate(
                    offset: Offset(0, MediaQuery.of(context).size.height + (_animation.value.dy != 0 ? _animation.value.dy : _dragOffsetY)),
                    child: _SingleArtworkView(artwork: provider.nextArtwork!),
                  ),
                  
                // Loading Overlay when switching
                if (provider.isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SingleArtworkView extends StatelessWidget {
  final Artwork artwork;
  const _SingleArtworkView({required this.artwork});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: artwork.primaryImageSmall,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(color: Colors.grey),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  artwork.artistDisplayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  artwork.objectDate,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}