import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/policy_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final policyProvider = Provider<PolicyService>((ref) => PolicyService(ref));
