export 'connection_stub.dart'
    if (dart.library.ffi) 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';
