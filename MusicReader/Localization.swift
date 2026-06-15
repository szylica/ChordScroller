import Foundation

// MARK: - Obsługiwane języki

enum AppLanguage: String, Codable, CaseIterable {
    case system  = "system"
    case polish  = "pl"
    case english = "en"
    case german  = "de"
    case spanish = "es"
    case italian = "it"
    case french  = "fr"

    var displayName: String {
        switch self {
        case .system:  return "System"
        case .polish:  return "Polski"
        case .english: return "English"
        case .german:  return "Deutsch"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .french:  return "Français"
        }
    }

    var flag: String {
        switch self {
        case .system:  return "🌐"
        case .polish:  return "🇵🇱"
        case .english: return "🇬🇧"
        case .german:  return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .french:  return "🇫🇷"
        }
    }

    /// Rozwiązuje język systemowy na konkretny język
    static func resolve(_ language: AppLanguage) -> AppLanguage {
        guard language == .system else { return language }
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = String(preferred.prefix(2)).lowercased()
        switch code {
        case "pl": return .polish
        case "de": return .german
        case "es": return .spanish
        case "it": return .italian
        case "fr": return .french
        default:   return .english
        }
    }
}

// MARK: - Klucze tłumaczeń

enum L10n: String {

    // MARK: Ogólne
    case cancel
    case save
    case delete
    case edit
    case done
    case back
    case ok
    case error
    case loading
    case none

    // MARK: Nawigacja / Tytuły ekranów
    case library
    case settings
    case tuner
    case editor
    case newSong
    case editSong
    case importSong
    case teleprompter

    // MARK: Biblioteka (ContentView)
    case searchSongs
    case noSongs
    case noSongsTapToAdd
    case showAll
    case noResults
    case allTags
    case untitled

    // MARK: Szczegóły piosenki (SongDetailView)
    case tempo
    case fontSize
    case capo
    case playTeleprompter
    case chordsInSong
    case noDiagram
    case deleteSong
    case deleteSongConfirm
    case cannotUndo

    // MARK: Edytor (EditorView)
    case title
    case songNamePlaceholder
    case tags
    case newTagPlaceholder
    case existingTags
    case capoLabel
    case scrollSpeed
    case slow
    case medium
    case fast
    case veryFast
    case fontSizeLabel
    case small
    case large
    case textAndChords
    case chordsInBrackets
    case previewScrolling
    case quickInsert

    // MARK: Import (ImportView)
    case importSongTitle
    case supportedSites
    case pasteLink
    case urlPlaceholder
    case examples
    case importing
    case importButton
    case invalidURL
    case unsupportedSite
    case found
    case addToLibrary
    case tips
    case tipUGChords
    case tipHighRating
    case tipEditAfterImport

    // MARK: Import - błędy i komunikaty
    case importedSong
    case loadingError
    case noConnectionOrInvalidURL
    case songNotFoundWywrota
    case invalidJsonUG
    case chordsNotFoundUG
    case couldNotProcessSong
    case couldNotReadUG

    // MARK: Import - etykiety sekcji
    case sectionIntro
    case sectionVerse
    case sectionChorus
    case sectionBridge
    case sectionPrechorus
    case sectionOutro
    case sectionSolo
    case sectionInterlude
    case sectionInstrumental
    case sectionHook
    case sectionCoda
    case sectionBreak
    
    // MARK: Import - przykłady URL
    case exampleURLWywrota
    case exampleURLUG

    // MARK: Stroik (TunerView)
    case tunerTitle
    case playSound
    case orSelectString
    case noMicrophoneAccess
    case enableMicInSettings
    case openSettings
    case tapToUnlock
    case tuneString
    case tapStringToSelect
    case inTune

    // MARK: Ustawienia (SettingsView)
    case appearance
    case colorTheme
    case systemTheme
    case lightTheme
    case darkTheme
    case themeSystemDesc
    case themeLightDesc
    case themeDarkDesc
    case language
    case languageDesc
    case teleprompterSettings
    case onManualScroll
    case stopAutoScroll
    case continueAutoScroll
    case stopAutoScrollDesc
    case continueAutoScrollDesc
    case keepScreenOn
    case keepScreenOnDesc
    case information
    case appVersion
    case chordsInDatabase
    case resetSettings

    // MARK: Menu boczne (ToolPanelView)
    case tunerSubtitle
    case settingsSubtitle

    // MARK: Teleprompter
    case play
    case pause
    case reset
    
    // MARK: Teleprompter - dodatkowe
    case scrollHint
    case pausedToast

    // MARK: PDF Export
    case generatedIn
    
    // MARK: Przykładowa piosenka
    case exampleSongTitle
    case exampleSongContent
    case exampleTag

    // MARK: - Lokalizacja

    func localized(for language: AppLanguage = SettingsManager.shared.resolvedLanguage) -> String {
        let lang = AppLanguage.resolve(language)
        return Self.translations[lang]?[self]
            ?? Self.translations[.english]?[self]
            ?? "[\(rawValue)]"
    }
}

// MARK: - Słowniki tłumaczeń

extension L10n {

