import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScratchCardController {
  _ScratchCardState? _state;

  void reset() => _state?._reset();
}

class ScratchCard extends StatefulWidget {
  final Widget child;
  final ScratchCardController? controller;
  final Color overlayColor;
  final double scratchRadius;
  final double revealThreshold;
  final String hintText;
  final String progressLabel;
  final ValueChanged<double>? onProgressChanged;
  final VoidCallback? onRevealed;

  const ScratchCard({
    super.key,
    required this.child,
    required this.hintText,
    required this.progressLabel,
    this.controller,
    this.overlayColor = const Color(0xFF4F7B60),
    this.scratchRadius = 28,
    this.revealThreshold = 0.6,
    this.onProgressChanged,
    this.onRevealed,
  }) : assert(revealThreshold > 0 && revealThreshold <= 1);

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 40;

  final List<List<Offset>> _scratchPaths = [];
  final Set<int> _revealedCells = {};

  late final AnimationController _revealController;
  Size _cardSize = Size.zero;
  double _revealPercentage = 0;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant ScratchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _revealController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isRevealed) return;
    _scratchPaths.add([]);
    _recordScratchPoint(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isRevealed || _scratchPaths.isEmpty) return;
    _recordScratchPoint(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isRevealed && _revealPercentage >= widget.revealThreshold) {
      _triggerAutoReveal();
    }
  }

  void _recordScratchPoint(Offset point) {
    if (_cardSize.isEmpty ||
        point.dx < 0 ||
        point.dy < 0 ||
        point.dx > _cardSize.width ||
        point.dy > _cardSize.height) {
      return;
    }

    final path = _scratchPaths.last;
    final samples = <Offset>[];
    if (path.isEmpty) {
      samples.add(point);
    } else {
      final previous = path.last;
      final distance = (point - previous).distance;
      final spacing = math.max(4.0, widget.scratchRadius * 0.35);
      final steps = math.max(1, (distance / spacing).ceil());
      for (var i = 1; i <= steps; i++) {
        samples.add(Offset.lerp(previous, point, i / steps)!);
      }
    }

    setState(() {
      path.addAll(samples);
      for (final sample in samples) {
        _markRevealedCells(sample);
      }
      _revealPercentage = _revealedCells.length / (_gridSize * _gridSize);
    });

    widget.onProgressChanged?.call(_revealPercentage);
    if (_revealPercentage >= widget.revealThreshold) {
      _triggerAutoReveal();
    }
  }

  void _markRevealedCells(Offset point) {
    final cellWidth = _cardSize.width / _gridSize;
    final cellHeight = _cardSize.height / _gridSize;
    final col = (point.dx / cellWidth).floor();
    final row = (point.dy / cellHeight).floor();
    final colRadius = (widget.scratchRadius / cellWidth).ceil() + 1;
    final rowRadius = (widget.scratchRadius / cellHeight).ceil() + 1;
    final cellHalfDiagonal =
        math.sqrt(cellWidth * cellWidth + cellHeight * cellHeight) / 2;
    final coverageRadius = widget.scratchRadius + cellHalfDiagonal;

    for (var rowOffset = -rowRadius; rowOffset <= rowRadius; rowOffset++) {
      for (var colOffset = -colRadius; colOffset <= colRadius; colOffset++) {
        final candidateRow = row + rowOffset;
        final candidateCol = col + colOffset;
        if (candidateRow < 0 ||
            candidateRow >= _gridSize ||
            candidateCol < 0 ||
            candidateCol >= _gridSize) {
          continue;
        }

        final center = Offset(
          (candidateCol + 0.5) * cellWidth,
          (candidateRow + 0.5) * cellHeight,
        );
        if ((center - point).distance <= coverageRadius) {
          _revealedCells.add(candidateRow * _gridSize + candidateCol);
        }
      }
    }
  }

  void _triggerAutoReveal() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
    widget.onRevealed?.call();
    _revealController.forward();
  }

  void _reset() {
    _revealController.reset();
    setState(() {
      _scratchPaths.clear();
      _revealedCells.clear();
      _revealPercentage = 0;
      _isRevealed = false;
    });
    widget.onProgressChanged?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cardSize = Size(constraints.maxWidth, constraints.maxHeight);
        final displayedProgress = _isRevealed ? 1.0 : _revealPercentage;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, _) => CustomPaint(
                    painter: ScratchOverlayPainter(
                      scratchPaths: _scratchPaths,
                      scratchRadius: widget.scratchRadius,
                      overlayColor: widget.overlayColor,
                      revealProgress: _revealController.value,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isRevealed ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gesture,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.hintText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.progressLabel} '
                          '${(displayedProgress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScratchOverlayPainter extends CustomPainter {
  final List<List<Offset>> scratchPaths;
  final double scratchRadius;
  final Color overlayColor;
  final double revealProgress;

  ScratchOverlayPainter({
    required this.scratchPaths,
    required this.scratchRadius,
    required this.overlayColor,
    required this.revealProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());

    final overlayPaint = Paint()..color = overlayColor;
    canvas.drawRect(bounds, overlayPaint);

    final patternPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width; x += 28) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        patternPaint,
      );
    }

    final clearStroke = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = scratchRadius * 2;

    final clearFill = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    for (final points in scratchPaths) {
      if (points.isEmpty) continue;
      if (points.length == 1) {
        canvas.drawCircle(points.first, scratchRadius, clearFill);
        continue;
      }

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, clearStroke);
    }

    if (revealProgress > 0) {
      final center = size.center(Offset.zero);
      final maxRadius =
          math.sqrt(size.width * size.width + size.height * size.height) / 2;
      canvas.drawCircle(center, maxRadius * revealProgress, clearFill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchOverlayPainter oldDelegate) => true;
}
