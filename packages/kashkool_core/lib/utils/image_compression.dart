/// Client-side receipt image compression for Zero-Cost deployment.
///
/// Compresses receipt images to under [maxSizeBytes] (default 150 KB) to
/// protect Supabase Free Tier storage and bandwidth. Uses the `image` package
/// to re-encode JPEG at progressive quality levels until the target size is
/// met or [minQuality] is reached.
///
/// All money amounts in Kashkool use piasters (integer minor units, 1 EGP =
/// 100 piasters); this file has no money logic, it is purely a byte reducer.

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Result of a compression attempt.
class CompressionResult {
  const CompressionResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    required this.format,
    required this.quality,
  });

  /// Compressed image bytes, ready for upload.
  final Uint8List bytes;

  /// Original image size in bytes.
  final int originalSize;

  /// Compressed image size in bytes.
  final int compressedSize;

  /// Output image format ('jpeg', 'png', 'webp').
  final String format;

  /// JPEG/WebP quality used (1–100).
  final int quality;

  /// Compression ratio (0.0–1.0, lower = more compressed).
  double get ratio => originalSize == 0 ? 0.0 : compressedSize / originalSize;

  /// Bytes saved by compression.
  int get savedBytes => originalSize - compressedSize;

  @override
  String toString() =>
      'CompressionResult(size=$compressedSize, ratio=${ratio.toStringAsFixed(2)}, quality=$quality, format=$format)';
}

/// Compresses an image to fit within [maxSizeBytes].
///
/// Returns the compressed bytes. If the original is already smaller than
/// [maxSizeBytes], it is returned as-is (possibly re-encoded to JPEG for
/// consistency).
///
/// [format] overrides the output format ('jpeg', 'png', 'webp').
/// [minQuality] is the lowest acceptable JPEG/WebP quality (default 60).
/// [maxSizeBytes] default is 150 KB.
Future<CompressionResult> compressImage({
  required Uint8List originalBytes,
  String? format,
  int minQuality = 60,
  int maxSizeBytes = 150 * 1024,
}) async {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    // Not a decodable image; return as-is.
    return CompressionResult(
      bytes: originalBytes,
      originalSize: originalBytes.length,
      compressedSize: originalBytes.length,
      format: format ?? 'unknown',
      quality: 100,
    );
  }

  final outFormat = format ?? 'jpeg';
  final originalSize = originalBytes.length;

  // Already small enough: re-encode to target format for consistency.
  if (originalSize <= maxSizeBytes) {
    final encoded = _encodeImage(decoded, outFormat, 100);
    return CompressionResult(
      bytes: encoded,
      originalSize: originalSize,
      compressedSize: encoded.length,
      format: outFormat,
      quality: 100,
    );
  }

  // Binary search for the lowest quality that fits within maxSizeBytes.
  int low = minQuality;
  int high = 100;
  Uint8List bestBytes = await _encodeImageBytes(decoded, outFormat, minQuality);
  int bestQuality = minQuality;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final candidate = await _encodeImageBytes(decoded, outFormat, mid);
    if (candidate.length <= maxSizeBytes) {
      bestBytes = candidate;
      bestQuality = mid;
      low = mid + 1; // Try higher quality.
    } else {
      high = mid - 1; // Need lower quality.
    }
  }

  return CompressionResult(
    bytes: bestBytes,
    originalSize: originalSize,
    compressedSize: bestBytes.length,
    format: outFormat,
    quality: bestQuality,
  );
}

/// Encodes an [image] to [format] at [quality] and returns the bytes.
Future<Uint8List> _encodeImageBytes(
  img.Image image,
  String format,
  int quality,
) async {
  final bytes = _encodeImage(image, format, quality);
  return bytes;
}

/// Encodes an [image] to [format] at [quality] and returns the bytes.
Uint8List _encodeImage(img.Image image, String format, int quality) {
  switch (format.toLowerCase()) {
    case 'png':
      return Uint8List.fromList(img.encodePng(image));
    case 'webp':
      return Uint8List.fromList(img.encodeWebP(image, quality: quality));
    case 'jpeg':
    default:
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}