    static let translations: [AppLanguage: [L10n: String]] = [

        // ==================== POLSKI ====================
        .polish: [
            // Ogólne
            .cancel:  "Anuluj",
            .save:    "Zapisz",
            .delete:  "Usuń",
            .edit:    "Edytuj",
            .done:    "Gotowe",
            .back:    "Wróć",
            .ok:      "OK",
            .error:   "Błąd",
            .loading: "Ładowanie…",
            .none:    "Brak",

            // Nawigacja
            .library:      "Biblioteka",
            .settings:     "Ustawienia",
            .tuner:        "Stroik",
            .editor:       "Edytor",
            .newSong:      "Nowa piosenka",
            .editSong:     "Edytuj",
            .importSong:   "Importuj",
            .teleprompter: "Teleprompter",

            // Biblioteka
            .searchSongs:     "Szukaj piosenki…",
            .noSongs:         "Brak piosenek",
            .noSongsTapToAdd: "Dotknij + aby dodać pierwszą piosenkę",
            .showAll:         "Pokaż wszystkie",
            .noResults:       "Brak wyników",
            .allTags:         "Wszystkie",
            .untitled:        "Bez tytułu",

            // Szczegóły piosenki
            .tempo:            "Tempo",
            .fontSize:         "Czcionka",
            .capo:             "Kapodaster",
            .playTeleprompter: "Odtwórz teleprompter",
            .chordsInSong:     "Akordy w piosence",
            .noDiagram:        "Brak diagramu",
            .deleteSong:       "Usuń piosenkę?",
            .deleteSongConfirm: "Usuń",
            .cannotUndo:       "Tej operacji nie można cofnąć.",

            // Edytor
            .title:             "Tytuł",
            .songNamePlaceholder: "Nazwa piosenki…",
            .tags:              "Tagi",
            .newTagPlaceholder: "Nowy tag…",
            .existingTags:      "Istniejące tagi:",
            .capoLabel:         "Kapodaster",
            .scrollSpeed:       "Tempo przewijania",
            .slow:              "Wolno",
            .medium:            "Średnio",
            .fast:              "Szybko",
            .veryFast:          "Bardzo szybko",
            .fontSizeLabel:     "Rozmiar czcionki",
            .small:             "Małe",
            .large:             "Duże",
            .textAndChords:     "Tekst i akordy",
            .chordsInBrackets:  "Akordy w [nawiasach]",
            .previewScrolling:  "Podgląd przewijania",
            .quickInsert:       "Szybkie wstawianie",

            // Import
            .importSongTitle: "Importuj piosenkę",
            .supportedSites:  "Wspierane strony:",
            .pasteLink:       "Wklej link do piosenki",
            .urlPlaceholder:  "https://...",
            .examples:        "Przykłady:",
            .importing:       "Pobieranie…",
            .importButton:    "Importuj",
            .invalidURL:      "Podaj prawidłowy adres URL",
            .unsupportedSite: "Nieobsługiwana strona.\n\nWspierane:\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "Znaleziono!",
            .addToLibrary:    "Dodaj do biblioteki",
            .tips:            "Wskazówki",
            .tipUGChords:     "Na Ultimate Guitar wybierz wersję \"Chords\" (nie \"Tab\")",
            .tipHighRating:   "Wybieraj wersje z wysoką oceną ★★★★★",
            .tipEditAfterImport: "Po imporcie możesz edytować tekst i akordy",

            // Import - błędy
            .importedSong:           "Importowana piosenka",
            .loadingError:           "Błąd ładowania",
            .noConnectionOrInvalidURL: "Brak połączenia lub nieprawidłowy URL.",
            .songNotFoundWywrota:    "Nie znaleziono treści piosenki na Wywrocie.",
            .invalidJsonUG:          "Nieprawidłowy format danych z Ultimate Guitar",
            .chordsNotFoundUG:       "Nie znaleziono treści akordów.\nUpewnij się że link prowadzi do strony typu \"Chords\".",
            .couldNotProcessSong:    "Nie udało się przetworzyć treści piosenki.",
            .couldNotReadUG:         "Nie udało się odczytać danych z Ultimate Guitar.\nUpewnij się że link prowadzi do strony z akordami (Chords).",

            // Import - etykiety sekcji
            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Zwrotka",
            .sectionChorus:       "🎵 Refren",
            .sectionBridge:       "🌉 Bridge",
            .sectionPrechorus:    "🎶 Pre-refren",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interlude",
            .sectionInstrumental: "🎼 Instrumental",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Break",
            .exampleURLWywrota:   "spiewnik.wywrota.pl/piosenka/tytul",
            .exampleURLUG:        "tabs.ultimate-guitar.com/tab/artysta/piosenka-chords-123456",
            

            // Stroik
            .tunerTitle:          "Stroik",
            .playSound:           "Zagraj dźwięk…",
            .orSelectString:      "Lub wybierz strunę poniżej",
            .noMicrophoneAccess:  "Brak dostępu do mikrofonu",
            .enableMicInSettings: "Włącz mikrofon w Ustawieniach iPhone'a",
            .openSettings:        "Otwórz Ustawienia",
            .tapToUnlock:         "• dotknij strunę aby odblokować",
            .tuneString:        "Strój strunę",  // używane z funkcją
            .tapStringToSelect: "Dotknij strunę aby ją wybrać ręcznie",
            .inTune:            "✓ czysto",

            // Ustawienia
            .appearance:           "Wygląd",
            .colorTheme:           "Motyw kolorystyczny",
            .systemTheme:          "Systemowy",
            .lightTheme:           "Jasny",
            .darkTheme:            "Ciemny",
            .themeSystemDesc:      "Aplikacja automatycznie dostosuje się do ustawień systemowych.",
            .themeLightDesc:       "Jasny motyw z białym tłem.",
            .themeDarkDesc:        "Ciemny motyw z czarnym tłem (domyślny).",
            .language:             "Język",
            .languageDesc:         "Zmień język interfejsu aplikacji.",
            .teleprompterSettings: "Teleprompter",
            .onManualScroll:       "Po ręcznym przewinięciu:",
            .stopAutoScroll:       "Zatrzymaj auto-scroll",
            .continueAutoScroll:   "Kontynuuj auto-scroll",
            .stopAutoScrollDesc:   "Przewijanie automatyczne zatrzyma się gdy przewiniesz ręcznie. Naciśnij play aby wznowić.",
            .continueAutoScrollDesc: "Przewijanie automatyczne będzie kontynuowane od nowej pozycji po ręcznym przewinięciu.",
            .keepScreenOn:         "Nie wyłączaj ekranu",
            .keepScreenOnDesc:     "Ekran pozostanie włączony podczas telepromptera",
            .information:          "Informacje",
            .appVersion:           "Wersja aplikacji",
            .chordsInDatabase:     "Akordy w bazie",
            .resetSettings:        "Przywróć domyślne ustawienia",

            // Menu boczne
            .tunerSubtitle:    "Nastrojenie gitary",
            .settingsSubtitle: "Motyw, język, teleprompter",

            // Teleprompter
            .play:  "Start",
            .pause: "Pauza",
            .reset: "Reset",
            .scrollHint:   "Przewiń palcem w dowolnym momencie",
            .pausedToast:  "⏸ Zatrzymano",

            // PDF
            .generatedIn: "Wygenerowano w ChordScroller",
            
            // Przykładowa piosenka
            .exampleSongTitle:   "Przykładowa piosenka",
            .exampleSongContent: """
[G]Dzisiaj jest piękny [C]dzień
[D]Słońce świeci [G]znów
[Em]Wiatr gra na [Am]strunach drzew
[D]I śpiewa mi [G]w ucho

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Przykłady",
            
            
        ],

        // ==================== ENGLISH ====================
        .english: [
            .cancel:  "Cancel",
            .save:    "Save",
            .delete:  "Delete",
            .edit:    "Edit",
            .done:    "Done",
            .back:    "Back",
            .ok:      "OK",
            .error:   "Error",
            .loading: "Loading…",
            .none:    "None",

            .library:      "Library",
            .settings:     "Settings",
            .tuner:        "Tuner",
            .editor:       "Editor",
            .newSong:      "New Song",
            .editSong:     "Edit",
            .importSong:   "Import",
            .teleprompter: "Teleprompter",

            .searchSongs:     "Search songs…",
            .noSongs:         "No songs",
            .noSongsTapToAdd: "Tap + to add your first song",
            .showAll:         "Show all",
            .noResults:       "No results",
            .allTags:         "All",
            .untitled:        "Untitled",

            .tempo:            "Tempo",
            .fontSize:         "Font",
            .capo:             "Capo",
            .playTeleprompter: "Play teleprompter",
            .chordsInSong:     "Chords in song",
            .noDiagram:        "No diagram",
            .deleteSong:       "Delete song?",
            .deleteSongConfirm: "Delete",
            .cannotUndo:       "This action cannot be undone.",

            .title:             "Title",
            .songNamePlaceholder: "Song name…",
            .tags:              "Tags",
            .newTagPlaceholder: "New tag…",
            .existingTags:      "Existing tags:",
            .capoLabel:         "Capo",
            .scrollSpeed:       "Scroll speed",
            .slow:              "Slow",
            .medium:            "Medium",
            .fast:              "Fast",
            .veryFast:          "Very fast",
            .fontSizeLabel:     "Font size",
            .small:             "Small",
            .large:             "Large",
            .textAndChords:     "Lyrics & chords",
            .chordsInBrackets:  "Chords in [brackets]",
            .previewScrolling:  "Preview scrolling",
            .quickInsert:       "Quick insert",

            .importSongTitle: "Import song",
            .supportedSites:  "Supported sites:",
            .pasteLink:       "Paste song link",
            .urlPlaceholder:  "https://...",
            .examples:        "Examples:",
            .importing:       "Importing…",
            .importButton:    "Import",
            .invalidURL:      "Enter a valid URL",
            .unsupportedSite: "Unsupported site.\n\nSupported:\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "Found!",
            .addToLibrary:    "Add to library",
            .tips:            "Tips",
            .tipUGChords:     "On Ultimate Guitar, choose \"Chords\" version (not \"Tab\")",
            .tipHighRating:   "Choose versions with high rating ★★★★★",
            .tipEditAfterImport: "You can edit lyrics and chords after import",

            .importedSong:           "Imported song",
            .loadingError:           "Loading error",
            .noConnectionOrInvalidURL: "No connection or invalid URL.",
            .songNotFoundWywrota:    "Song content not found on Wywrota.",
            .invalidJsonUG:          "Invalid data format from Ultimate Guitar",
            .chordsNotFoundUG:       "Chord content not found.\nMake sure the link leads to a \"Chords\" page.",
            .couldNotProcessSong:    "Could not process song content.",
            .couldNotReadUG:         "Could not read data from Ultimate Guitar.\nMake sure the link leads to a Chords page.",

            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Verse",
            .sectionChorus:       "🎵 Chorus",
            .sectionBridge:       "🌉 Bridge",
            .sectionPrechorus:    "🎶 Pre-Chorus",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interlude",
            .sectionInstrumental: "🎼 Instrumental",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Break",
            .exampleURLWywrota:   "spiewnik.wywrota.pl/song/title",
            .exampleURLUG:        "tabs.ultimate-guitar.com/tab/artist/song-chords-123456",

            .tunerTitle:          "Tuner",
            .playSound:           "Play a note…",
            .orSelectString:      "Or select a string below",
            .noMicrophoneAccess:  "No microphone access",
            .enableMicInSettings: "Enable microphone in iPhone Settings",
            .openSettings:        "Open Settings",
            .tapToUnlock:         "• tap string to unlock",
            .tuneString:          "Tune string",
            .tapStringToSelect:   "Tap a string to select it manually",
            .inTune:              "✓ in tune",

            .appearance:           "Appearance",
            .colorTheme:           "Color theme",
            .systemTheme:          "System",
            .lightTheme:           "Light",
            .darkTheme:            "Dark",
            .themeSystemDesc:      "App will automatically adapt to system settings.",
            .themeLightDesc:       "Light theme with white background.",
            .themeDarkDesc:        "Dark theme with black background (default).",
            .language:             "Language",
            .languageDesc:         "Change app interface language.",
            .teleprompterSettings: "Teleprompter",
            .onManualScroll:       "On manual scroll:",
            .stopAutoScroll:       "Stop auto-scroll",
            .continueAutoScroll:   "Continue auto-scroll",
            .stopAutoScrollDesc:   "Auto-scroll will stop when you scroll manually. Press play to resume.",
            .continueAutoScrollDesc: "Auto-scroll will continue from new position after manual scroll.",
            .keepScreenOn:         "Keep screen on",
            .keepScreenOnDesc:     "Screen will stay on during teleprompter",
            .information:          "Information",
            .appVersion:           "App version",
            .chordsInDatabase:     "Chords in database",
            .resetSettings:        "Reset to defaults",

            .tunerSubtitle:    "Tune your guitar",
            .settingsSubtitle: "Theme, language, teleprompter",

            .play:  "Play",
            .pause: "Pause",
            .reset: "Reset",
            .scrollHint:   "Scroll with finger at any time",
            .pausedToast:  "⏸ Paused",

            .generatedIn: "Generated in ChordScroller",
            
            // Example song
            .exampleSongTitle:   "Example Song",
            .exampleSongContent: """
[G]Today is a beautiful [C]day
[D]The sun is shining [G]again
[Em]Wind plays on [Am]tree strings
[D]And sings in [G]my ear

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Examples",
        ],

        // ==================== GERMAN ====================
        .german: [
            .cancel:  "Abbrechen",
            .save:    "Speichern",
            .delete:  "Löschen",
            .edit:    "Bearbeiten",
            .done:    "Fertig",
            .back:    "Zurück",
            .ok:      "OK",
            .error:   "Fehler",
            .loading: "Laden…",
            .none:    "Keine",

            .library:      "Bibliothek",
            .settings:     "Einstellungen",
            .tuner:        "Stimmgerät",
            .editor:       "Editor",
            .newSong:      "Neues Lied",
            .editSong:     "Bearbeiten",
            .importSong:   "Importieren",
            .teleprompter: "Teleprompter",

            .searchSongs:     "Lieder suchen…",
            .noSongs:         "Keine Lieder",
            .noSongsTapToAdd: "Tippe + um dein erstes Lied hinzuzufügen",
            .showAll:         "Alle anzeigen",
            .noResults:       "Keine Ergebnisse",
            .allTags:         "Alle",
            .untitled:        "Ohne Titel",

            .tempo:            "Tempo",
            .fontSize:         "Schrift",
            .capo:             "Kapodaster",
            .playTeleprompter: "Teleprompter starten",
            .chordsInSong:     "Akkorde im Lied",
            .noDiagram:        "Kein Diagramm",
            .deleteSong:       "Lied löschen?",
            .deleteSongConfirm: "Löschen",
            .cannotUndo:       "Diese Aktion kann nicht rückgängig gemacht werden.",

            .title:             "Titel",
            .songNamePlaceholder: "Liedname…",
            .tags:              "Tags",
            .newTagPlaceholder: "Neuer Tag…",
            .existingTags:      "Vorhandene Tags:",
            .capoLabel:         "Kapodaster",
            .scrollSpeed:       "Scrollgeschwindigkeit",
            .slow:              "Langsam",
            .medium:            "Mittel",
            .fast:              "Schnell",
            .veryFast:          "Sehr schnell",
            .fontSizeLabel:     "Schriftgröße",
            .small:             "Klein",
            .large:             "Groß",
            .textAndChords:     "Text & Akkorde",
            .chordsInBrackets:  "Akkorde in [Klammern]",
            .previewScrolling:  "Scrollen Vorschau",
            .quickInsert:       "Schnelleingabe",

            .importSongTitle: "Lied importieren",
            .supportedSites:  "Unterstützte Seiten:",
            .pasteLink:       "Link zum Lied einfügen",
            .urlPlaceholder:  "https://...",
            .examples:        "Beispiele:",
            .importing:       "Importieren…",
            .importButton:    "Importieren",
            .invalidURL:      "Gültige URL eingeben",
            .unsupportedSite: "Nicht unterstützte Seite.\n\nUnterstützt:\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "Gefunden!",
            .addToLibrary:    "Zur Bibliothek hinzufügen",
            .tips:            "Tipps",
            .tipUGChords:     "Wähle auf Ultimate Guitar die \"Chords\" Version (nicht \"Tab\")",
            .tipHighRating:   "Wähle Versionen mit hoher Bewertung ★★★★★",
            .tipEditAfterImport: "Du kannst Text und Akkorde nach dem Import bearbeiten",

            .importedSong:           "Importiertes Lied",
            .loadingError:           "Ladefehler",
            .noConnectionOrInvalidURL: "Keine Verbindung oder ungültige URL.",
            .songNotFoundWywrota:    "Liedinhalt auf Wywrota nicht gefunden.",
            .invalidJsonUG:          "Ungültiges Datenformat von Ultimate Guitar",
            .chordsNotFoundUG:       "Akkordinhalt nicht gefunden.\nStelle sicher, dass der Link zu einer \"Chords\"-Seite führt.",
            .couldNotProcessSong:    "Liedinhalt konnte nicht verarbeitet werden.",
            .couldNotReadUG:         "Daten von Ultimate Guitar konnten nicht gelesen werden.\nStelle sicher, dass der Link zu einer Chords-Seite führt.",

            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Strophe",
            .sectionChorus:       "🎵 Refrain",
            .sectionBridge:       "🌉 Bridge",
            .sectionPrechorus:    "🎶 Pre-Chorus",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interlude",
            .sectionInstrumental: "🎼 Instrumental",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Break",
            .exampleURLWywrota:   "spiewnik.wywrota.pl/lied/titel",
            .exampleURLUG:        "tabs.ultimate-guitar.com/tab/kuenstler/lied-chords-123456",

            .tunerTitle:          "Stimmgerät",
            .playSound:           "Spiele einen Ton…",
            .orSelectString:      "Oder wähle eine Saite unten",
            .noMicrophoneAccess:  "Kein Mikrofonzugriff",
            .enableMicInSettings: "Aktiviere das Mikrofon in den iPhone-Einstellungen",
            .openSettings:        "Einstellungen öffnen",
            .tapToUnlock:         "• Saite antippen zum Entsperren",
            .tuneString:          "Stimme Saite",
            .tapStringToSelect:   "Tippe auf eine Saite um sie auszuwählen",
            .inTune:              "✓ gestimmt",

            .appearance:           "Aussehen",
            .colorTheme:           "Farbschema",
            .systemTheme:          "System",
            .lightTheme:           "Hell",
            .darkTheme:            "Dunkel",
            .themeSystemDesc:      "App passt sich automatisch an Systemeinstellungen an.",
            .themeLightDesc:       "Helles Design mit weißem Hintergrund.",
            .themeDarkDesc:        "Dunkles Design mit schwarzem Hintergrund (Standard).",
            .language:             "Sprache",
            .languageDesc:         "App-Sprache ändern.",
            .teleprompterSettings: "Teleprompter",
            .onManualScroll:       "Bei manuellem Scrollen:",
            .stopAutoScroll:       "Auto-Scroll stoppen",
            .continueAutoScroll:   "Auto-Scroll fortsetzen",
            .stopAutoScrollDesc:   "Auto-Scroll stoppt bei manuellem Scrollen. Drücke Play zum Fortsetzen.",
            .continueAutoScrollDesc: "Auto-Scroll wird von neuer Position nach manuellem Scrollen fortgesetzt.",
            .keepScreenOn:         "Bildschirm anlassen",
            .keepScreenOnDesc:     "Bildschirm bleibt während Teleprompter an",
            .information:          "Information",
            .appVersion:           "App-Version",
            .chordsInDatabase:     "Akkorde in Datenbank",
            .resetSettings:        "Auf Standard zurücksetzen",

            .tunerSubtitle:    "Gitarre stimmen",
            .settingsSubtitle: "Design, Sprache, Teleprompter",

            .play:  "Start",
            .pause: "Pause",
            .reset: "Reset",
            .scrollHint:   "Jederzeit mit dem Finger scrollen",
            .pausedToast:  "⏸ Angehalten",

            .generatedIn: "Erstellt mit ChordScroller",
            
            // Beispiellied
            .exampleSongTitle:   "Beispiellied",
            .exampleSongContent: """
[G]Heute ist ein schöner [C]Tag
[D]Die Sonne scheint [G]wieder
[Em]Der Wind spielt auf [Am]Baumsaiten
[D]Und singt mir [G]ins Ohr

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Beispiele",
        ],

        // ==================== SPANISH ====================
        .spanish: [
            .cancel:  "Cancelar",
            .save:    "Guardar",
            .delete:  "Eliminar",
            .edit:    "Editar",
            .done:    "Listo",
            .back:    "Volver",
            .ok:      "OK",
            .error:   "Error",
            .loading: "Cargando…",
            .none:    "Ninguno",

            .library:      "Biblioteca",
            .settings:     "Ajustes",
            .tuner:        "Afinador",
            .editor:       "Editor",
            .newSong:      "Nueva canción",
            .editSong:     "Editar",
            .importSong:   "Importar",
            .teleprompter: "Teleprompter",
            
            

            .searchSongs:     "Buscar canciones…",
            .noSongs:         "Sin canciones",
            .noSongsTapToAdd: "Toca + para añadir tu primera canción",
            .showAll:         "Mostrar todo",
            .noResults:       "Sin resultados",
            .allTags:         "Todas",
            .untitled:        "Sin título",

            .tempo:            "Tempo",
            .fontSize:         "Fuente",
            .capo:             "Cejilla",
            .playTeleprompter: "Iniciar teleprompter",
            .chordsInSong:     "Acordes en canción",
            .noDiagram:        "Sin diagrama",
            .deleteSong:       "¿Eliminar canción?",
            .deleteSongConfirm: "Eliminar",
            .cannotUndo:       "Esta acción no se puede deshacer.",

            .title:             "Título",
            .songNamePlaceholder: "Nombre de canción…",
            .tags:              "Etiquetas",
            .newTagPlaceholder: "Nueva etiqueta…",
            .existingTags:      "Etiquetas existentes:",
            .capoLabel:         "Cejilla",
            .scrollSpeed:       "Velocidad de scroll",
            .slow:              "Lento",
            .medium:            "Medio",
            .fast:              "Rápido",
            .veryFast:          "Muy rápido",
            .fontSizeLabel:     "Tamaño de fuente",
            .small:             "Pequeño",
            .large:             "Grande",
            .textAndChords:     "Letra y acordes",
            .chordsInBrackets:  "Acordes en [corchetes]",
            .previewScrolling:  "Vista previa",
            .quickInsert:       "Inserción rápida",

            .importSongTitle: "Importar canción",
            .supportedSites:  "Sitios compatibles:",
            .pasteLink:       "Pega el enlace de la canción",
            .urlPlaceholder:  "https://...",
            .examples:        "Ejemplos:",
            .importing:       "Importando…",
            .importButton:    "Importar",
            .invalidURL:      "Introduce una URL válida",
            .unsupportedSite: "Sitio no compatible.\n\nCompatibles:\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "¡Encontrado!",
            .addToLibrary:    "Añadir a biblioteca",
            .tips:            "Consejos",
            .tipUGChords:     "En Ultimate Guitar, elige versión \"Chords\" (no \"Tab\")",
            .tipHighRating:   "Elige versiones con alta puntuación ★★★★★",
            .tipEditAfterImport: "Puedes editar letra y acordes después de importar",

            .importedSong:           "Canción importada",
            .loadingError:           "Error de carga",
            .noConnectionOrInvalidURL: "Sin conexión o URL inválida.",
            .songNotFoundWywrota:    "Contenido de la canción no encontrado en Wywrota.",
            .invalidJsonUG:          "Formato de datos inválido de Ultimate Guitar",
            .chordsNotFoundUG:       "Contenido de acordes no encontrado.\nAsegúrate de que el enlace lleve a una página \"Chords\".",
            .couldNotProcessSong:    "No se pudo procesar el contenido de la canción.",
            .couldNotReadUG:         "No se pudieron leer los datos de Ultimate Guitar.\nAsegúrate de que el enlace lleve a una página de acordes (Chords).",

            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Estrofa",
            .sectionChorus:       "🎵 Estribillo",
            .sectionBridge:       "🌉 Puente",
            .sectionPrechorus:    "🎶 Pre-estribillo",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interludio",
            .sectionInstrumental: "🎼 Instrumental",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Pausa",
            .exampleURLWywrota:   "spiewnik.wywrota.pl/cancion/titulo",
            .exampleURLUG:        "tabs.ultimate-guitar.com/tab/artista/cancion-chords-123456",

            .tunerTitle:          "Afinador",
            .playSound:           "Toca una nota…",
            .orSelectString:      "O selecciona una cuerda abajo",
            .noMicrophoneAccess:  "Sin acceso al micrófono",
            .enableMicInSettings: "Activa el micrófono en Ajustes del iPhone",
            .openSettings:        "Abrir Ajustes",
            .tapToUnlock:         "• toca cuerda para desbloquear",
            .tuneString:          "Afina la cuerda",
            .tapStringToSelect:   "Toca una cuerda para seleccionarla",
            .inTune:              "✓ afinado",

            .appearance:           "Apariencia",
            .colorTheme:           "Tema de color",
            .systemTheme:          "Sistema",
            .lightTheme:           "Claro",
            .darkTheme:            "Oscuro",
            .themeSystemDesc:      "La app se adaptará automáticamente a los ajustes del sistema.",
            .themeLightDesc:       "Tema claro con fondo blanco.",
            .themeDarkDesc:        "Tema oscuro con fondo negro (predeterminado).",
            .language:             "Idioma",
            .languageDesc:         "Cambiar idioma de la interfaz.",
            .teleprompterSettings: "Teleprompter",
            .onManualScroll:       "Al hacer scroll manual:",
            .stopAutoScroll:       "Detener auto-scroll",
            .continueAutoScroll:   "Continuar auto-scroll",
            .stopAutoScrollDesc:   "El auto-scroll se detendrá al hacer scroll manual. Pulsa play para reanudar.",
            .continueAutoScrollDesc: "El auto-scroll continuará desde la nueva posición después del scroll manual.",
            .keepScreenOn:         "Mantener pantalla encendida",
            .keepScreenOnDesc:     "La pantalla permanecerá encendida durante el teleprompter",
            .information:          "Información",
            .appVersion:           "Versión de la app",
            .chordsInDatabase:     "Acordes en base de datos",
            .resetSettings:        "Restablecer ajustes",

            .tunerSubtitle:    "Afina tu guitarra",
            .settingsSubtitle: "Tema, idioma, teleprompter",

            .play:  "Iniciar",
            .pause: "Pausa",
            .reset: "Reiniciar",
            .scrollHint:   "Desliza con el dedo en cualquier momento",
            .pausedToast:  "⏸ Pausado",

            .generatedIn: "Generado en ChordScroller",
            
            // Canción de ejemplo
            .exampleSongTitle:   "Canción de ejemplo",
            .exampleSongContent: """
[G]Hoy es un hermoso [C]día
[D]El sol brilla [G]otra vez
[Em]El viento toca en [Am]cuerdas de árboles
[D]Y me canta [G]al oído

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Ejemplos",
        ],
        
        // ==================== ITALIAN ====================
        .italian: [
            // Ogólne
            .cancel:  "Annulla",
            .save:    "Salva",
            .delete:  "Elimina",
            .edit:    "Modifica",
            .done:    "Fatto",
            .back:    "Indietro",
            .ok:      "OK",
            .error:   "Errore",
            .loading: "Caricamento…",
            .none:    "Nessuno",

            // Nawigacja
            .library:      "Libreria",
            .settings:     "Impostazioni",
            .tuner:        "Accordatore",
            .editor:       "Editor",
            .newSong:      "Nuova canzone",
            .editSong:     "Modifica",
            .importSong:   "Importa",
            .teleprompter: "Teleprompter",

            // Biblioteka
            .searchSongs:     "Cerca canzoni…",
            .noSongs:         "Nessuna canzone",
            .noSongsTapToAdd: "Tocca + per aggiungere la prima canzone",
            .showAll:         "Mostra tutto",
            .noResults:       "Nessun risultato",
            .allTags:         "Tutti",
            .untitled:        "Senza titolo",

            // Szczegóły piosenki
            .tempo:            "Tempo",
            .fontSize:         "Carattere",
            .capo:             "Capotasto",
            .playTeleprompter: "Avvia teleprompter",
            .chordsInSong:     "Accordi nella canzone",
            .noDiagram:        "Nessun diagramma",
            .deleteSong:       "Eliminare la canzone?",
            .deleteSongConfirm: "Elimina",
            .cannotUndo:       "Questa azione non può essere annullata.",

            // Edytor
            .title:             "Titolo",
            .songNamePlaceholder: "Nome della canzone…",
            .tags:              "Tag",
            .newTagPlaceholder: "Nuovo tag…",
            .existingTags:      "Tag esistenti:",
            .capoLabel:         "Capotasto",
            .scrollSpeed:       "Velocità di scorrimento",
            .slow:              "Lento",
            .medium:            "Medio",
            .fast:              "Veloce",
            .veryFast:          "Molto veloce",
            .fontSizeLabel:     "Dimensione carattere",
            .small:             "Piccolo",
            .large:             "Grande",
            .textAndChords:     "Testo e accordi",
            .chordsInBrackets:  "Accordi in [parentesi]",
            .previewScrolling:  "Anteprima scorrimento",
            .quickInsert:       "Inserimento rapido",

            // Import
            .importSongTitle: "Importa canzone",
            .supportedSites:  "Siti supportati:",
            .pasteLink:       "Incolla il link della canzone",
            .urlPlaceholder:  "https://...",
            .examples:        "Esempi:",
            .importing:       "Importazione…",
            .importButton:    "Importa",
            .invalidURL:      "Inserisci un URL valido",
            .unsupportedSite: "Sito non supportato.\n\nSupportati:\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "Trovato!",
            .addToLibrary:    "Aggiungi alla libreria",
            .tips:            "Suggerimenti",
            .tipUGChords:     "Su Ultimate Guitar, scegli la versione \"Chords\" (non \"Tab\")",
            .tipHighRating:   "Scegli versioni con valutazione alta ★★★★★",
            .tipEditAfterImport: "Puoi modificare testo e accordi dopo l'importazione",

            // Import - błędy
            .importedSong:           "Canzone importata",
            .loadingError:           "Errore di caricamento",
            .noConnectionOrInvalidURL: "Nessuna connessione o URL non valido.",
            .songNotFoundWywrota:    "Contenuto della canzone non trovato su Wywrota.",
            .invalidJsonUG:          "Formato dati non valido da Ultimate Guitar",
            .chordsNotFoundUG:       "Contenuto degli accordi non trovato.\nAssicurati che il link porti a una pagina \"Chords\".",
            .couldNotProcessSong:    "Impossibile elaborare il contenuto della canzone.",
            .couldNotReadUG:         "Impossibile leggere i dati da Ultimate Guitar.\nAssicurati che il link porti a una pagina Chords.",

            // Import - etykiety sekcji
            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Strofa",
            .sectionChorus:       "🎵 Ritornello",
            .sectionBridge:       "🌉 Bridge",
            .sectionPrechorus:    "🎶 Pre-Ritornello",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interlude",
            .sectionInstrumental: "🎼 Strumentale",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Pausa",

            // Stroik
            .tunerTitle:          "Accordatore",
            .playSound:           "Suona una nota…",
            .orSelectString:      "Oppure seleziona una corda sotto",
            .noMicrophoneAccess:  "Nessun accesso al microfono",
            .enableMicInSettings: "Abilita il microfono nelle Impostazioni iPhone",
            .openSettings:        "Apri Impostazioni",
            .tapToUnlock:         "• tocca la corda per sbloccare",

            // Ustawienia
            .appearance:           "Aspetto",
            .colorTheme:           "Tema colori",
            .systemTheme:          "Sistema",
            .lightTheme:           "Chiaro",
            .darkTheme:            "Scuro",
            .themeSystemDesc:      "L'app si adatterà automaticamente alle impostazioni di sistema.",
            .themeLightDesc:       "Tema chiaro con sfondo bianco.",
            .themeDarkDesc:        "Tema scuro con sfondo nero (predefinito).",
            .language:             "Lingua",
            .languageDesc:         "Cambia la lingua dell'interfaccia.",
            .teleprompterSettings: "Teleprompter",
            .onManualScroll:       "Allo scorrimento manuale:",
            .stopAutoScroll:       "Ferma auto-scroll",
            .continueAutoScroll:   "Continua auto-scroll",
            .stopAutoScrollDesc:   "L'auto-scroll si fermerà quando scorri manualmente. Premi play per riprendere.",
            .continueAutoScrollDesc: "L'auto-scroll continuerà dalla nuova posizione dopo lo scorrimento manuale.",
            .keepScreenOn:         "Mantieni schermo acceso",
            .keepScreenOnDesc:     "Lo schermo rimarrà acceso durante il teleprompter",
            .information:          "Informazioni",
            .appVersion:           "Versione app",
            .chordsInDatabase:     "Accordi nel database",
            .resetSettings:        "Ripristina impostazioni",

            // Menu boczne
            .tunerSubtitle:    "Accorda la chitarra",
            .settingsSubtitle: "Tema, lingua, teleprompter",

            // Teleprompter
            .play:  "Avvia",
            .pause: "Pausa",
            .reset: "Reset",

            // PDF
            .generatedIn: "Generato in ChordScroller",
            
            // Teleprompter - dodatkowe
            .scrollHint:   "Scorri con il dito in qualsiasi momento",
            .pausedToast:  "⏸ In pausa",
            
            // Stroik - dodatkowe
            .tapStringToSelect: "Tocca una corda per selezionarla manualmente",
            .inTune:            "✓ accordato",
            
            // Import - przykłady URL
            .exampleURLWywrota: "spiewnik.wywrota.pl/canzone/titolo",
            .exampleURLUG:      "tabs.ultimate-guitar.com/tab/artista/canzone-chords-123456",
            
            
            // Canzone di esempio
            .exampleSongTitle:   "Canzone di esempio",
            .exampleSongContent: """
[G]Oggi è una bella [C]giornata
[D]Il sole splende [G]di nuovo
[Em]Il vento suona sulle [Am]corde degli alberi
[D]E mi canta [G]all'orecchio

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Esempi",
        ],
        
        // ==================== FRENCH ====================
        .french: [
            // Ogólne
            .cancel:  "Annuler",
            .save:    "Enregistrer",
            .delete:  "Supprimer",
            .edit:    "Modifier",
            .done:    "Terminé",
            .back:    "Retour",
            .ok:      "OK",
            .error:   "Erreur",
            .loading: "Chargement…",
            .none:    "Aucun",

            // Nawigacja
            .library:      "Bibliothèque",
            .settings:     "Paramètres",
            .tuner:        "Accordeur",
            .editor:       "Éditeur",
            .newSong:      "Nouvelle chanson",
            .editSong:     "Modifier",
            .importSong:   "Importer",
            .teleprompter: "Téléprompter",

            // Biblioteka
            .searchSongs:     "Rechercher des chansons…",
            .noSongs:         "Aucune chanson",
            .noSongsTapToAdd: "Appuyez sur + pour ajouter votre première chanson",
            .showAll:         "Tout afficher",
            .noResults:       "Aucun résultat",
            .allTags:         "Tous",
            .untitled:        "Sans titre",

            // Szczegóły piosenki
            .tempo:            "Tempo",
            .fontSize:         "Police",
            .capo:             "Capodastre",
            .playTeleprompter: "Lancer le téléprompter",
            .chordsInSong:     "Accords dans la chanson",
            .noDiagram:        "Pas de diagramme",
            .deleteSong:       "Supprimer la chanson ?",
            .deleteSongConfirm: "Supprimer",
            .cannotUndo:       "Cette action ne peut pas être annulée.",

            // Edytor
            .title:             "Titre",
            .songNamePlaceholder: "Nom de la chanson…",
            .tags:              "Tags",
            .newTagPlaceholder: "Nouveau tag…",
            .existingTags:      "Tags existants :",
            .capoLabel:         "Capodastre",
            .scrollSpeed:       "Vitesse de défilement",
            .slow:              "Lent",
            .medium:            "Moyen",
            .fast:              "Rapide",
            .veryFast:          "Très rapide",
            .fontSizeLabel:     "Taille de police",
            .small:             "Petit",
            .large:             "Grand",
            .textAndChords:     "Paroles et accords",
            .chordsInBrackets:  "Accords entre [crochets]",
            .previewScrolling:  "Aperçu du défilement",
            .quickInsert:       "Insertion rapide",

            // Import
            .importSongTitle: "Importer une chanson",
            .supportedSites:  "Sites supportés :",
            .pasteLink:       "Collez le lien de la chanson",
            .urlPlaceholder:  "https://...",
            .examples:        "Exemples :",
            .importing:       "Importation…",
            .importButton:    "Importer",
            .invalidURL:      "Entrez une URL valide",
            .unsupportedSite: "Site non supporté.\n\nSupportés :\n• spiewnik.wywrota.pl\n• tabs.ultimate-guitar.com",
            .found:           "Trouvé !",
            .addToLibrary:    "Ajouter à la bibliothèque",
            .tips:            "Conseils",
            .tipUGChords:     "Sur Ultimate Guitar, choisissez la version \"Chords\" (pas \"Tab\")",
            .tipHighRating:   "Choisissez les versions bien notées ★★★★★",
            .tipEditAfterImport: "Vous pouvez modifier les paroles et accords après l'importation",

            // Import - błędy
            .importedSong:           "Chanson importée",
            .loadingError:           "Erreur de chargement",
            .noConnectionOrInvalidURL: "Pas de connexion ou URL invalide.",
            .songNotFoundWywrota:    "Contenu de la chanson non trouvé sur Wywrota.",
            .invalidJsonUG:          "Format de données invalide depuis Ultimate Guitar",
            .chordsNotFoundUG:       "Contenu des accords non trouvé.\nAssurez-vous que le lien mène à une page \"Chords\".",
            .couldNotProcessSong:    "Impossible de traiter le contenu de la chanson.",
            .couldNotReadUG:         "Impossible de lire les données depuis Ultimate Guitar.\nAssurez-vous que le lien mène à une page Chords.",

            // Import - etykiety sekcji
            .sectionIntro:        "🎸 Intro",
            .sectionVerse:        "📝 Couplet",
            .sectionChorus:       "🎵 Refrain",
            .sectionBridge:       "🌉 Pont",
            .sectionPrechorus:    "🎶 Pré-refrain",
            .sectionOutro:        "🔚 Outro",
            .sectionSolo:         "🎸 Solo",
            .sectionInterlude:    "🎹 Interlude",
            .sectionInstrumental: "🎼 Instrumental",
            .sectionHook:         "🪝 Hook",
            .sectionCoda:         "🔄 Coda",
            .sectionBreak:        "⏸ Pause",

            // Stroik
            .tunerTitle:          "Accordeur",
            .playSound:           "Jouez une note…",
            .orSelectString:      "Ou sélectionnez une corde ci-dessous",
            .noMicrophoneAccess:  "Pas d'accès au microphone",
            .enableMicInSettings: "Activez le microphone dans les Réglages iPhone",
            .openSettings:        "Ouvrir les Réglages",
            .tapToUnlock:         "• touchez la corde pour déverrouiller",

            // Ustawienia
            .appearance:           "Apparence",
            .colorTheme:           "Thème de couleur",
            .systemTheme:          "Système",
            .lightTheme:           "Clair",
            .darkTheme:            "Sombre",
            .themeSystemDesc:      "L'app s'adaptera automatiquement aux réglages système.",
            .themeLightDesc:       "Thème clair avec fond blanc.",
            .themeDarkDesc:        "Thème sombre avec fond noir (par défaut).",
            .language:             "Langue",
            .languageDesc:         "Changer la langue de l'interface.",
            .teleprompterSettings: "Téléprompter",
            .onManualScroll:       "Lors du défilement manuel :",
            .stopAutoScroll:       "Arrêter le défilement auto",
            .continueAutoScroll:   "Continuer le défilement auto",
            .stopAutoScrollDesc:   "Le défilement auto s'arrêtera lors du défilement manuel. Appuyez sur lecture pour reprendre.",
            .continueAutoScrollDesc: "Le défilement auto continuera depuis la nouvelle position après le défilement manuel.",
            .keepScreenOn:         "Garder l'écran allumé",
            .keepScreenOnDesc:     "L'écran restera allumé pendant le téléprompter",
            .information:          "Informations",
            .appVersion:           "Version de l'app",
            .chordsInDatabase:     "Accords dans la base",
            .resetSettings:        "Réinitialiser les paramètres",

            // Menu boczne
            .tunerSubtitle:    "Accordez votre guitare",
            .settingsSubtitle: "Thème, langue, téléprompter",

            // Teleprompter
            .play:  "Lecture",
            .pause: "Pause",
            .reset: "Réinitialiser",

            // PDF
            .generatedIn: "Généré dans ChordScroller",
            
            // Teleprompter - dodatkowe
            .scrollHint:   "Faites défiler avec le doigt à tout moment",
            .pausedToast:  "⏸ En pause",
            
            // Stroik - dodatkowe
            .tapStringToSelect: "Touchez une corde pour la sélectionner manuellement",
            .inTune:            "✓ accordé",
            
            // Import - przykłady URL
            .exampleURLWywrota: "spiewnik.wywrota.pl/chanson/titre",
            .exampleURLUG:      "tabs.ultimate-guitar.com/tab/artiste/chanson-chords-123456",
            
            // Chanson d'exemple
            .exampleSongTitle:   "Chanson d'exemple",
            .exampleSongContent: """
[G]Aujourd'hui est une belle [C]journée
[D]Le soleil brille [G]à nouveau
[Em]Le vent joue sur les [Am]cordes des arbres
[D]Et me chante [G]à l'oreille

[G]La la la [C]la la
[D]La la la [G]la
""",
            .exampleTag:         "Exemples",
        ],
    ]
}

// MARK: - Teksty z parametrami (interpolacja)

extension L10n {

    static func noSongsWithTag(
        _ tag: String,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Brak piosenek z tagiem: \(tag)"
        case .english: return "No songs with tag: \(tag)"
        case .german:  return "Keine Lieder mit Tag: \(tag)"
        case .spanish: return "Sin canciones con etiqueta: \(tag)"
        case .italian: return "Nessuna canzone con tag: \(tag)"
        case .french:  return "Aucune chanson avec le tag : \(tag)"
        case .system:  return "No songs with tag: \(tag)"
        }
    }

    static func capoFret(
        _ fret: Int,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "\(fret). próg"
        case .english: return "Fret \(fret)"
        case .german:  return "\(fret). Bund"
        case .spanish: return "Traste \(fret)"
        case .italian: return "Tasto \(fret)"
        case .french:  return "Frette \(fret)"
        case .system:  return "Fret \(fret)"
        }
    }

    static func linesCount(
        _ count: Int,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "\(count) linii"
        case .english: return "\(count) lines"
        case .german:  return "\(count) Zeilen"
        case .spanish: return "\(count) líneas"
        case .italian: return "\(count) righe"
        case .french:  return "\(count) lignes"
        case .system:  return "\(count) lines"
        }
    }

    static func linesAndSpeed(
        _ lines: Int,
        _ speed: Int,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "\(lines) linii • \(speed) px/s"
        case .english: return "\(lines) lines • \(speed) px/s"
        case .german:  return "\(lines) Zeilen • \(speed) px/s"
        case .spanish: return "\(lines) líneas • \(speed) px/s"
        case .italian: return "\(lines) righe • \(speed) px/s"
        case .french:  return "\(lines) lignes • \(speed) px/s"
        case .system:  return "\(lines) lines • \(speed) px/s"
        }
    }

    static func noDiagramFor(
        _ chord: String,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Brak diagramu dla \(chord)"
        case .english: return "No diagram for \(chord)"
        case .german:  return "Kein Diagramm für \(chord)"
        case .spanish: return "Sin diagrama para \(chord)"
        case .italian: return "Nessun diagramma per \(chord)"
        case .french:  return "Pas de diagramme pour \(chord)"
        case .system:  return "No diagram for \(chord)"
        }
    }

    static func manualMode(
        _ note: String,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Tryb ręczny: \(note)"
        case .english: return "Manual mode: \(note)"
        case .german:  return "Manueller Modus: \(note)"
        case .spanish: return "Modo manual: \(note)"
        case .italian: return "Modo manuale: \(note)"
        case .french:  return "Mode manuel : \(note)"
        case .system:  return "Manual mode: \(note)"
        }
    }

    static func octave(
        _ num: Int,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "oktawa \(num)"
        case .english: return "octave \(num)"
        case .german:  return "Oktave \(num)"
        case .spanish: return "octava \(num)"
        case .italian: return "ottava \(num)"
        case .french:  return "octave \(num)"
        case .system:  return "octave \(num)"
        }
    }

    static func capoValue(
        _ value: Int,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Capo: \(value)"
        case .english: return "Capo: \(value)"
        case .german:  return "Kapo: \(value)"
        case .spanish: return "Cejilla: \(value)"
        case .italian: return "Capotasto: \(value)"
        case .french:  return "Capo : \(value)"
        case .system:  return "Capo: \(value)"
        }
    }

    static func loadingErrorWith(
        _ description: String,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Błąd ładowania: \(description)"
        case .english: return "Loading error: \(description)"
        case .german:  return "Ladefehler: \(description)"
        case .spanish: return "Error de carga: \(description)"
        case .italian: return "Errore di caricamento: \(description)"
        case .french:  return "Erreur de chargement : \(description)"
        case .system:  return "Loading error: \(description)"
        }
    }
    
    static func tuneString(
        _ note: String,
        for lang: AppLanguage = SettingsManager.shared.resolvedLanguage
    ) -> String {
        switch AppLanguage.resolve(lang) {
        case .polish:  return "Strój strunę \(note)"
        case .english: return "Tune string \(note)"
        case .german:  return "Stimme Saite \(note)"
        case .spanish: return "Afina la cuerda \(note)"
        case .italian: return "Accorda la corda \(note)"
        case .french:  return "Accordez la corde \(note)"
        case .system:  return "Tune string \(note)"
        }
    }
    
}
