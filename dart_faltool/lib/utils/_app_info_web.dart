/// Web stub: there is no filesystem on the browser, so version loading is a
/// no-op. Consumers should set `AppInfo` version via another channel on web
/// (e.g. build-time injection) if they need a non-default value.
String? loadVersion(String path) => null;
