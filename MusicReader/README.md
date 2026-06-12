# 🎸 ChordScroller – Instrukcja konfiguracji Xcode

## Tworzenie projektu w Xcode

1. Otwórz Xcode → **Create New Project**
2. Wybierz **iOS → App**
3. Uzupełnij:
   - **Product Name**: `ChordScroller`
   - **Team**: Twój Apple ID (lub "None" do testów na symulatorze)
   - **Organization Identifier**: np. `com.twojename.chordscroller`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - Odznacz „Include Tests"
4. Kliknij **Next** i wybierz folder docelowy

## Dodawanie plików

1. W Xcode usuń domyślne pliki: `ContentView.swift` oraz `<NazwaAplikacji>App.swift`
2. Przeciągnij wszystkie pliki `.swift` z folderu `ChordScrollerApp/` do projektu w Xcode
3. Zaznacz **"Copy items if needed"** i dodaj do targetu

Pliki do dodania:
- `ChordScrollerApp.swift` (zastępuje domyślny App.swift)
- `SongStore.swift`
- `ContentView.swift`
- `SongDetailView.swift`
- `EditorView.swift`
- `TeleprompterView.swift`

## Uruchomienie

- **Symulator**: wybierz np. iPhone 15 i kliknij ▶
- **Urządzenie fizyczne**: podłącz iPhone, wybierz go jako target (wymagany Apple ID w Xcode → Settings → Accounts)

## Funkcje aplikacji

| Funkcja | Opis |
|---|---|
| 📋 Lista piosenek | Przegląd zapisanych piosenek z wyszukiwarką |
| ✏️ Edytor | Wpisywanie tekstu i akordów z podglądem |
| 🎸 Szybkie akordy | Pasek z popularnymi akordami do wstawiania jednym kliknięciem |
| 🎤 Teleprompter | Automatyczne przewijanie z regulowanym tempem |
| 🐢🐇 Slider tempa | Od 10 do 200 px/s, presety: Wolno/Średnio/Szybko |
| 🔡 Rozmiar czcionki | Od 12 do 48 pt |
| 🟠 Kolorowanie akordów | Akordy w `[nawiasach]` wyświetlają się na pomarańczowo |
| 💾 Zapis offline | Dane zapisywane lokalnie w UserDefaults (działa bez internetu) |

## Format tekstu

Akordy wpisuj w nawiasach kwadratowych bezpośrednio w tekście:

```
[Am]Kiedy pada [C]deszcz
[G]Myślę o [Em]Tobie
[F]Gdziekolwiek [C]jesteś
[G]Wróć do [Am]mnie
```

W trybie telepromptera akordy wyświetlają się pomarańczowym kolorem, a tekst białym.

## Sterowanie teleprompterem

- **Dotknij ekran** → pokaż/ukryj kontrolki
- **▶ Play** → start przewijania
- **⏸ Pause** → zatrzymaj
- **↺ Reset** → wróć na początek
- **Slider** → regulacja tempa w locie
- Kontrolki chowają się automatycznie po 4 sekundach od startu
