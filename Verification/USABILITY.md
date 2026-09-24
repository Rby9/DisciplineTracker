# Verificare — utilizare, căutare și backup

## Verificări automate

- Sintaxa fișierelor Swift.
- Formatarea modificărilor Git.
- Cataloagele de texte și traducerile în română și engleză.
- Exportul și importul datelor în format JSON.
- Prevenirea duplicatelor la import repetat.
- Respingerea fișierelor de backup invalide.
- Păstrarea modificărilor locale mai noi.

Rulează verificările din folderul principal al proiectului:

```bash
bash Verification/run-checks.sh
```

Testele folosesc baze de date temporare și nu modifică informațiile din aplicație.

## Verificări manuale

1. Duplică o activitate și verifică să primească un identificator nou.
2. Caută după titlu și notițe, apoi combină filtrele disponibile.
3. Exportă un backup și importă-l fără să apară duplicate.
4. Încearcă un fișier JSON deteriorat și verifică afișarea erorii.
5. Testează anularea selectorului de fișiere.
6. Verifică interfața în română și cu dimensiuni mari de text.
