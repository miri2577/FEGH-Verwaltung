// Re-Export aus dem Shared-Package `fegh_core`.
//
// Das Employee-Modell ist jetzt geteilt mit der Doku-App.
// Bestehende Imports `import '../models/employee.dart'` funktionieren
// weiter, inkl. Employee, Address, EmergencyContact, EmployeeStatus
// und ContractType.
export 'package:fegh_core/fegh_core.dart'
    show
        Employee,
        Mitarbeiter,
        Address,
        EmergencyContact,
        EmployeeStatus,
        ContractType,
        MitarbeiterBereich,
        EmployeeStatusDisplay,
        ContractTypeDisplay,
        MitarbeiterBereichDisplay;
