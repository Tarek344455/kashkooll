# 🛡️ SKILL: Egypt Market — Rural & Mobile Data Optimization
**ID:** `kashkool-egypt-rural-data-v1`
**Activation:** AUTOMATIC — Triggers on any network request, media loading, caching, or offline feature in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`
**Enforcement Level:** MANDATORY — Part I Pillar 1 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Rural & Mobile Data Optimization** (Part I, Pillar 1): Aggressive compression, SQLite caching, PDF delta-loading, adaptive low-bitrate video.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Adding network calls (Dio, http, Supabase Postgres)
- Loading images/videos/PDFs
- Implementing offline-first features
- Configuring cache policies

---

## 📋 OPTIMIZATION REQUIREMENTS

### 1. Aggressive Compression
```dart
// Images: WebP, quality 75, max 1920px
class ImageOptimization {
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;
  static const int quality = 75;
  static const String format = 'webp';
  
  static Future<Uint8List> compress(Uint8List original) async {
    return await FlutterImageCompress.compressWithList(
      original,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: CompressFormat.webp,
    );
  }
}

// API responses: gzip + protobuf where possible
// Supabase: .select('id,title,thumbnail_url') — only the fields you render
```

### 2. SQLite Caching (Drift) — Offline-First
```dart
// All read-heavy data cached in Drift
// kashkool_core/lib/database/app_database.dart

@DriftDatabase(tables: [Lessons, Videos, PDFs, Quizzes, UserProgress])
class AppDatabase extends _$AppDatabase {
  // Cache TTL: 7 days for content, 1 day for dynamic data
  static const Duration contentTtl = Duration(days: 7);
  static const Duration dynamicTtl = Duration(days: 1);
  
  // Background sync queue
  Stream<List<SyncOperation>> get pendingSync => 
    (select(syncQueue)..where((s) => s.status.equals(SyncStatus.pending))).watch();
}

// Repository uses Drift as primary, Supabase as sync source
class LessonRepository {
  Future<List<Lesson>> getLessons(String courseId) async {
    // 1. Return cached immediately (instant UI)
    final cached = await db.lessonsByCourse(courseId).get();
    if (cached.isNotEmpty && !_isStale(cached.first)) return cached;
    
    // 2. Background fetch from Supabase
    unawaited(_syncFromSupabase(courseId));
    return cached;
  }
}
```

### 3. PDF Delta-Loading
```dart
// Load PDF metadata first, pages on demand
class PDFDeltaLoader {
  // 1. Fetch manifest (page count, thumbnails, total size)
  Future<PDFManifest> getManifest(String pdfId) async {
    return await Supabase.instance.client.from('pdf_manifests').select('*').eq('id', pdfId).single();
  }
  
  // 2. Load thumbnail grid (tiny images)
  Future<List<Uint8List>> getThumbnails(String pdfId, List<int> pageNumbers) async {
    // Parallel fetch, max 3 concurrent
  }
  
  // 3. Load single page on tap (progressive)
  Future<Uint8List> getPage(String pdfId, int pageNumber, {int quality = 50}) async {
    // Range request for single page
  }
  
  // 4. Prefetch next 2 pages in background
  void prefetchNext(String pdfId, int currentPage) {
    unawaited(getPage(pdfId, currentPage + 1));
    unawaited(getPage(pdfId, currentPage + 2));
  }
}
```

### 4. Adaptive Low-Bitrate Video
```dart
// Video quality adapts to network
class AdaptiveVideoPlayer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkQuality = ref.watch(networkQualityProvider);
    
    final quality = switch (networkQuality) {
      NetworkQuality.excellent => VideoQuality.hd1080,
      NetworkQuality.good => VideoQuality.hd720,
      NetworkQuality.fair => VideoQuality.sd480,
      NetworkQuality.poor => VideoQuality.low360,
      NetworkQuality.offline => VideoQuality.cachedOnly,
    };
    
    return VideoPlayerWidget(
      videoId: widget.videoId,
      preferredQuality: quality,
      allowQualitySwitch: true,
      showQualitySelector: true,
    );
  }
}

// Network quality detection
@riverpod
Stream<NetworkQuality> networkQuality(NetworkQualityRef ref) {
  return Stream.periodic(const Duration(seconds: 10), (_) async {
    final speed = await _measureDownloadSpeed(); // KB/s
    if (speed > 2000) return NetworkQuality.excellent;
    if (speed > 1000) return NetworkQuality.good;
    if (speed > 500) return NetworkQuality.fair;
    if (speed > 100) return NetworkQuality.poor;
    return NetworkQuality.offline;
  }).asyncMap((e) => e);
}
```

### 5. Data Saver Mode (User Toggle)
```dart
// Global data saver setting
@riverpod
class DataSaverMode extends _$DataSaverMode {
  @override
  bool build() => ref.watch(settingsProvider).dataSaverEnabled;
  
  void toggle(bool enabled) {
    state = enabled;
    ref.read(settingsProvider.notifier).setDataSaver(enabled);
  }
}

// Applied everywhere:
class DataSaverInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ref.read(dataSaverModeProvider)) {
      options.headers['Accept-Encoding'] = 'gzip, br';
      options.queryParameters['data_saver'] = 'true';
      // Reduce image quality params
    }
    handler.next(options);
  }
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Drift tables for all cacheable content
grep -r "@DriftDatabase\|@Table" packages/kashkool_core/lib/database/

# 2. Select() on Postgres queries (no full doc reads)
grep -r "\.select(" apps/ --include="*.dart"

# 3. PDF delta-loading implementation
grep -r "PDFDeltaLoader\|getManifest\|getPage" apps/

# 4. Adaptive video quality
grep -r "AdaptiveVideoPlayer\|NetworkQuality" apps/

# 5. Data saver mode
grep -r "DataSaverMode\|data_saver" apps/

# 6. Compression on uploads
grep -r "FlutterImageCompress\|compress" apps/
```

---

## 🛑 VIOLATION RESPONSE
- Full document reads without select() = **rejected**
- No SQLite caching for read-heavy data = **rejected**
- PDF loads all pages at once = **rejected**
- Video no adaptive quality = **rejected**
- No data saver mode = **rejected**
- Output includes: exact violation, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters content delivery by network quality, device storage, user preferences
- **Pulse-Triggered Routing**: Complex prefetch strategies escalate to cloud for optimal scheduling
- **360° Awareness**: Monitors cache hit rates, bandwidth usage, offline duration in real-time
- **Homeostasis**: Auto-evicts stale cache, adjusts quality dynamically, preloads on WiFi