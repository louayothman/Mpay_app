import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // إضافة استيراد dart:ui للحصول على PointerHoverEvent و PointerExitEvent

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double borderRadius;
  final bool enableTilt;
  final bool enableHoverScale;
  final double maxTiltAngle;
  final double hoverScale;
  final VoidCallback? onTap;

  const InteractiveCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.boxShadow,
    this.borderRadius = 12.0,
    this.enableTilt = true,
    this.enableHoverScale = true,
    this.maxTiltAngle = 0.05,
    this.hoverScale = 1.03,
    this.onTap,
  }) : super(key: key);

  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovering = false;
  double _rotateX = 0;
  double _rotateY = 0;

  void _onHoverChanged(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (!isHovering) {
        _rotateX = 0;
        _rotateY = 0;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableTilt || !_isHovering) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset position = box.globalToLocal(details.globalPosition);

    setState(() {
      _rotateY = widget.maxTiltAngle * (position.dx / size.width - 0.5) * 2;
      _rotateX = -widget.maxTiltAngle * (position.dy / size.height - 0.5) * 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      onHover: (event) {
        if (widget.enableTilt) {
          _onPanUpdate(DragUpdateDetails(
            globalPosition: event.position,
            delta: Offset.zero,
          ));
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: _onPanUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY)
            ..scale(widget.enableHoverScale && _isHovering ? widget.hoverScale : 1.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.boxShadow ?? defaultShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class InteractiveContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color hoverColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool enableHoverEffect;

  const InteractiveContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.hoverColor = Colors.white,
    this.borderRadius = 12.0,
    this.boxShadow,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.enableHoverEffect = true,
  }) : super(key: key);

  @override
  _InteractiveContainerState createState() => _InteractiveContainerState();
}

class _InteractiveContainerState extends State<InteractiveContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHoverEffect) {
          setState(() {
            _isHovering = true;
          });
        }
      },
      onExit: (_) {
        if (widget.enableHoverEffect) {
          setState(() {
            _isHovering = false;
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.boxShadow ?? defaultShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class InteractiveListItem extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color hoverColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enableHoverEffect;

  const InteractiveListItem({
    Key? key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.hoverColor = Colors.white,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.enableHoverEffect = true,
  }) : super(key: key);

  @override
  _InteractiveListItemState createState() => _InteractiveListItemState();
}

class _InteractiveListItemState extends State<InteractiveListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHoverEffect) {
          setState(() {
            _isHovering = true;
          });
        }
      },
      onExit: (_) {
        if (widget.enableHoverEffect) {
          setState(() {
            _isHovering = false;
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
