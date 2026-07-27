import 'package:flutter_test/flutter_test.dart';
import 'package:personalverwaltung/models/client.dart';
import 'package:personalverwaltung/models/employee.dart';
import 'package:personalverwaltung/models/team.dart';
import 'package:personalverwaltung/services/capacity_service.dart';

void main() {
  final t0 = DateTime(2026, 1, 1);

  Employee emp(String id) => Employee(
        id: id,
        firstName: 'V$id',
        lastName: 'N$id',
        email: '$id@example.org',
        createdAt: t0,
        updatedAt: t0,
      );

  Team team(String id, List<String> members) => Team(
        id: id,
        name: 'Team $id',
        memberIds: members,
        createdAt: t0,
        updatedAt: t0,
      );

  Client client(String id, String teamId, int hbg) => Client(
        id: id,
        firstName: 'K',
        lastName: id,
        teamId: teamId,
        hilfebedarfsgruppe: hbg,
        createdAt: t0,
        updatedAt: t0,
      );

  group('CapacityService – bedarfsgetriebene Sollbesetzung', () {
    test('requiredStaff aus dem FLS-Bedarf der Klienten (HBG), nicht Kopfzahl',
        () async {
      final employees = [emp('e1'), emp('e2'), emp('e3')];
      final teams = [
        team('t1', ['e1', 'e2', 'e3'])
      ];
      // 3 Klienten HBG 12 = 3 * 11.599 = 34.797 FLS/Woche.
      // / 25 FLS je Vollzeitkraft = 1.39 -> aufgerundet 2 (nicht die Kopfzahl 3).
      final clients = [
        client('c1', 't1', 12),
        client('c2', 't1', 12),
        client('c3', 't1', 12),
      ];

      final result = await CapacityService().generateWorkforceAnalytics(
        employees: employees,
        teams: teams,
        shifts: const [],
        timesheets: const [],
        clients: clients,
      );

      expect(result.teamCapacities.single.requiredStaff, 2);
    });

    test('ohne Klienten-FLS faellt requiredStaff auf die Kopfzahl zurueck',
        () async {
      final employees = [emp('e1'), emp('e2'), emp('e3')];
      final teams = [
        team('t1', ['e1', 'e2', 'e3'])
      ];

      final result = await CapacityService().generateWorkforceAnalytics(
        employees: employees,
        teams: teams,
        shifts: const [],
        timesheets: const [],
        clients: const [],
      );

      expect(result.teamCapacities.single.requiredStaff, 3);
    });

    test('Klienten anderer Teams zaehlen nicht zum Bedarf', () async {
      final employees = [emp('e1'), emp('e2')];
      final teams = [
        team('t1', ['e1', 'e2'])
      ];
      // Bedarf nur aus t1-Klienten; c2 gehoert zu t2 und wird ignoriert.
      final clients = [
        client('c1', 't1', 1), // 2.089 FLS/Woche -> ceil(2.089/25) = 1
        client('c2', 't2', 12),
      ];

      final result = await CapacityService().generateWorkforceAnalytics(
        employees: employees,
        teams: teams,
        shifts: const [],
        timesheets: const [],
        clients: clients,
      );

      expect(result.teamCapacities.single.requiredStaff, 1);
    });
  });
}
