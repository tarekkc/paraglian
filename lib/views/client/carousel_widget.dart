import 'package:flutter/material.dart';

class CarouselItemData {
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;

  CarouselItemData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
  });
}

class CarouselWidget extends StatefulWidget {
  final List<CarouselItemData> items;

  const CarouselWidget({
    super.key,
    required this.items,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % widget.items.length;
              });
              _animationController.forward(from: 0.0);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index % widget.items.length];
              return _buildCarouselItem(item);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPaginationDots(),
      ],
    );
  }

  Widget _buildCarouselItem(CarouselItemData item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.accentColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: item.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Découvrir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.items.length,
        (index) => Container(
          width: _currentPage == index ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF2E7D32)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
