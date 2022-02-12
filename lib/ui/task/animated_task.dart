import 'package:flutter/material.dart';
import 'package:habit_tracker_flutter/constants/app_assets.dart';

import 'package:habit_tracker_flutter/ui/common_widgets/centered_svg_icon.dart';
import 'package:habit_tracker_flutter/ui/task/task_completion_ring.dart';

import '../theming/app_theme.dart';

class AnimatedTask extends StatefulWidget {
  final String iconName;
  const AnimatedTask({Key? key, required this.iconName}) : super(key: key);

  @override
  _AnimatedTaskState createState() => _AnimatedTaskState();
}

class _AnimatedTaskState extends State<AnimatedTask>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _curveAnimation;
  bool _showCheckIcon = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 750),
    );
    _animationController.addStatusListener(_checkStatusUpdate);
    _curveAnimation = _animationController.drive(
      CurveTween(curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_checkStatusUpdate);
    _animationController.dispose();
    super.dispose();
  }

  void _checkStatusUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // ウィジェットがマウントされている場合のみsetStateにしないと、エラーが出る
      if (mounted) {
        setState(() => _showCheckIcon = true);
      }
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _showCheckIcon = false);
        }
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_animationController.status != AnimationStatus.completed) {
      _animationController.forward();
      // checkIconが消えてからのみリセットできる↓
    } else if (!_showCheckIcon) {
      _animationController.value = 0.0;
    }
  }

  void _handleTapCancel() {
    if (_animationController.status != AnimationStatus.completed) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      // onTapUpには引数が必要なので、(_) => を追加しないとエラー (The argument type 'void Function()' can't be assigned to the parameter type 'void Function(TapUpDetails)?')が出る
      onTapUp: (_) => _handleTapCancel,
      //タップした後にウィジェット外に指を動かした場合はキャンセルとする ↓
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _curveAnimation,
        builder: (BuildContext context, Widget? child) {
          final themeData = AppTheme.of(context);
          final progress = _curveAnimation.value;
          final hasCompleted = progress == 1.0;
          final iconColor =
              hasCompleted ? themeData.accentNegative : themeData.taskIcon;
          return Stack(
            children: [
              TaskCompletionRing(
                progress: _curveAnimation.value,
              ),
              Positioned.fill(
                child: CenteredSvgIcon(
                  iconName: hasCompleted && _showCheckIcon
                      ? AppAssets.check
                      : widget.iconName,
                  color: iconColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
