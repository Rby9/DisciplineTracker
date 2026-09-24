# Verificare — notificări personalizate

## Verificări efectuate

- Analiza sintaxei fișierelor Swift ale aplicației și verificărilor.
- Verificarea formatării modificărilor cu `git diff --check`.
- Validarea cataloagelor de texte și a traducerilor în română și engleză.
- Verificarea logicii pentru creare, editare, rutine, reprogramare și schimbarea stării.

## Verificări pe Mac

Din folderul principal al proiectului rulează:

```bash
bash Verification/run-checks.sh
```

Testele folosesc o bază de date temporară și nu modifică datele reale. Acestea verifică:

- migrarea activităților și rutinelor existente;
- păstrarea setărilor notificărilor;
- eliminarea intervalelor duplicate sau invalide;
- datele din jurul miezului nopții și schimbării orei;
- conversia unei activități într-o rutină;
- anularea notificărilor după finalizare;
- salvarea setărilor după repornire.

## Verificări pe iPhone

1. Creează o activitate cu mai multe notificări și verifică păstrarea lor după redeschidere.
2. Testează notificările cu aplicația deschisă, în fundal și cu telefonul blocat.
3. Finalizează, omite sau șterge o activitate înainte de notificare.
4. Reprogramează o activitate și verifică să nu apară notificarea veche.
5. Testează acțiunile „Finalizează” și „Amintește-mi peste 10 minute”.
6. Dezactivează și reactivează notificările din profil.
7. Verifică textele în română, dimensiunile mari de text și VoiceOver.

## Observații

Aplicația păstrează în coadă cel mult 63 de notificări pentru activități și un loc pentru notificarea de test. Evenimentele cele mai apropiate au prioritate. Coada se reface când aplicația este deschisă sau când activitățile sunt modificate.
