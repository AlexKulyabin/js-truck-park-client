const searchPanelKeyboardTopGutter = 12.0;

double searchPanelMaxHeight({
  required double screenHeight,
  required double keyboardInset,
  double topSafeAreaInset = 0.0,
  double keyboardTopGutter = searchPanelKeyboardTopGutter,
}) {
  if (keyboardInset <= 0.0) {
    return screenHeight * 0.8;
  }

  return (screenHeight - keyboardInset - topSafeAreaInset - keyboardTopGutter)
      .clamp(0.0, screenHeight);
}
