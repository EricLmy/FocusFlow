import 'dart:collection';
import 'dart:async';

/// 缓存管理器
/// 提供内存缓存功能，支持TTL（生存时间）和LRU（最近最少使用）策略
class CacheManager<K, V> {
  final int _maxSize;
  final Duration? _defaultTtl;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  Timer? _cleanupTimer;

  CacheManager({
    int maxSize = 100,
    Duration? defaultTtl,
    Duration cleanupInterval = const Duration(minutes: 5),
  }) : _maxSize = maxSize,
       _defaultTtl = defaultTtl {
    // 启动定期清理过期缓存的定时器
    if (_defaultTtl != null) {
      _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _cleanupExpired());
    }
  }

  /// 获取缓存值
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // 检查是否过期
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    // LRU策略：将访问的项移到最后
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.value;
  }

  /// 设置缓存值
  void put(K key, V value, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _defaultTtl;
    final expiryTime = effectiveTtl != null 
        ? DateTime.now().add(effectiveTtl)
        : null;

    // 如果缓存已满，移除最旧的项
    if (_cache.length >= _maxSize && !_cache.containsKey(key)) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = _CacheEntry(value, expiryTime);
  }

  /// 移除缓存项
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// 检查是否包含指定键
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) {
      return false;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
  }

  /// 获取缓存大小
  int get size => _cache.length;

  /// 获取缓存命中率统计
  CacheStats get stats => _stats;

  /// 获取或计算缓存值
  V getOrPut(K key, V Function() valueFactory, {Duration? ttl}) {
    final cachedValue = get(key);
    if (cachedValue != null) {
      _stats._hits++;
      return cachedValue;
    }

    _stats._misses++;
    final newValue = valueFactory();
    put(key, newValue, ttl: ttl);
    return newValue;
  }

  /// 异步获取或计算缓存值
  Future<V> getOrPutAsync(K key, Future<V> Function() valueFactory, {Duration? ttl}) async {
    final cachedValue = get(key);
    if (cachedValue != null) {
      _stats._hits++;
      return cachedValue;
    }

    _stats._misses++;
    final newValue = await valueFactory();
    put(key, newValue, ttl: ttl);
    return newValue;
  }

  /// 批量获取
  Map<K, V> getAll(Iterable<K> keys) {
    final result = <K, V>{};
    for (final key in keys) {
      final value = get(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  /// 批量设置
  void putAll(Map<K, V> entries, {Duration? ttl}) {
    entries.forEach((key, value) {
      put(key, value, ttl: ttl);
    });
  }

  /// 清理过期的缓存项
  void _cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <K>[];

    for (final entry in _cache.entries) {
      if (entry.value.expiryTime != null && 
          entry.value.expiryTime!.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 销毁缓存管理器
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  final CacheStats _stats = CacheStats();
}

/// 缓存项
class _CacheEntry<V> {
  final V value;
  final DateTime? expiryTime;

  _CacheEntry(this.value, this.expiryTime);

  bool get isExpired {
    return expiryTime != null && DateTime.now().isAfter(expiryTime!);
  }
}

/// 缓存统计信息
class CacheStats {
  int _hits = 0;
  int _misses = 0;

  int get hits => _hits;
  int get misses => _misses;
  int get total => _hits + _misses;
  double get hitRate => total > 0 ? _hits / total : 0.0;
  double get missRate => total > 0 ? _misses / total : 0.0;

  void reset() {
    _hits = 0;
    _misses = 0;
  }

  @override
  String toString() {
    return 'CacheStats(hits: $_hits, misses: $_misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 全局缓存管理器实例
class GlobalCacheManager {
  static final _instance = GlobalCacheManager._internal();
  factory GlobalCacheManager() => _instance;
  GlobalCacheManager._internal();

  // 不同类型的缓存管理器
  final CacheManager<String, String> _stringCache = CacheManager(
    maxSize: 200,
    defaultTtl: const Duration(minutes: 30),
  );

  final CacheManager<String, Map<String, dynamic>> _dataCache = CacheManager(
    maxSize: 100,
    defaultTtl: const Duration(minutes: 15),
  );

  final CacheManager<String, List<dynamic>> _listCache = CacheManager(
    maxSize: 50,
    defaultTtl: const Duration(minutes: 10),
  );

  /// 字符串缓存（用于格式化结果等）
  CacheManager<String, String> get stringCache => _stringCache;

  /// 数据缓存（用于API响应等）
  CacheManager<String, Map<String, dynamic>> get dataCache => _dataCache;

  /// 列表缓存（用于任务列表等）
  CacheManager<String, List<dynamic>> get listCache => _listCache;

  /// 清空所有缓存
  void clearAll() {
    _stringCache.clear();
    _dataCache.clear();
    _listCache.clear();
  }

  /// 获取所有缓存的统计信息
  Map<String, CacheStats> getAllStats() {
    return {
      'string': _stringCache.stats,
      'data': _dataCache.stats,
      'list': _listCache.stats,
    };
  }

  /// 销毁所有缓存管理器
  void dispose() {
    _stringCache.dispose();
    _dataCache.dispose();
    _listCache.dispose();
  }
}

/// 缓存装饰器mixin
mixin CacheMixin {
  final CacheManager<String, dynamic> _cache = CacheManager(
    maxSize: 50,
    defaultTtl: const Duration(minutes: 5),
  );

  /// 缓存方法调用结果
  T cached<T>(String key, T Function() computation, {Duration? ttl}) {
    return _cache.getOrPut(key, computation, ttl: ttl) as T;
  }

  /// 异步缓存方法调用结果
  Future<T> cachedAsync<T>(String key, Future<T> Function() computation, {Duration? ttl}) async {
    return await _cache.getOrPutAsync(key, computation, ttl: ttl) as T;
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }

  /// 移除特定缓存项
  void removeCached(String key) {
    _cache.remove(key);
  }
}