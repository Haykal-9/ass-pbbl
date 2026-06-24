import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Menggambar frame putih Polaroid dan shadow di belakang gambar
class PolaroidBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gambar bayangan (drop shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    
    final shadowRect = Rect.fromLTWH(4, 8, size.width, size.height);
    canvas.drawRect(shadowRect, shadowPaint);

    // Gambar frame putih Polaroid
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(frameRect, framePaint);
    
    // Gambar subtle border agar terlihat lebih nyata
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(frameRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menggambar Washi Tape (selotip) atau Pin di atas gambar
class WashiTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tapePaint = Paint()
      ..color = const Color(0x66FFD700) // Warna emas transparan untuk selotip
      ..style = PaintingStyle.fill;

    // Selotip diletakkan agak miring di tengah atas
    canvas.save();
    canvas.translate(size.width / 2, 20); // Pindah ke tengah atas
    canvas.rotate(-5 * math.pi / 180); // Miring -5 derajat

    // Gambar persegi panjang selotip
    final tapeRect = Rect.fromCenter(center: Offset.zero, width: 80, height: 25);
    canvas.drawRect(tapeRect, tapePaint);
    
    // Tekstur selotip (garis-garis tipis putih transparan)
    final texturePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    for (double i = -35; i <= 35; i += 5) {
      canvas.drawLine(Offset(i, -12), Offset(i, 12), texturePaint);
    }
    
    // Potongan kasar di ujung selotip (zig-zag kecil)
    // Untuk memperindah efek visual (opsional, diringkas dengan Paint biasa)
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menggambar Push Pin di atas gambar
class PushPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Pindah ke tengah atas
    canvas.save();
    canvas.translate(size.width / 2, 20);

    // Jarum pin (merak / silver)
    final needlePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, 5), width: 3, height: 12), needlePaint);

    // Kepala pin bulat merah dengan gradien/shadow sederhana
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(const Offset(1, 2), 7, shadowPaint);

    final headPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 7, headPaint);

    // Highlight agar terlihat 3D
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-2, -2), 2, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menggambar Ikon Hati secara custom menggunakan Bezier Paths
class HeartPainter extends CustomPainter {
  final bool isFilled;
  final Color color;

  HeartPainter({required this.isFilled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    // Menggambar hati yang lebih proporsional
    final path = Path();
    
    // Mulai dari lekukan tengah atas
    path.moveTo(width * 0.5, height * 0.25);

    // Setengah kiri
    path.cubicTo(
      width * 0.5, height * 0.05,
      0, height * 0.05,
      0, height * 0.4,
    );
    path.cubicTo(
      0, height * 0.65,
      width * 0.25, height * 0.8,
      width * 0.5, height * 0.95,
    );

    // Setengah kanan
    path.moveTo(width * 0.5, height * 0.25);
    path.cubicTo(
      width * 0.5, height * 0.05,
      width, height * 0.05,
      width, height * 0.4,
    );
    path.cubicTo(
      width, height * 0.65,
      width * 0.75, height * 0.8,
      width * 0.5, height * 0.95,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) {
    return oldDelegate.isFilled != isFilled || oldDelegate.color != color;
  }
}
