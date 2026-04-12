import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:park_buddy/utils/family_service.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<T> timeout(Duration timeLimit,
          {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

// Shared test data
const kUserId = 'user-test-001';
const kJoinCode = 'FAM-TEST';

// Tests
void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late FamilyService service;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(kUserId);

    service = FamilyService(mockSupabase);
  });

  //  createFamily 
  group('createFamily', () {

    // TC-CF-01 
    test('TC-CF-01',
        () async {
      when(() => mockSupabase.rpc(
            'create_family',
            params: {'p_familyname': 'My Family', 'p_userid': kUserId},
          )).thenAnswer((_) => FakePostgrestFilterBuilder(
            Future.value([{'familyjoincode': kJoinCode}]),
          ));

      final result = await service.createFamily('My Family');
      expect(result, equals(kJoinCode));
    });

    // TC-CF-02 
    test('TC-CF-02', () {
      when(() => mockSupabase.rpc(
            'create_family',
            params: {'p_familyname': 'My Family', 'p_userid': kUserId},
          )).thenThrow(PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      ));

      expect(
        () => service.createFamily('My Family'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });



  //  deleteFamily 
  group('deleteFamily', () {

    // TC-DF-01 
    test('TC-DF-01',
        () async {
      when(() => mockSupabase.rpc(
            'delete_family_cascade',
            params: {'target_family_code': kJoinCode},
          )).thenAnswer((_) => FakePostgrestFilterBuilder(
            Future<dynamic>.value(null),
          ));

      await expectLater(service.deleteFamily(kJoinCode), completes);
    });

    // TC-DF-02 
    test('TC-DF-02',
        () {
      when(() => mockSupabase.rpc(
            'delete_family_cascade',
            params: {'target_family_code': kJoinCode},
          )).thenThrow(
            PostgrestException(message: 'foreign key violation', code: '23503'),
          );

      expect(
        () => service.deleteFamily(kJoinCode),
        throwsA(equals('foreign key violation')),
      );
    });

    // TC-DF-03 
    test('TC-DF-03', () {
      when(() => mockSupabase.rpc(
            'delete_family_cascade',
            params: {'target_family_code': kJoinCode},
          )).thenThrow(Exception('network timeout'));

      expect(
        () => service.deleteFamily(kJoinCode),
        throwsA(predicate<String>(
          (msg) => msg.startsWith('An unexpected error occurred:'),
          'starts with "An unexpected error occurred:"',
        )),
      );
    });
  });
}