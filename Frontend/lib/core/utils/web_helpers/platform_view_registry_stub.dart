class PlatformViewRegistry {
  bool registerViewFactory(String viewTypeId, dynamic Function(int viewId) viewFactory, {bool isVisible = true}) {
    return false;
  }
}

final platformViewRegistry = PlatformViewRegistry();
