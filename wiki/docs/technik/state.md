# State-Management (Riverpod)

Die Verwaltung nutzt **Riverpod 2.x** durchgaengig. Jede persistente Entitaet hat einen Service, einen Provider und einen optionalen ActionNotifier.

## Muster

```dart
// 1) Service-Provider (stateless, Singleton)
final employeeServiceProvider =
    Provider<EmployeeService>((ref) => EmployeeService());

// 2) Daten-Provider (FutureProvider oder StateNotifier)
final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  return ref.watch(employeeServiceProvider).loadAll();
});

// 3) Action-Notifier fuer Schreibaktionen
final employeeActionProvider =
    StateNotifierProvider<EmployeeActionNotifier, AsyncValue<void>>(
        (ref) => EmployeeActionNotifier(ref));

class EmployeeActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EmployeeActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> add(Employee e) async {
    state = const AsyncValue.loading();
    final ok = await _ref.read(employeeServiceProvider).addEmployee(e);
    state = const AsyncValue.data(null);
    if (ok) _ref.invalidate(employeesProvider);
    return ok;
  }
}
```

**Der Punkt**: Services kapseln I/O, Data-Provider kapseln Lesestatus, Action-Notifier kapseln Ausfuehrungsstatus. Widgets machen `ref.watch(...)` fuer Daten und `ref.read(...notifier).action()` fuer Aktionen.

## FutureProvider.family

Bei klient- oder tag-spezifischen Queries nutzen wir `Provider.family.autoDispose`:

```dart
final medicationsForClientProvider = FutureProvider.family
    .autoDispose<List<Medication>, String>((ref, clientId) async {
  return ref.watch(medicationServiceProvider).loadForClient(clientId);
});
```

`autoDispose` gibt die Ressourcen frei, sobald kein Widget mehr `ref.watch`-et. Das ist fuer selten besuchte Screens wichtig (Klient-Profil).

## Invalidation

Action-Notifier muessen die abhaengigen Provider invalidieren:

```dart
void _invalidate(String clientId) {
  _ref.invalidate(kassenbuchForClientProvider(clientId));
  _ref.invalidate(kassenbuchSaldoProvider(clientId));
}
```

Wer das vergisst, erlebt UI-Gespenster: eine erfolgreiche Aktion scheint nichts zu bewirken, weil der Provider nicht neu lief. Das passiert hauptsaechlich bei **Family-Providern**, wo die Identitaet (`clientId`, `DateTime`) auf das Byte genau stimmen muss.

## Kein BuildContext-Smuggling

Provider duerfen keinen `BuildContext` halten. Alle UI-Interaktionen (SnackBar, Dialog, Navigator) bleiben in den Widgets selbst. Aus Notifiern werfen wir `bool`-Rueckgabewerte oder `AsyncValue.error(...)` — die Widgets rendern daraus Fehlermeldungen.

## Testbarkeit

Provider koennen in Tests mit `ProviderScope(overrides: [...])` ersetzt werden. Fuer Services nutzen wir `SharedPreferences.setMockInitialValues({})`, um die Persistenz in-memory zu halten. Siehe z. B. `test/medication_service_test.dart`.

## Warum Riverpod, nicht Provider oder Bloc?

- **Compile-time-Safety**: Kein `Provider.of<X>(context)`-Match.
- **Keine InheritedWidget-Aufraeumerei**: Provider werden global deklariert, nicht in den Widget-Baum gehaengt.
- **AutoDispose**: Ressourcen-Lifecycle explizit.
- **Schlankere Tests**: Kein Bloc-Event/State-Ping-Pong fuer einfache CRUD-Aktionen.

Die Doku-App nutzt historisch **`provider` (ohne Ri)**. Die Verwaltung-App ist auf Riverpod gestartet und hat sich bewaehrt — ein Umbau der Doku ist nicht geplant, weil der Nutzen begrenzt und der Aufwand gross waere.

## Siehe auch

- [Architektur](architektur.md)
- [Offizielle Riverpod-Docs](https://riverpod.dev/)
