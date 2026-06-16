import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/destination_photo.dart';
import 'polaroid_painters.dart';

class PolaroidDeckGallery extends StatefulWidget {
  final List<DestinationPhoto> photos;
  final VoidCallback onDeckEmpty;
  final Function(DestinationPhoto)? onDeletePhoto;
  final String decoType;

  const PolaroidDeckGallery({
    super.key,
    required this.photos,
    required this.onDeckEmpty,
    this.onDeletePhoto,
    this.decoType = 'tape',
  });

  @override
  State<PolaroidDeckGallery> createState() => _PolaroidDeckGalleryState();
}

class _PolaroidDeckGalleryState extends State<PolaroidDeckGallery> with SingleTickerProviderStateMixin {
  late List<DestinationPhoto> _deck;
  
  // Posisi dan rotasi top card saat di-drag
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0.0;
  
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    // Membalik urutan agar foto pertama ada di paling atas (karena Stack dari bawah ke atas)
    _deck = List.from(widget.photos.reversed);
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(PolaroidDeckGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      setState(() {
        _deck = List.from(widget.photos.reversed);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      // Rotasi bertambah saat digeser menjauhi pusat
      _dragRotation = _dragOffset.dx / 400.0; 
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Tentukan apakah kartu dibuang atau dikembalikan
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final throwAway = _dragOffset.dx.abs() > 100 || velocityX.abs() > 1000;

    if (throwAway) {
      // Lempar keluar layar
      final endX = _dragOffset.dx > 0 ? 500.0 : -500.0;
      _offsetAnim = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(endX, _dragOffset.dy + (details.velocity.pixelsPerSecond.dy * 0.2)),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

      _rotAnim = Tween<double>(
        begin: _dragRotation,
        end: _dragRotation + (velocityX > 0 ? 0.5 : -0.5),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

      _animController.forward(from: 0).then((_) {
        setState(() {
          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
          _deck.removeLast(); // Buang foto teratas
          if (_deck.isEmpty) {
            widget.onDeckEmpty();
          }
        });
      });
    } else {
      // Kembali ke tengah (Spring back)
      _offsetAnim = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));

      _rotAnim = Tween<double>(
        begin: _dragRotation,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));

      _animController.forward(from: 0).then((_) {
        setState(() {
          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
        });
      });
    }
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
      );
    }
    // Handle File on Web vs Android
    if (kIsWeb) {
      return Image.network(
        path, // Di web, file path dari image_picker biasanya berupa blob URL
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
      );
    }
  }

  Widget _buildPolaroidCard(DestinationPhoto photo, {bool isTop = false, int index = 0}) {
    // Generate pseudo-random spread yang lebih berantakan
    final random = math.Random(photo.id ?? index);
    
    // Rotasi dari -0.3 hingga 0.3 radian (~17 derajat)
    final baseRotation = isTop ? 0.0 : (random.nextDouble() - 0.5) * 0.6; 
    
    // Offset posisi acak agar ujung-ujung kartu mencuat keluar
    final double dx = isTop ? 0.0 : (random.nextDouble() - 0.5) * 60;
    final double dy = isTop ? 0.0 : (random.nextDouble() - 0.5) * 60;

    Widget cardContent = CustomPaint(
      painter: PolaroidBackgroundPainter(),
      child: Container(
        width: 280,
        height: 340,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60), // Margin polaroid
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: _buildImage(photo.photoPath),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              photo.caption ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 24,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    // Tambahkan Washi Tape atau Pin
    cardContent = Stack(
      alignment: Alignment.center,
      children: [
        cardContent,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            painter: widget.decoType == 'pin' ? PushPinPainter() : WashiTapePainter(),
            size: const Size(double.infinity, 40),
          ),
        ),
        if (isTop && widget.onDeletePhoto != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Hapus Memori',
                onPressed: () => widget.onDeletePhoto!(photo),
              ),
            ),
          ),
      ],
    );

    if (isTop) {
      return AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final offset = _animController.isAnimating ? _offsetAnim.value : _dragOffset;
          final rot = _animController.isAnimating ? _rotAnim.value : _dragRotation;

          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rot,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: child,
              ),
            ),
          );
        },
        child: cardContent,
      );
    } else {
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: baseRotation,
          child: cardContent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Semua foto sudah dilihat.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: _deck.asMap().entries.map((entry) {
          final index = entry.key;
          final photo = entry.value;
          final isTop = index == _deck.length - 1;
          
          return _buildPolaroidCard(photo, isTop: isTop, index: index);
        }).toList(),
      ),
    );
  }
}
