export 'database_initializer_stub.dart'
    if (dart.library.js_util) 'database_initializer_web.dart'
    if (dart.library.io) 'database_initializer_io.dart';
