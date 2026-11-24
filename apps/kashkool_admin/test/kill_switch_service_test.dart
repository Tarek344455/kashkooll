import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_admin/core/kill_switch_service.dart';

/// In-memory store so the state machine is tested without a live backend.
class MemorySwitchStore implements SwitchStore {
  MemorySwitchStore({this.failWrites = false});

  final Map<String, bool> values = <String, bool>{};
  bool failWrites;

  @override
  Future<Map<String, bool>> read() async => Map<String, bool>.of(values);

  @override
  Future<void> write(String feature, bool enabled) async {
    if (failWrites) throw StateError('write rejected');
    values[feature] = enabled;
  }
}

void main() {
  group('KillSwitchService', () {
    test('the global kill switch is off by default', () {
      final service = KillSwitchService(store: MemorySwitchStore());

      expect(service.isGlobalKillSwitchActive, isFalse);
    });

    test('toggleKillSwitch flips the global flag', () {
      final service = KillSwitchService(store: MemorySwitchStore());

      service.toggleKillSwitch(true);
      expect(service.isGlobalKillSwitchActive, isTrue);

      service.toggleKillSwitch(false);
      expect(service.isGlobalKillSwitchActive, isFalse);
    });

    test('known feature flags default to their configured value', () {
      final service = KillSwitchService(store: MemorySwitchStore());

      expect(service.isFeatureEnabled('new_quiz_feature'), isTrue);
      expect(service.isFeatureEnabled('live_classroom'), isTrue);
      expect(service.isFeatureEnabled('cash_desk'), isTrue);
    });

    test('unknown feature flags are disabled', () {
      final service = KillSwitchService(store: MemorySwitchStore());

      expect(service.isFeatureEnabled('not_a_feature'), isFalse);
    });

    test('setFeature overrides a single flag', () {
      final service = KillSwitchService(store: MemorySwitchStore());

      service.setFeature('cash_desk', false);

      expect(service.isFeatureEnabled('cash_desk'), isFalse);
      expect(service.isFeatureEnabled('live_classroom'), isTrue);
    });

    test('a rejected write rolls the switch back and reports the error', () async {
      final store = MemorySwitchStore();
      final service = KillSwitchService(store: store);

      await service.toggleKillSwitch(true);

      expect(service.isGlobalKillSwitchActive, isTrue);
      expect(store.values['global_emergency'], isTrue);

      store.failWrites = true;
      await service.toggleKillSwitch(false);

      expect(service.isGlobalKillSwitchActive, isTrue, reason: 'rollback to last saved state');
      expect(service.error, isNotNull);
    });

    test('the provider exposes a working service', () async {
      final container = ProviderContainer(
        overrides: [
          killSwitchServiceProvider.overrideWith(
            (ref) => KillSwitchService(store: MemorySwitchStore()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(killSwitchServiceProvider);
      expect(service, isA<KillSwitchService>());
      expect(service.isGlobalKillSwitchActive, isFalse);
    });
  });
}
