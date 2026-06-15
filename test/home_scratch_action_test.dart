import 'package:ass2/models/destination.dart';
import 'package:ass2/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Destination destination({required String status, String? photoPath}) {
    return Destination(
      name: 'Test Destination',
      country: 'Test Country',
      category: 'Wisata Alam',
      status: status,
      notes: '',
      photoPath: photoPath,
      createdAt: '2026-06-15T00:00:00.000',
    );
  }

  test('scratch action only appears for wishlist with a photo', () {
    expect(
      canScratchDestination(
        destination(status: 'wishlist', photoPath: 'https://example.com/a.jpg'),
      ),
      isTrue,
    );
    expect(canScratchDestination(destination(status: 'wishlist')), isFalse);
    expect(
      canScratchDestination(destination(status: 'wishlist', photoPath: '   ')),
      isFalse,
    );
    expect(
      canScratchDestination(
        destination(status: 'visited', photoPath: 'https://example.com/a.jpg'),
      ),
      isFalse,
    );
  });
}
