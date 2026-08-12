import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_dialyse/features/auth/data/models/user_model.dart';

void main() {
  test('UserModel parses the Django login payload', () {
    final payload = {
      'id': 7,
      'username': 'Dr. Ali',
      'email': 'ali@example.com',
      'role': 'Docteur',
    };

    final user = UserModel.fromJson(payload);

    expect(user.id, 7);
    expect(user.username, 'Dr. Ali');
    expect(user.email, 'ali@example.com');
    expect(user.role, 'Docteur');
  });
}
