double searchPanelMaxHeight({
  required double screenHeight,
  required double keyboardInset,
}) {
  if (keyboardInset <= 0.0) {
    return screenHeight * 0.8;
  }

  return (screenHeight - keyboardInset).clamp(0.0, screenHeight);
}
