import 'dart:async';

import 'package:idb_shim/idb_browser.dart';

import 'package:matrix/src/database/zone_transaction_mixin.dart';

/// Key-Value store abstraction over IndexedDB so that the sdk database can use
/// a single interface for all platforms. API is inspired by Hive.
class BoxCollection with ZoneTransactionMixin {
  final Database _db;
  final Set<String> boxNames;
  final String name;

  BoxCollection(this._db, this.boxNames, this.name);

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    Object? sqfliteDatabase,
    Object? sqfliteFactory,
    IdbFactory? idbFactory,
    int version = 1,
  }) async {
    idbFactory ??= getIdbFactory()!;
    final db = await idbFactory.open(
      name,
      version: version,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;
        for (final name in boxNames) {
          if (db.objectStoreNames.contains(name)) continue;

          db.createObjectStore(name, autoIncrement: true);
        }
      },
    );
    return BoxCollection(db, boxNames, name);
  }

  Box<V> openBox<V>(String name) {
    if (!boxNames.contains(name)) {
      throw ('Box with name $name is not in the known box names of this collection.');
    }
    return Box<V>(name, this);
  }

  List<Future<void> Function(Transaction txn)>? _txnCache;

  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  }) => zoneTransaction(() async {
    boxNames ??= _db.objectStoreNames.toList();
    final txnCache = _txnCache = [];
    await action();
    final cache = List<Future<void> Function(Transaction txn)>.from(txnCache);
    _txnCache = null;
    if (cache.isEmpty) return;
    final txn = _db.transactionList(
      boxNames!,
      readOnly ? 'readonly' : 'readwrite',
    );
    for (final fun in cache) {
      // The IDB methods return a Future in Dart but must not be awaited in
      // order to have an actual transaction. They must only be performed and
      // then the transaction object must call `txn.completed;` which then
      // returns the actual future.
      // https://developer.mozilla.org/en-US/docs/Web/API/IDBTransaction
      unawaited(fun(txn));
    }
    await txn.completed;
    return;
  });

  Future<void> clear() async {
    final txn = _db.transaction(boxNames.toList(), 'readwrite');
    for (final name in boxNames) {
      unawaited(txn.objectStore(name).clear());
    }
    await txn.completed;
  }

  Future<void> close() async {
    assert(_txnCache == null, 'Database closed while in transaction!');
    // Note, zoneTransaction and txnCache are different kinds of transactions.
    return zoneTransaction(() async => _db.close());
  }

  Future<void> deleteDatabase(String name, [dynamic factory]) async {
    await close();
    await (factory ?? getIdbFactory()).deleteDatabase(name);
  }
}

class Box<V> {
  final String name;
  final BoxCollection boxCollection;
  final Map<String, V?> _quickAccessCache = {};

  /// _quickAccessCachedKeys is only used to make sure that if you fetch all keys from a
  /// box, you do not need to have an expensive read operation twice. There is
  /// no other usage for this at the moment. So the cache is never partial.
  /// Once the keys are cached, they need to be updated when changed in put and
  /// delete* so that the cache does not become outdated.
  Set<String>? _quickAccessCachedKeys;

  Box(this.name, this.boxCollection);

  Future<List<String>> getAllKeys([Transaction? txn]) async {
    if (_quickAccessCachedKeys != null) return _quickAccessCachedKeys!.toList();
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final request = store.getAllKeys(null);
    final keys = await request
        .then((result) {
          return result.cast<String>();
        })
        .catchError((e) {
          throw StateError('Failed to get all keys: $e');
        });

    _quickAccessCachedKeys = keys.toSet();
    return keys;
  }

  Future<Map<String, V>> getAllValues([Transaction? txn]) async {
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final map = <String, V>{};
    final cursorStream = store.openCursor(autoAdvance: true);
    await for (final cursor in cursorStream) {
      map[cursor.key as String] = _fromValue(cursor.value) as V;
    }
    return map;
  }

  Future<V?> get(String key, [Transaction? txn]) async {
    if (_quickAccessCache.containsKey(key)) return _quickAccessCache[key];
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    _quickAccessCache[key] = await store.getObject(key).then(_fromValue);
    return _quickAccessCache[key];
  }

  Future<List<V?>> getAll(List<String> keys, [Transaction? txn]) async {
    if (keys.every((key) => _quickAccessCache.containsKey(key))) {
      return keys.map((key) => _quickAccessCache[key]).toList();
    }
    txn ??= boxCollection._db.transaction(name, 'readonly');
    final store = txn.objectStore(name);
    final list = await Future.wait(
      keys.map((key) => store.getObject(key).then(_fromValue)),
    );
    for (var i = 0; i < keys.length; i++) {
      _quickAccessCache[keys[i]] = list[i];
    }
    return list;
  }

  Future<void> put(String key, V val, [Transaction? txn]) async {
    if (boxCollection._txnCache != null) {
      boxCollection._txnCache!.add((txn) => put(key, val, txn));
      _quickAccessCache[key] = val;
      _quickAccessCachedKeys?.add(key);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    await store.put(val as Object, key);
    _quickAccessCache[key] = val;
    _quickAccessCachedKeys?.add(key);
    return;
  }

  Future<void> delete(String key, [Transaction? txn]) async {
    if (boxCollection._txnCache != null) {
      boxCollection._txnCache!.add((txn) => delete(key, txn));
      _quickAccessCache[key] = null;
      _quickAccessCachedKeys?.remove(key);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    await store.delete(key);

    // Set to null instead remove() so that inside of transactions null is
    // returned.
    _quickAccessCache[key] = null;
    _quickAccessCachedKeys?.remove(key);
    return;
  }

  Future<void> deleteAll(List<String> keys, [Transaction? txn]) async {
    if (boxCollection._txnCache != null) {
      boxCollection._txnCache!.add((txn) => deleteAll(keys, txn));
      for (final key in keys) {
        _quickAccessCache[key] = null;
      }
      _quickAccessCachedKeys?.removeAll(keys);
      return;
    }

    txn ??= boxCollection._db.transaction(name, 'readwrite');
    final store = txn.objectStore(name);
    for (final key in keys) {
      await store.delete(key);
      _quickAccessCache[key] = null;
      _quickAccessCachedKeys?.remove(key);
    }
    return;
  }

  void clearQuickAccessCache() {
    _quickAccessCache.clear();
    _quickAccessCachedKeys = null;
  }

  Future<void> clear([Transaction? txn]) async {
    if (boxCollection._txnCache != null) {
      boxCollection._txnCache!.add((txn) => clear(txn));
    } else {
      txn ??= boxCollection._db.transaction(name, 'readwrite');
      final store = txn.objectStore(name);
      await store.clear();
    }

    clearQuickAccessCache();
  }

  V? _fromValue(Object? value) {
    if (value == null) return null;
    switch (V) {
      case const (List<dynamic>):
        return List.unmodifiable(value as List) as V;
      case const (Map<dynamic, dynamic>):
        return Map.unmodifiable(value as Map) as V;
      case const (int):
      case const (double):
      case const (bool):
      case const (String):
      default:
        return value as V;
    }
  }
}
