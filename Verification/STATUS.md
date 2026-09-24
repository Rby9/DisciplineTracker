# Starea verificărilor

## Verificări automate

- Sintaxa fișierelor Swift.
- Structura fișierelor JSON din cataloagele de resurse.
- Formatarea modificărilor Git.
- Sintaxa scriptului `Verification/run-checks.sh`.
- Recurența activităților și limitele calendaristice.
- Păstrarea stărilor și migrarea datelor existente.
- Conversia activităților în rutine fără duplicate.
- Exportul și restaurarea backupului.

## Verificări manuale recomandate

1. Activitățile, rutinele și jurnalul rămân salvate după repornire.
2. Conversia într-o rutină nu dublează activitatea inițială.
3. Stările „De făcut”, „Finalizată” și „Omisă” sunt păstrate corect.
4. Editarea unei rutine protejează activitățile modificate individual.
5. Statisticile săptămânale afișează valorile corecte.
6. Notificările sunt anulate după finalizare, omiterea sau ștergerea activității.
7. Interfața funcționează cu titluri lungi, text mărit și Reduce Motion.

## Limite cunoscute

- Datele sunt salvate local și nu sunt sincronizate automat între dispozitive.
- Numărul notificărilor locale programate simultan este limitat.
- Pentru verificarea completă sunt necesare compilarea în Xcode și testarea pe iPhone.
