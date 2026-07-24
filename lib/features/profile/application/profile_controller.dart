import 'package:flutter/foundation.dart';

class ProfileState {
  const ProfileState({
    this.showInviteAction = false,
  });

  final bool showInviteAction;

  ProfileState copyWith({
    bool? showInviteAction,
  }) {
    return ProfileState(
      showInviteAction: showInviteAction ?? this.showInviteAction,
    );
  }
}

class ProfileController extends ChangeNotifier {
  ProfileState _state = const ProfileState();

  ProfileState get state => _state;

  void setInviteActionVisible(bool visible) {
    if (_state.showInviteAction == visible) {
      return;
    }

    _state = _state.copyWith(showInviteAction: visible);
    notifyListeners();
  }
}
