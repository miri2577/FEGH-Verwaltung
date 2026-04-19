import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cloud_provider.dart';
import '../providers/settings_provider.dart';
import '../services/roles_policy_service.dart';

final rolesPolicyProvider = Provider<RolesPolicyService>((ref) {
  final client = ref.watch(cloudClientProvider);
  final org = ref.watch(appSettingsProvider).organizationId ?? 'default';
  return RolesPolicyService(client: client, orgBase: 'eingliederungshilfe/organizations/$org');
});

