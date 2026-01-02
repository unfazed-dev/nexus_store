import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_supabase_adapter/src/realtime_manager_wrapper.dart';
import 'package:nexus_store_supabase_adapter/src/supabase_realtime_manager.dart';
import 'package:test/test.dart';

// Test model
class TestUser {
  const TestUser({required this.id, required this.name});

  factory TestUser.fromJson(Map<String, dynamic> json) =>
      TestUser(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Mock for the underlying SupabaseRealtimeManager
class MockSupabaseRealtimeManager extends Mock
    implements SupabaseRealtimeManager<TestUser, String> {}

void main() {
  group('RealtimeManagerWrapper', () {
    group('DefaultRealtimeManagerWrapper', () {
      late MockSupabaseRealtimeManager mockManager;
      late DefaultRealtimeManagerWrapper<TestUser, String> wrapper;

      setUp(() {
        mockManager = MockSupabaseRealtimeManager();
        wrapper = DefaultRealtimeManagerWrapper<TestUser, String>(mockManager);
      });

      test('isInitialized delegates to underlying manager', () {
        when(() => mockManager.isInitialized).thenReturn(true);

        expect(wrapper.isInitialized, isTrue);

        verify(() => mockManager.isInitialized).called(1);
      });

      test('isInitialized returns false when manager not initialized', () {
        when(() => mockManager.isInitialized).thenReturn(false);

        expect(wrapper.isInitialized, isFalse);

        verify(() => mockManager.isInitialized).called(1);
      });

      test('initialize delegates to underlying manager', () async {
        when(() => mockManager.initialize()).thenAnswer((_) async {});

        await wrapper.initialize();

        verify(() => mockManager.initialize()).called(1);
      });

      test('watchItem delegates to underlying manager', () {
        const user = TestUser(id: '1', name: 'Test');
        final controller = StreamController<TestUser?>.broadcast();
        addTearDown(controller.close);

        when(() => mockManager.watchItem('1', initialValue: user))
            .thenAnswer((_) => controller.stream);

        final stream = wrapper.watchItem('1', initialValue: user);

        expect(stream, isA<Stream<TestUser?>>());
        verify(() => mockManager.watchItem('1', initialValue: user)).called(1);
      });

      test('watchItem without initial value delegates correctly', () {
        final controller = StreamController<TestUser?>.broadcast();
        addTearDown(controller.close);

        when(() => mockManager.watchItem('1'))
            .thenAnswer((_) => controller.stream);

        final stream = wrapper.watchItem('1');

        expect(stream, isA<Stream<TestUser?>>());
        verify(() => mockManager.watchItem('1')).called(1);
      });

      test('watchAll delegates to underlying manager', () {
        const users = [TestUser(id: '1', name: 'Test')];
        final controller = StreamController<List<TestUser>>.broadcast();
        addTearDown(controller.close);

        when(() => mockManager.watchAll(initialValue: users))
            .thenAnswer((_) => controller.stream);

        final stream = wrapper.watchAll(initialValue: users);

        expect(stream, isA<Stream<List<TestUser>>>());
        verify(() => mockManager.watchAll(initialValue: users)).called(1);
      });

      test('watchAll without initial value delegates correctly', () {
        final controller = StreamController<List<TestUser>>.broadcast();
        addTearDown(controller.close);

        when(() => mockManager.watchAll()).thenAnswer((_) => controller.stream);

        final stream = wrapper.watchAll();

        expect(stream, isA<Stream<List<TestUser>>>());
        verify(() => mockManager.watchAll()).called(1);
      });

      test('notifyItemChanged delegates to underlying manager', () {
        const user = TestUser(id: '1', name: 'Test');
        when(() => mockManager.notifyItemChanged(user)).thenReturn(null);

        wrapper.notifyItemChanged(user);

        verify(() => mockManager.notifyItemChanged(user)).called(1);
      });

      test('notifyItemDeleted delegates to underlying manager', () {
        when(() => mockManager.notifyItemDeleted('1')).thenReturn(null);

        wrapper.notifyItemDeleted('1');

        verify(() => mockManager.notifyItemDeleted('1')).called(1);
      });

      test('dispose delegates to underlying manager', () async {
        when(() => mockManager.dispose()).thenAnswer((_) async {});

        await wrapper.dispose();

        verify(() => mockManager.dispose()).called(1);
      });
    });
  });
}
