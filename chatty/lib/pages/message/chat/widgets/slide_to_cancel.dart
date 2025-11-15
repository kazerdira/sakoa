import 'package:flutter/material.dart';

/// 🔥 SLIDE TO CANCEL GESTURE DETECTOR
/// Wraps voice recording widget to detect swipe-left-to-cancel gesture
/// Similar to WhatsApp voice message cancellation
class SlideToCancel extends StatefulWidget {
  final Widget child;
  final VoidCallback onCancel;
  final double cancelThreshold; // Distance to trigger cancel (in pixels)

  const SlideToCancel({
    Key? key,
    required this.child,
    required this.onCancel,
    this.cancelThreshold = 100.0,
  }) : super(key: key);

  @override
  State<SlideToCancel> createState() => _SlideToCancelState();
}

class _SlideToCancelState extends State<SlideToCancel>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only allow left drag (negative values)
      _dragPosition += details.delta.dx;
      if (_dragPosition > 0) {
        _dragPosition = 0;
      }
    });

    // Check if threshold exceeded
    if (_dragPosition.abs() >= widget.cancelThreshold) {
      _triggerCancel();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    if (_dragPosition.abs() >= widget.cancelThreshold) {
      // Already cancelled
      return;
    }

    // Snap back to original position
    _animation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ))
      ..addListener(() {
        setState(() {
          _dragPosition = _animation.value;
        });
      });

    _animationController.forward(from: 0);
    setState(() {
      _isDragging = false;
    });
  }

  void _triggerCancel() {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragPosition = 0;
    });

    // Vibrate feedback (if available)
    // HapticFeedback.mediumImpact();

    // Call cancel callback
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // Cancel hint (appears when sliding)
          if (_isDragging && _dragPosition < 0)
            Positioned(
              left: 20 + _dragPosition.abs(),
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: (_dragPosition.abs() / widget.cancelThreshold)
                      .clamp(0.0, 1.0),
                  duration: Duration(milliseconds: 50),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Release to cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Recording widget (slides with drag)
          Transform.translate(
            offset: Offset(_dragPosition, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
