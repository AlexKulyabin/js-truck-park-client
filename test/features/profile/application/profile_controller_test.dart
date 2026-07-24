import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/profile/application/profile_controller.dart';

void main() {
  group('ProfileController', () {
    test('starts with invite action hidden to preserve generated behavior', () {
      final controller = ProfileController();

      expect(controller.state.showInviteAction, isFalse);
    });

    test('updates invite action visibility through immutable state', () {
      final controller = ProfileController();
      final initialState = controller.state;

      controller.setInviteActionVisible(true);

      expect(controller.state, isNot(same(initialState)));
      expect(controller.state.showInviteAction, isTrue);
    });

    test('does not notify when visibility is unchanged', () {
      final controller = ProfileController();
      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });

      controller.setInviteActionVisible(false);

      expect(notifications, 0);
    });
  });
}
