# CineMatch AI

Vizuálny filmový poradca: opíšeš náladu prirodzeným textom, **Gemini AI** vráti 3–5 filmov s dôvodmi, náladovou paletou farieb a tagmi. Výsledky sa ukladajú do **Firebase Firestore** (backend / história).

## Technológie

| Vrstva | Technológia |
|--------|-------------|
| Frontend | Flutter (Web, Android, …) |
| AI (LLM runtime) | Google Gemini API (`google_generative_ai`) |
| Backend | Firebase Firestore |
| UI | Material 3, Google Fonts, Netflix-style karty |

## Požiadavky

- Flutter SDK 3.7+
- Firebase projekt `fir-test-project-2026` (už nakonfigurovaný v `lib/firebase_options.dart`)
- **Gemini API kľúč** z [Google AI Studio](https://aistudio.google.com/apikey)

## Spustenie

```bash
cd flutter_application_1
flutter pub get

# Web (odporúčané pre demo)
flutter run -d chrome --dart-define=GEMINI_API_KEY=TVOJ_GEMINI_API_KLUC

# Android
flutter run -d android --dart-define=GEMINI_API_KEY=TVOJ_GEMINI_API_KLUC
```

Voliteľne iný model:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=xxx --dart-define=GEMINI_MODEL=gemini-2.0-flash
```

> **Nepridávaj API kľúč do Gitu.** Používaj vždy `--dart-define`.

## Firebase Firestore

1. V [Firebase Console](https://console.firebase.google.com/) otvor projekt **fir-test-project-2026**.
2. **Build → Firestore Database → Create database** (test mode alebo production).
3. Nasadenie pravidiel (ak máš Firebase CLI):

```bash
firebase deploy --only firestore:rules
```

Súbor `firestore.rules` povoluje zápis do kolekcie `recommendations` (vhodné pre vývoj; pred odovzdaním môžeš spomenúť v reflexii, že v produkcii by bolo treba Auth).

## Štruktúra projektu

```
lib/
  config/          # API kľúč cez dart-define
  models/          # MovieRecommendation, JSON parsing
  services/        # GeminiService, FirestoreService
  screens/         # HomeScreen
  widgets/         # MovieCard, MoodPaletteBar, detail sheet
  main.dart
firestore.rules
docs/              # (voliteľne screenshoty pre zadanie)
```

## Hlavné funkcie

- Prirodzený popis nálady → AI odporúčania
- Karty filmov s **náladovou paletou** a tagmi
- Klik na film → detail, AI recenzia, odkaz na trailer (YouTube)
- Uloženie dotazu a výsledkov do Firestore

## Riešenie problémov

| Problém | Riešenie |
|---------|----------|
| `models/gemini-1.5-pro is not found` | Používaj `gemini-2.0-flash` (už nastavené v kóde) |
| Chýba API kľúč | Spusti s `--dart-define=GEMINI_API_KEY=...` |
| Firebase zápis zlyhá | Zapni Firestore v konzole a nasaď `firestore.rules` |
| Nesúlad Firebase projektov | `firebase_options.dart` musí sedieť s `google-services.json` |

## Reflexia LLM (šablóna pre zadanie)

V dokumentácii popíš napr.:

- **Vývoj:** Cursor / ChatGPT pri generovaní UI a integrácii Firebase
- **Runtime:** Gemini API pri odporúčaní filmov
- **Prínosy:** rýchle prototypovanie, JSON štruktúrovaný výstup
- **Limity:** halucinácie názvov filmov, potreba overiť API kľúč a model, Firestore pravidlá

## Licencia

Školský projekt – praktický projekt (LLM + Firebase).
