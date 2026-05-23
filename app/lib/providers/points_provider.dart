import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/points_service.dart';

final pointsServiceProvider = Provider<PointsService>((ref) => PointsService());
