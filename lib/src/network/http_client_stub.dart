// Stub for packages not available on ohos (cronet_http, cupertino_http)
// These classes are never instantiated on ohos - the code falls through
// to the default dart:io HttpClient.

// ignore_for_file: unused_import

class CronetEngine {
  factory CronetEngine.build({dynamic options}) => throw UnsupportedError('Not available on ohos');
}

class CronetClient {
  factory CronetClient.fromCronetEngine(dynamic engine) => throw UnsupportedError('Not available on ohos');
}

class CupertinoClient {
  factory CupertinoClient.fromSessionConfiguration(dynamic config) => throw UnsupportedError('Not available on ohos');
}
