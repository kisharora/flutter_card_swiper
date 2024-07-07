import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class CardAnimation {
  CardAnimation({
    required this.animationController,
    required this.maxAngle,
    required this.initialScale,
    required this.initialOffset,
    this.isHorizontalSwipingEnabled = true,
    this.isVerticalSwipingEnabled = true,
    this.allowedSwipeDirection = const AllowedSwipeDirection.all(),
    this.onSwipeDirectionChanged,
    this.onSwipeProgress,
  }) : scale = initialScale;

  final double maxAngle;
  final double initialScale;
  final Offset initialOffset;
  final AnimationController animationController;
  final bool isHorizontalSwipingEnabled;
  final bool isVerticalSwipingEnabled;
  final AllowedSwipeDirection allowedSwipeDirection;

  final ValueChanged<CardSwiperDirection>? onSwipeDirectionChanged;
  final ValueChanged<double>? onSwipeProgress;

  double left = 0;
  double top = 0;
  double total = 0;
  double angle = 0;
  double scale;
  Offset difference = Offset.zero;

  late Animation<double> _leftAnimation;
  late Animation<double> _topAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _differenceAnimation;

  double get _maxAngleInRadian => maxAngle * (math.pi / 180);

  void sync() {
    if (_leftAnimation.value != left ||
        _topAnimation.value != top ||
        _scaleAnimation.value != scale ||
        _differenceAnimation.value != difference) {
      left = _leftAnimation.value;
      top = _topAnimation.value;
      scale = _scaleAnimation.value;
      difference = _differenceAnimation.value;
    }
  }

  void reset() {
    animationController.reset();
    left = 0;
    top = 0;
    total = 0;
    angle = 0;
    scale = initialScale;
    difference = Offset.zero;
  }

  void update(double dx, double dy, bool inverseAngle) {
    bool updated = false;

    if ((allowedSwipeDirection.left && dx < 0) ||
        (allowedSwipeDirection.right && dx > 0)) {
      left += dx;
      updated = true;
    }

    if ((allowedSwipeDirection.up && dy < 0) ||
        (allowedSwipeDirection.down && dy > 0)) {
      top += dy;
      updated = true;
    }

    if (updated) {
      total = left + top;
      updateAngle(inverseAngle);
      updateScale();
      updateDifference();
      onSwipeProgress?.call(left);
      onSwipeDirectionChanged?.call(
        left > 0
            ? CardSwiperDirection.right
            : left < 0
                ? CardSwiperDirection.left
                : top > 0
                    ? CardSwiperDirection.bottom
                    : CardSwiperDirection.top,
      );
    }
  }

  void updateAngle(bool inverse) {
    angle = clampDouble(
      _maxAngleInRadian * left / 1000,
      -_maxAngleInRadian,
      _maxAngleInRadian,
    );
    if (inverse) angle *= -1;
  }

  void updateScale() {
    scale = clampDouble(initialScale + (total.abs() / 5000), initialScale, 1.0);
  }

  void updateDifference() {
    final discrepancy = (total / 10).abs();
    difference = Offset(
      initialOffset.dx == 0 ? 0 : discrepancy * initialOffset.dx.sign,
      initialOffset.dy == 0 ? 0 : discrepancy * initialOffset.dy.sign,
    );
  }

  void animate(BuildContext context, CardSwiperDirection direction) {
    switch (direction) {
      case CardSwiperDirection.left:
        animateHorizontally(context, false);
        break;
      case CardSwiperDirection.right:
        animateHorizontally(context, true);
        break;
      case CardSwiperDirection.top:
        animateVertically(context, false);
        break;
      case CardSwiperDirection.bottom:
        animateVertically(context, true);
        break;
      case CardSwiperDirection.none:
        break;
    }
  }

  void animateHorizontally(BuildContext context, bool isToRight) {
    final screenWidth = MediaQuery.of(context).size.width;

    _leftAnimation = Tween<double>(
      begin: left,
      end: isToRight ? screenWidth : -screenWidth,
    ).animate(animationController);
    _topAnimation = Tween<double>(
      begin: top,
      end: top + top,
    ).animate(animationController);
    _scaleAnimation = Tween<double>(
      begin: scale,
      end: 1.0,
    ).animate(animationController);
    _differenceAnimation = Tween<Offset>(
      begin: difference,
      end: initialOffset,
    ).animate(animationController);
    animationController.forward();
  }

  void animateVertically(BuildContext context, bool isToBottom) {
    final screenHeight = MediaQuery.of(context).size.height;

    _leftAnimation = Tween<double>(
      begin: left,
      end: left + left,
    ).animate(animationController);
    _topAnimation = Tween<double>(
      begin: top,
      end: isToBottom ? screenHeight : -screenHeight,
    ).animate(animationController);
    _scaleAnimation = Tween<double>(
      begin: scale,
      end: 1.0,
    ).animate(animationController);
    _differenceAnimation = Tween<Offset>(
      begin: difference,
      end: initialOffset,
    ).animate(animationController);
    animationController.forward();
  }

  void animateBack(BuildContext context) {
    _leftAnimation = Tween<double>(
      begin: left,
      end: 0,
    ).animate(animationController);
    _topAnimation = Tween<double>(
      begin: top,
      end: 0,
    ).animate(animationController);
    _scaleAnimation = Tween<double>(
      begin: scale,
      end: initialScale,
    ).animate(animationController);
    _differenceAnimation = Tween<Offset>(
      begin: difference,
      end: Offset.zero,
    ).animate(animationController);
    animationController.forward();
  }

  void animateUndo(BuildContext context, CardSwiperDirection direction) {
    switch (direction) {
      case CardSwiperDirection.left:
        animateUndoHorizontally(context, false);
        break;
      case CardSwiperDirection.right:
        animateUndoHorizontally(context, true);
        break;
      case CardSwiperDirection.top:
        animateUndoVertically(context, false);
        break;
      case CardSwiperDirection.bottom:
        animateUndoVertically(context, true);
        break;
      case CardSwiperDirection.none:
        break;
    }
  }

  void animateUndoHorizontally(BuildContext context, bool isToRight) {
    final size = MediaQuery.of(context).size;

    _leftAnimation = Tween<double>(
      begin: isToRight ? size.width : -size.width,
      end: 0,
    ).animate(animationController);
    _topAnimation = Tween<double>(
      begin: top,
      end: top + top,
    ).animate(animationController);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: scale,
    ).animate(animationController);
    _differenceAnimation = Tween<Offset>(
      begin: initialOffset,
      end: difference,
    ).animate(animationController);
    animationController.forward();
  }

  void animateUndoVertically(BuildContext context, bool isToBottom) {
    final size = MediaQuery.of(context).size;

    _leftAnimation = Tween<double>(
      begin: left,
      end: left + left,
    ).animate(animationController);
    _topAnimation = Tween<double>(
      begin: isToBottom ? -size.height : size.height,
      end: 0,
    ).animate(animationController);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: scale,
    ).animate(animationController);
    _differenceAnimation = Tween<Offset>(
      begin: initialOffset,
      end: difference,
    ).animate(animationController);
    animationController.forward();
  }
}
