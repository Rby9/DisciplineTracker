# Notificări personalizate — DisciplineTracker

## Pune modificările în proiectul tău

1. Închide proiectul din Xcode.
2. Dezarhivează ZIP-ul. Folderul primit conține proiectul actualizat și acest document.
3. În proiectul tău existent din Documents/DisciplineTracker, copiază folderul interior
   `DisciplineTracker` într-un loc separat, ca rezervă.
4. Copiază folderul interior `DisciplineTracker` din arhiva nouă peste folderul cu
   același nume din proiectul existent. În Finder alege **Replace / Înlocuiește**.
   Acesta este folderul cu Components, Models, Services, Utilities, Views și Assets.xcassets.
5. Copiază și folderul `Verification` din arhivă peste cel din proiectul existent.
6. Deschide **proiectul existent** `Documents/DisciplineTracker/DisciplineTracker.xcodeproj`.
7. Apasă Command + B, apoi Command + R.

Nu înlocui folderul exterior al proiectului și nu șterge aplicația din simulator sau
telefon. Folderul exterior conține istoricul Git și proiectul Xcode. Actualizarea
codului nu necesită ștergerea bazei de date. Proiectul folosește un folder sincronizat
cu Xcode, astfel încât fișierele Swift noi sunt incluse automat.

Dacă buildul sau deschiderea bazei de date dă o eroare, păstrează instalarea și
trimite mesajul complet înainte de alte modificări. Mediul în care au fost editate
fișierele nu are Xcode; compilarea și migrarea nativă trebuie confirmate pe Mac.

## Ce este implementat

- Notificări multiple: la început, 5/10/15/20/30/60 de minute înainte.
- Intervale personalizate în minute sau ore, până la 30 de zile, fără duplicate.
- Oprire pentru o activitate și comutator general în Profil.
- Setări implicite pentru activități și rutine noi, inițial 10 minute înainte.
- Previzualizarea datei și orei fiecărei notificări; cele trecute sunt marcate.
- Configurarea notificărilor în adăugare, editare și conversia într-o rutină.
- Editarea notificărilor unei rutine respectă data de aplicare și protejează
  activitățile editate individual. O schimbare doar a notificărilor este inclusă
  în numărul de activități actualizate din verificarea rutinei.
- Reprogramarea recalculează notificările și elimină amânarea suplimentară veche.
- Finalizarea, omiterea sau ștergerea elimină notificările viitoare aferente.
- Profil: stare permisiune, deschiderea setărilor, test peste 5 secunde și erori vizibile.
- Apăsarea notificării deschide activitatea, inclusiv după pornire de la zero.
- Acțiuni: „Finalizează activitatea” (poate cere deblocarea telefonului) și
  „Amintește-mi peste 10 minute”. Amânarea nu schimbă ora activității și
  se păstrează în baza de date. O nouă amânare înlocuiește amânarea suplimentară
  anterioară; notificările normale rămân programate.
- Textele noi au traduceri în română și engleză.

## Date existente

Activitățile și rutinele vechi păstrează notificările existente: 10 minute înainte,
la început și 15 minute după. La editare, ultima apare ca notificare existentă și
poate fi debifată. Nu o adăugăm implicit activităților noi.

Câmpurile noi din SwiftData sunt opționale. O listă absentă înseamnă comportamentul
vechi; o listă goală înseamnă notificări dezactivate. Preferințele din Profil nu
rescriu activitățile deja salvate. Conversia într-o rutină păstrează notificările
activității inițiale și aplică selecția doar repetărilor noi.

## Prima verificare în aplicație

1. Profil → Configurări notificări → Permite notificările, dacă este necesar.
2. Apasă „Testează notificările”. Trebuie să apară exemplul după aproximativ 5 secunde.
3. Adaugă o activitate peste 5 minute. Debifează 10 minute și adaugă intervalele
   personalizate 1 și 2 minute; bifează și „La început”.
4. Salvează, redeschide editarea și verifică păstrarea celor trei selecții.
5. Verifică notificările la momentele respective. Repetă apoi pe iPhone cu ecranul blocat.
6. Creează o altă activitate și finalizeaz-o înainte de reminder: acesta nu trebuie
   să mai apară. Verifică și omiterea, ștergerea și reprogramarea.
7. La o notificare, ține apăsat pentru acțiuni. Verifică amânarea cu 10 minute și
   faptul că ora activității nu se modifică.
8. Creează o rutină cu notificări; editează o singură zi, apoi modifică rutina.
   Ziua editată individual trebuie păstrată.

Lista completă de verificări este în `Verification/NOTIFICATIONS.md`.

## Limite practice

Aplicația programează notificări locale, fără server. Păstrează o coadă de cel mult
63 de notificări pentru activități, cu un loc rezervat testului. Cele mai apropiate
au prioritate. Dacă există mai multe, Profil afișează avertismentul și ultima dată
programată. Coada se reface când deschizi/revii în aplicație, modifici activități sau
folosești o acțiune din notificare. Deschide periodic aplicația pentru rutine lungi.
Nu există o reumplere garantată în fundal dacă aplicația nu este folosită.

Notificările deja programate pot fi livrate cu aplicația închisă. Focus, Rezumatul
programat, modul Silențios și permisiunile sistemului pot schimba afișarea/sunetul.
Datele activităților sunt instanțe Date; schimbarea fusului orar păstrează momentul
absolut al activității. Rutinele nu sunt reconstruite automat într-un fus nou.

După verificare, facem commit și continuăm cu instalarea pe iPhone. Acest ZIP nu
conține o aplicație iPhone compilată și nu publică nimic pe GitHub sau App Store.
