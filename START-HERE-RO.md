# DisciplineTracker — actualizarea din 6 septembrie 2026

Arhiva conține proiectul complet actualizat. Nu trebuie să copiezi codul manual în fiecare fișier.

## 1. Pune actualizarea în proiectul tău

1. Închide Xcode.
2. În Finder → Documents, selectează folderul existent `DisciplineTracker` și apasă Command + D. Păstrează copia ca backup al codului.
3. Dezarhivează pachetul primit într-un loc separat, de exemplu Downloads.
4. Deschide folderul `DisciplineTracker` din arhiva dezarhivată. În interior găsești folderul surselor `DisciplineTracker`, proiectul `DisciplineTracker.xcodeproj` și folderul `Verification`.
5. Copiază aceste trei elemente în interiorul proiectului tău existent, `Documents/DisciplineTracker`. Alege Replace pentru elementele care există deja. Lucrând în interiorul proiectului existent, păstrezi istoricul Git.
6. Deschide `Documents/DisciplineTracker/DisciplineTracker.xcodeproj`.

Fișierele noi din folderul surselor sunt incluse automat de proiect. `Verification` rămâne lângă proiect, în afara folderului surselor aplicației.

Backupul proiectului păstrează codul, nu baza de date din simulator. Actualizarea adaugă câmpuri opționale în SwiftData; nu conține o resetare a datelor. Păstrează același Bundle Identifier și aceeași aplicație instalată. Dacă apare o eroare ModelContainer/migrare, trimite eroarea înainte de a șterge aplicația sau datele.

## 2. Verificarea automată pe Mac

Am inclus o verificare separată care folosește o bază temporară de test, fără să deschidă datele tale reale. Necesită Xcode și macOS 14 sau mai nou.

Deschide Terminal și execută:

```bash
cd ~/Documents/DisciplineTracker
bash Verification/run-checks.sh
```

Verifică generarea datelor recurente, schimbările de oră, conversia fără duplicate, stările și migrarea unei baze create cu modelele din arhiva ta inițială. La final ar trebui să scrie `All native checks passed.` Dacă apare o eroare, trimite textul complet.

Aceste teste sunt pregătite pentru Mac; nu au putut fi executate în mediul în care am editat proiectul. Un test reușit nu înlocuiește compilarea aplicației și verificarea interfeței.

## 3. Rulează în simulator

În Xcode selectează simulatorul pe care îl foloseai deja și apasă Command + R.

Ce ar trebui să vezi:

- În detaliile unui task individual apare **Make recurring**. Alegi zilele, ora și durata, vezi numărul de taskuri noi, apoi Create. Taskul original rămâne o singură dată, la data și ora inițială, cu aceeași stare.
- **Cancel** din conversie abandonează formularul.
- În detaliile unui task există **Status → Pending / Completed / Skipped**. Poți schimba starea și prin apăsare lungă pe task, în Today sau Weekly.
- Un task **Skipped** este portocaliu, nu intră în Pending și nu mai primește notificări. Apăsarea cercului îl marchează Completed; încă o apăsare îl readuce în Pending.
- În Weekly ai filtrul **Skipped**, iar în All ai grupuri pentru taskurile completate și sărite.
- Butonul cu grafic din dreapta sus în Weekly deschide **Weekly insights**: progres, zile, categorii și jurnal. Apăsarea unei zile deschide jurnalul acelei date.
- Add, Edit, Details, conversia, editorul de rutine și Journal folosesc aceeași temă închisă, cu accent mov.

Exemplu: 10 planificate, 6 Completed, 2 Skipped și 2 Pending înseamnă **60% progres**. Skipped nu mărește procentul de completare.

Verifică și că taskurile și notițele existente sunt încă acolo după închiderea și redeschiderea aplicației.

## 4. Instalează pe iPhone

Proiectul este setat acum cu versiune minimă iOS 18.0. Compatibilitatea efectivă trebuie confirmată la compilare și pe telefon. Xcode trebuie să recunoască versiunea iOS instalată pe dispozitiv.

1. Conectează iPhone-ul la Mac prin cablu și deblochează-l. Acceptă **Trust This Computer**, dacă apare.
2. În Xcode → **Settings → Accounts**, adaugă contul tău Apple dacă nu este deja adăugat.
3. În navigatorul din stânga, selectează proiectul albastru **DisciplineTracker**. Sub **TARGETS**, selectează **DisciplineTracker**.
4. Deschide **Signing & Capabilities**. Bifează **Automatically manage signing** și selectează echipa ta la **Team**; pentru cont gratuit apare **Personal Team**.
5. În selectorul de dispozitiv din bara de sus, alege iPhone-ul tău în locul simulatorului.
6. Dacă Xcode solicită **Developer Mode**, pe telefon deschide **Settings → Privacy & Security → Developer Mode**. Activează opțiunea, repornește telefonul și confirmă activarea. Dacă opțiunea nu apare încă, conectează mai întâi telefonul la Xcode și încearcă rularea.
7. Apasă **Command + R**. Xcode compilează și instalează aplicația. Acceptă eventualele confirmări de încredere afișate pe telefon, apoi rulează din nou dacă este cerut.
8. Acceptă notificările când aplicația le solicită.

Aceasta este instalarea pentru testare pe dispozitivul personal. [Instrucțiunile Apple pentru rularea pe dispozitiv](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices) și [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

Contul gratuit Personal Team permite testarea pe telefon; profilurile expiră după 7 zile, apoi trebuie să reconstruiești și să reinstalezi din Xcode. [Limitele oficiale Apple](https://developer.apple.com/help/account/basics/about-your-developer-account).

Taskurile din simulator nu se transferă automat pe telefon: aplicația salvează local și nu are încă sincronizare sau import/export.

## 5. Testează notificările pe telefon

1. Adaugă un task la 2–3 minute în viitor și lasă-l Pending.
2. Blochează telefonul; la ora aleasă ar trebui să primești notificarea exactă.
3. Repetă cu alt task, apoi pune-l Skipped înainte de oră: nu ar trebui să primești reminderul.
4. Testează și cu aplicația deschisă: managerul permite acum bannerul și sunetul în prim-plan.
5. Dacă nu apare notificarea, verifică permisiunea aplicației în Settings → Notifications și modul Focus.

Managerul păstrează o coadă de cel mult 64 de notificări apropiate, cu până la trei notificări per task. Coada se reface când deschizi aplicația și când modifici taskurile. Rutinele sunt create pentru toată perioada aleasă, dar asta nu garantează notificări pentru luni întregi fără redeschiderea aplicației.

## Ce urmează

După ce confirmăm funcționarea pe telefon: salvăm un commit, apoi putem adăuga export/import pentru backup și transferul datelor între simulator și telefon. Nu am adăugat încă sincronizare iCloud sau publicare în App Store.
