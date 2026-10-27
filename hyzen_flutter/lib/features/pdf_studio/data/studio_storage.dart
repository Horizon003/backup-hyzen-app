import 'studio_storage_contract.dart';
import 'studio_storage_stub.dart'
    if (dart.library.io) 'studio_storage_io.dart' as implementation;

export 'studio_storage_contract.dart';

StudioStorage createStudioStorage() => implementation.createStudioStorage();
