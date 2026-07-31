import 'dart:async';

enum UserFeedbackMutation { reviewCreated, complaintCreated }

class UserFeedbackMutationEvents {
  UserFeedbackMutationEvents._();

  static final StreamController<UserFeedbackMutation> _controller =
      StreamController<UserFeedbackMutation>.broadcast(sync: true);

  static Stream<UserFeedbackMutation> get stream => _controller.stream;

  static void publish(UserFeedbackMutation mutation) {
    _controller.add(mutation);
  }
}
