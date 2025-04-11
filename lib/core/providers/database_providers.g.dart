// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'3d3a397d2ea952fc020fce0506793a5564e93530';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$databaseHash() => r'1dacec65e9c032b9ea6c9611bc89000ebceff806';

/// See also [database].
@ProviderFor(database)
final databaseProvider = FutureProvider<Database>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = FutureProviderRef<Database>;
String _$userDaoHash() => r'146c5c614de31baa78e41be12aa6aa215d66b716';

/// See also [userDao].
@ProviderFor(userDao)
final userDaoProvider = Provider<UserDao>.internal(
  userDao,
  name: r'userDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserDaoRef = ProviderRef<UserDao>;
String _$scanDaoHash() => r'2e8ffbc318ae72c9b4e46ace0db2a2fd0a5901a7';

/// See also [scanDao].
@ProviderFor(scanDao)
final scanDaoProvider = Provider<ScanDao>.internal(
  scanDao,
  name: r'scanDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanDaoRef = ProviderRef<ScanDao>;
String _$lesionDaoHash() => r'b30caa2ba7628b6d046d94fa820bf42474879e32';

/// See also [lesionDao].
@ProviderFor(lesionDao)
final lesionDaoProvider = Provider<LesionDao>.internal(
  lesionDao,
  name: r'lesionDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lesionDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LesionDaoRef = ProviderRef<LesionDao>;
String _$userSettingsDaoHash() => r'0baa0c8ff2b81e51dee0ec8b2f953bc15ac60e7c';

/// See also [userSettingsDao].
@ProviderFor(userSettingsDao)
final userSettingsDaoProvider = Provider<UserSettingsDao>.internal(
  userSettingsDao,
  name: r'userSettingsDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userSettingsDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserSettingsDaoRef = ProviderRef<UserSettingsDao>;
String _$userLesionCountsHash() => r'288504a46c61acb17b43cd61468b1ac56bad7fe9';

/// See also [userLesionCounts].
@ProviderFor(userLesionCounts)
final userLesionCountsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
      userLesionCounts,
      name: r'userLesionCountsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$userLesionCountsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLesionCountsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$userScansHash() => r'6ce15296069aa84f9ff8d6a0c5ba8a410c207068';

/// See also [userScans].
@ProviderFor(userScans)
final userScansProvider = AutoDisposeFutureProvider<List<Scan>>.internal(
  userScans,
  name: r'userScansProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userScansHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserScansRef = AutoDisposeFutureProviderRef<List<Scan>>;
String _$allUsersHash() => r'31f03518feff2826a1fd447962c4fbaec2fd9afe';

/// See also [allUsers].
@ProviderFor(allUsers)
final allUsersProvider = AutoDisposeFutureProvider<List<User>>.internal(
  allUsers,
  name: r'allUsersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllUsersRef = AutoDisposeFutureProviderRef<List<User>>;
String _$currentUserSettingsHash() =>
    r'fea1a6f169a9d5c9787a143069744d14e29120db';

/// See also [currentUserSettings].
@ProviderFor(currentUserSettings)
final currentUserSettingsProvider =
    AutoDisposeFutureProvider<UserSettings?>.internal(
      currentUserSettings,
      name: r'currentUserSettingsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$currentUserSettingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserSettingsRef = AutoDisposeFutureProviderRef<UserSettings?>;
String _$scanByIdHash() => r'da61cac49db1f52e5c4a689e2651bd7022dcbaea';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [scanById].
@ProviderFor(scanById)
const scanByIdProvider = ScanByIdFamily();

/// See also [scanById].
class ScanByIdFamily extends Family<AsyncValue<Scan?>> {
  /// See also [scanById].
  const ScanByIdFamily();

  /// See also [scanById].
  ScanByIdProvider call(int scanId) {
    return ScanByIdProvider(scanId);
  }

  @override
  ScanByIdProvider getProviderOverride(covariant ScanByIdProvider provider) {
    return call(provider.scanId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scanByIdProvider';
}

/// See also [scanById].
class ScanByIdProvider extends AutoDisposeFutureProvider<Scan?> {
  /// See also [scanById].
  ScanByIdProvider(int scanId)
    : this._internal(
        (ref) => scanById(ref as ScanByIdRef, scanId),
        from: scanByIdProvider,
        name: r'scanByIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$scanByIdHash,
        dependencies: ScanByIdFamily._dependencies,
        allTransitiveDependencies: ScanByIdFamily._allTransitiveDependencies,
        scanId: scanId,
      );

  ScanByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scanId,
  }) : super.internal();

  final int scanId;

  @override
  Override overrideWith(FutureOr<Scan?> Function(ScanByIdRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: ScanByIdProvider._internal(
        (ref) => create(ref as ScanByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scanId: scanId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Scan?> createElement() {
    return _ScanByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScanByIdProvider && other.scanId == scanId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scanId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScanByIdRef on AutoDisposeFutureProviderRef<Scan?> {
  /// The parameter `scanId` of this provider.
  int get scanId;
}

class _ScanByIdProviderElement extends AutoDisposeFutureProviderElement<Scan?>
    with ScanByIdRef {
  _ScanByIdProviderElement(super.provider);

  @override
  int get scanId => (origin as ScanByIdProvider).scanId;
}

String _$lesionsByScanIdHash() => r'e6f78396203eff2fe0f2b83aef6eb64bb2a49d4a';

/// See also [lesionsByScanId].
@ProviderFor(lesionsByScanId)
const lesionsByScanIdProvider = LesionsByScanIdFamily();

/// See also [lesionsByScanId].
class LesionsByScanIdFamily extends Family<AsyncValue<List<Lesion>>> {
  /// See also [lesionsByScanId].
  const LesionsByScanIdFamily();

  /// See also [lesionsByScanId].
  LesionsByScanIdProvider call(int scanId) {
    return LesionsByScanIdProvider(scanId);
  }

  @override
  LesionsByScanIdProvider getProviderOverride(
    covariant LesionsByScanIdProvider provider,
  ) {
    return call(provider.scanId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lesionsByScanIdProvider';
}

/// See also [lesionsByScanId].
class LesionsByScanIdProvider extends AutoDisposeFutureProvider<List<Lesion>> {
  /// See also [lesionsByScanId].
  LesionsByScanIdProvider(int scanId)
    : this._internal(
        (ref) => lesionsByScanId(ref as LesionsByScanIdRef, scanId),
        from: lesionsByScanIdProvider,
        name: r'lesionsByScanIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$lesionsByScanIdHash,
        dependencies: LesionsByScanIdFamily._dependencies,
        allTransitiveDependencies:
            LesionsByScanIdFamily._allTransitiveDependencies,
        scanId: scanId,
      );

  LesionsByScanIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scanId,
  }) : super.internal();

  final int scanId;

  @override
  Override overrideWith(
    FutureOr<List<Lesion>> Function(LesionsByScanIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LesionsByScanIdProvider._internal(
        (ref) => create(ref as LesionsByScanIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scanId: scanId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Lesion>> createElement() {
    return _LesionsByScanIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LesionsByScanIdProvider && other.scanId == scanId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scanId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LesionsByScanIdRef on AutoDisposeFutureProviderRef<List<Lesion>> {
  /// The parameter `scanId` of this provider.
  int get scanId;
}

class _LesionsByScanIdProviderElement
    extends AutoDisposeFutureProviderElement<List<Lesion>>
    with LesionsByScanIdRef {
  _LesionsByScanIdProviderElement(super.provider);

  @override
  int get scanId => (origin as LesionsByScanIdProvider).scanId;
}

String _$allUserLesionsHash() => r'aadc55c1677a387ea11df5b5651de90a836d8142';

/// See also [allUserLesions].
@ProviderFor(allUserLesions)
final allUserLesionsProvider = AutoDisposeFutureProvider<List<Lesion>>.internal(
  allUserLesions,
  name: r'allUserLesionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allUserLesionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllUserLesionsRef = AutoDisposeFutureProviderRef<List<Lesion>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
