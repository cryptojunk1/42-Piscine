# 42 Lerntool – C00 Prototyp

Solo-Lern-Tool für das 42-Piscine-Selbststudium. Peer (Claude Code) und Exam sind bewusst getrennt.

## Schnellstart in WSL

```bash
# 1. Ins Tool-Verzeichnis wechseln (WSL-Pfad)
cd /mnt/c/Users/renem/OneDrive/42/42-lerntool

# 2. Peer-Session starten (Tutor-Modus)
cd peer && claude   # startet Claude Code mit CLAUDE.md-Regeln

# 3. Eine Übung prüfen (Norm + Tests)
bash scripts/check.sh ft_putchar

# 4. Ergebnis eintragen
bash scripts/update_progress.sh ft_putchar 100

# 5. Trophäenschrank anzeigen
bash scripts/trophy.sh

# 6. Exam starten (kein Tutor!)
bash exam/exam.sh
bash exam/exam.sh --time 30   # 30-Minuten-Quickcheck
```

## Workflow

```
PDF Subject → subjects/c00_exercises.json (Specs + Hints)
                     ↓
        peer/ (Claude Code + CLAUDE.md)     ← Tutor
                     ↓
        scripts/check.sh                    ← Norminette + Tests
                     ↓
        scripts/update_progress.sh          ← XP + Badges
                     ↓
        exam/exam.sh                        ← Prüfung (isoliert!)
                     ↓
        scripts/trophy.sh                   ← Trophäenschrank
```

## Dateien

| Datei | Beschreibung |
|---|---|
| `../progress.json` | Zentraler Status (OneDrive-Sync) |
| `subjects/c00_exercises.json` | 9 Übungen mit Specs, Tests & Hints |
| `peer/CLAUDE.md` | Tutor-Regeln (Hinweis-Stufen 1-4) |
| `scripts/check.sh` | Norminette + Compile + Tests |
| `scripts/update_progress.sh` | XP/Badges eintragen |
| `scripts/trophy.sh` | Trophäenschrank anzeigen |
| `exam/exam.sh` | Mini-Exam (eskalierend, Timer) |

## Dein Arbeitsordner

Lege deine .c-Dateien unter `peer/<übungsname>/` an:
```
peer/
├── CLAUDE.md
├── ft_putchar/
│   └── ft_putchar.c    ← dein Code
├── ft_print_alphabet/
│   └── ft_print_alphabet.c
...
```

Dann: `bash scripts/check.sh ft_putchar` – aus dem Tool-Root aufgerufen.
