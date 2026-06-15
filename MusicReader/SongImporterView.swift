import SwiftUI
import WebKit

// MARK: - Obsługuje import z Wywrota i Ultimate Guitar przez WKWebView

final class SongWebViewController: UIViewController, WKNavigationDelegate {

    var onResult: ((Result<Song, Error>) -> Void)?
    private var webView: WKWebView!
    private var hasReported = false
    private var retryCount  = 0
    private var currentURL: String?
    private var siteType: SiteType = .unknown

    enum SiteType { case wywrota, ultimateGuitar, unknown }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        view.addSubview(webView)
    }

    // MARK: - Public

    func load(urlString: String) {
        guard urlString != currentURL else { return }
        currentURL  = urlString
        hasReported = false
        retryCount  = 0

        if urlString.contains("wywrota.pl") {
            siteType = .wywrota
        } else if urlString.contains("ultimate-guitar.com") {
            siteType = .ultimateGuitar
        } else {
            siteType = .unknown
        }

        guard let url = URL(string: urlString) else {
            report(.failure(ImportError.parseError(L10n.invalidURL.localized())))
            return
        }

        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let delay: TimeInterval = siteType == .ultimateGuitar ? 2.0 : 0.5
        scheduleExtract(delay: delay)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        report(.failure(ImportError.parseError(L10n.loadingErrorWith(error.localizedDescription))))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
        report(.failure(ImportError.parseError(L10n.noConnectionOrInvalidURL.localized())))
    }

    // MARK: - Extraction

    private func scheduleExtract(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.tryExtract()
        }
    }

    private func tryExtract() {
        switch siteType {
        case .wywrota:        extractWywrota()
        case .ultimateGuitar: extractUltimateGuitar()
        case .unknown:        report(.failure(ImportError.parseError(L10n.unsupportedSite.localized())))
        }
    }

    // MARK: - Wywrota.pl

    private func extractWywrota() {
        let js = """
        (function(){
            var result = { content: '', capo: null, fullText: '' };
            result.fullText = document.body.innerText || '';
            var lines = document.querySelectorAll('span.annotated-lyrics');
            if (!lines.length) return JSON.stringify(result);
            var content = [];
            function processNode(node) {
                var out = '';
                node.childNodes.forEach(function(child) {
                    if (child.nodeType === 3) {
                        out += child.textContent;
                    } else if (child.nodeName === 'CODE' && child.classList && child.classList.contains('an')) {
                        var ch = (child.getAttribute('data-chord') || '') + (child.getAttribute('data-suffix') || '');
                        out += '[' + ch + ']';
                    } else {
                        out += processNode(child);
                    }
                });
                return out;
            }
            lines.forEach(function(line) {
                content.push(processNode(line).trim());
            });
            result.content = content.join('\\n');
            return JSON.stringify(result);
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self else { return }

            if let jsonStr = result as? String,
               let data    = jsonStr.data(using: .utf8),
               let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let content  = json["content"]  as? String ?? ""
                let fullText = json["fullText"] as? String ?? ""
                let capo     = CapoExtractor.extract(from: fullText) ?? CapoExtractor.extract(from: content)

                if content.count > 20 {
                    let title = self.cleanWywrotaTitle(self.webView.title ?? L10n.importedSong.localized())
                    let cleanedContent = CapoExtractor.removeCapoLines(from: content)
                    self.report(.success(Song(
                        title:       title,
                        content:     cleanedContent,
                        scrollSpeed: 40,
                        fontSize:    22,
                        capo:        capo
                    )))
                    return
                }
            }

            if self.retryCount < 6 {
                self.retryCount += 1
                self.scheduleExtract(delay: 0.5)
            } else {
                self.report(.failure(ImportError.notFound(L10n.songNotFoundWywrota.localized())))
            }
        }
    }

    private func cleanWywrotaTitle(_ raw: String) -> String {
        var t = raw
        for suffix in [", Chwyty na gitarę", ", Chwyty na ukulele", " – Śpiewnik", " | Śpiewnik"] {
            t = t.replacingOccurrences(of: suffix, with: "")
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Ultimate Guitar

    private func extractUltimateGuitar() {
        let js = """
        (function() {
            var store = document.querySelector('.js-store');
            if (store) {
                var data = store.getAttribute('data-content');
                if (data && data.length > 100) return data;
            }
            if (typeof window !== 'undefined' && window.UGAPP && window.UGAPP.store) {
                return JSON.stringify(window.UGAPP.store);
            }
            var scripts = document.querySelectorAll('script');
            for (var i = 0; i < scripts.length; i++) {
                var text = scripts[i].textContent || '';
                if (text.includes('wiki_tab') && text.includes('content')) {
                    var match = text.match(/window\\.UGAPP\\.store\\s*=\\s*({[\\s\\S]+?});/);
                    if (match && match[1]) return match[1];
                }
            }
            return '';
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self else { return }

            if let json = result as? String, json.count > 100 {
                do {
                    let song = try UltimateGuitarParser.parse(json: json)
                    self.report(.success(song))
                } catch {
                    if self.retryCount < 4 {
                        self.retryCount += 1
                        self.scheduleExtract(delay: 1.5)
                    } else {
                        self.report(.failure(error))
                    }
                }
            } else if self.retryCount < 5 {
                self.retryCount += 1
                self.scheduleExtract(delay: 1.5)
            } else {
                self.report(.failure(ImportError.notFound(L10n.couldNotReadUG.localized())))
            }
        }
    }

    // MARK: - Report result

    private func report(_ result: Result<Song, Error>) {
        guard !hasReported else { return }
        hasReported = true
        currentURL  = nil
        DispatchQueue.main.async { self.onResult?(result) }
    }
}

// MARK: - SwiftUI wrapper

struct SongImporterView: UIViewControllerRepresentable {
    @Binding var urlToLoad: String?
    var onResult: (Result<Song, Error>) -> Void

    func makeUIViewController(context: Context) -> SongWebViewController {
        let vc = SongWebViewController()
        vc.onResult = { r in DispatchQueue.main.async { onResult(r) } }
        return vc
    }

    func updateUIViewController(_ vc: SongWebViewController, context: Context) {
        if let url = urlToLoad {
            vc.onResult = { r in DispatchQueue.main.async { onResult(r) } }
            vc.load(urlString: url)
        }
    }
}

// MARK: - Uniwersalny ekstraktor Capo

struct CapoExtractor {

    private static let wordToNumber: [String: Int] = [
        // Polski
        "pierwszym": 1, "pierwszy": 1, "pierwsza": 1, "pierwszej": 1, "1szy": 1, "1szym": 1,
        "drugim": 2, "drugi": 2, "druga": 2, "drugiej": 2, "2gi": 2, "2gim": 2,
        "trzecim": 3, "trzeci": 3, "trzecia": 3, "trzeciej": 3, "3ci": 3, "3cim": 3,
        "czwartym": 4, "czwarty": 4, "czwarta": 4, "czwartej": 4, "4ty": 4, "4tym": 4,
        "piątym": 5, "piąty": 5, "piąta": 5, "piątej": 5, "5ty": 5, "5tym": 5,
        "szóstym": 6, "szósty": 6, "szósta": 6, "szóstej": 6, "6ty": 6, "6tym": 6,
        "siódmym": 7, "siódmy": 7, "siódma": 7, "siódmej": 7, "7my": 7, "7mym": 7,
        "ósmym": 8, "ósmy": 8, "ósma": 8, "ósmej": 8, "8my": 8, "8mym": 8,
        "dziewiątym": 9, "dziewiąty": 9, "dziewiąta": 9, "dziewiątej": 9, "9ty": 9, "9tym": 9,
        "dziesiątym": 10, "dziesiąty": 10, "dziesiąta": 10, "dziesiątej": 10, "10ty": 10, "10tym": 10,
        "jedenastym": 11, "jedenasty": 11, "jedenasta": 11, "jedenastej": 11, "11ty": 11, "11tym": 11,
        "dwunastym": 12, "dwunasty": 12, "dwunasta": 12, "dwunastej": 12, "12ty": 12, "12tym": 12,
        // English
        "first": 1, "1st": 1,
        "second": 2, "2nd": 2,
        "third": 3, "3rd": 3,
        "fourth": 4, "4th": 4,
        "fifth": 5, "5th": 5,
        "sixth": 6, "6th": 6,
        "seventh": 7, "7th": 7,
        "eighth": 8, "8th": 8,
        "ninth": 9, "9th": 9,
        "tenth": 10, "10th": 10,
        "eleventh": 11, "11th": 11,
        "twelfth": 12, "12th": 12,
        // Roman
        "i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5,
        "vi": 6, "vii": 7, "viii": 8, "ix": 9, "x": 10,
        "xi": 11, "xii": 12,
    ]

    static func extract(from text: String) -> Int? {
        let lowercased = text.lowercased()

        let patterns: [(pattern: String, numberGroup: Int)] = [
            (#"kapodaster\s*(?:na|:)?\s*(\d+)\.?\s*progi?e?u?"#, 1),
            (#"kapodaster\s*(?:na|:)?\s*(\w+)\s*progi?e?u?"#, 1),
            (#"capo\s*(?:na|:)?\s*(\d+)\.?\s*progi?e?u?"#, 1),
            (#"capo\s*(?:na|:)?\s*(\w+)\s*progi?e?u?"#, 1),
            (#"capo\s*[:\-–—]?\s*(\d+)"#, 1),
            (#"kapodaster\s*[:\-–—]?\s*(\d+)"#, 1),
            (#"kapo\s*[:\-–—]?\s*(\d+)"#, 1),
            (#"(?:na\s+)?(\d+)\.?\s*progi?e?u?"#, 1),
            (#"capo\s*[:\-–—]?\s*(?:on\s+)?(\d+)(?:st|nd|rd|th)?\s*fret"#, 1),
            (#"capo\s*[:\-–—]?\s*(?:on\s+)?(\w+)\s*fret"#, 1),
            (#"capo\s+(?:on|at)\s+(\d+)"#, 1),
            (#"capo\s*[:\-–—]?\s*(\d+)(?:st|nd|rd|th)"#, 1),
            (#"(\d+)(?:st|nd|rd|th)?\s*fret"#, 1),
            (#"capo\s*[:\-–—]?\s*(i{1,3}|iv|v|vi{0,3}|ix|x|xi{0,2})\b"#, 1),
            (#"put\s+capo\s+(?:on\s+)?(\d+)"#, 1),
            (#"use\s+capo\s*(?:on\s+)?(\d+)"#, 1),
            (#"with\s+capo\s+(?:on\s+)?(\d+)"#, 1),
            (#"capo\s+required\s*[:\-–—]?\s*(\d+)"#, 1),
            (#"capo\W{0,3}(\d{1,2})\b"#, 1),
            (#"kapodaster\W{0,3}(\d{1,2})\b"#, 1),
        ]

        for (pattern, group) in patterns {
            guard
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: lowercased, range: NSRange(location: 0, length: lowercased.utf16.count))
            else { continue }

            let groupRange = match.range(at: group)
            guard groupRange.location != NSNotFound else { continue }

            let captured = (lowercased as NSString).substring(with: groupRange)

            if let number = Int(captured), (1...12).contains(number) {
                return number
            }
            if let number = wordToNumber[captured.lowercased()], (1...12).contains(number) {
                return number
            }
        }

        return nil
    }

    static func removeCapoLines(from text: String) -> String {
        let capoPatterns = [
            #"(?m)^.*\b[Cc]apo\b.*$\n?"#,
            #"(?m)^.*\b[Kk]apodaster\b.*$\n?"#,
            #"(?m)^.*\b[Kk]apo\b.*\bpro[gó]\b.*$\n?"#,
        ]

        var result = text
        for pattern in capoPatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return result
    }
}

// MARK: - Ultimate Guitar Parser

struct UltimateGuitarParser {

    static func parse(json jsonString: String) throws -> Song {
        let decodedJson = decodeHTMLEntities(jsonString)

        guard
            let data = decodedJson.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw ImportError.parseError(L10n.invalidJsonUG.localized())
        }

        // Znajdź treść
        let contentPaths: [[String]] = [
            ["store", "page", "data", "tab_view", "wiki_tab", "content"],
            ["page", "data", "tab_view", "wiki_tab", "content"],
            ["data", "tab_view", "wiki_tab", "content"],
            ["tab_view", "wiki_tab", "content"],
        ]

        var rawContent = ""
        for path in contentPaths {
            if let c = dig(root, path: path) as? String, c.count > 10 {
                rawContent = c
                break
            }
        }

        // Znajdź metadane
        let tabPaths: [[String]] = [
            ["store", "page", "data", "tab"],
            ["page", "data", "tab"],
            ["data", "tab"],
        ]

        var songName   = L10n.importedSong.localized()
        var artistName = ""
        for path in tabPaths {
            if let tab = dig(root, path: path) as? [String: Any] {
                songName   = tab["song_name"]   as? String ?? songName
                artistName = tab["artist_name"] as? String ?? ""
                break
            }
        }

        let title = artistName.isEmpty ? songName : "\(artistName) – \(songName)"

        guard !rawContent.isEmpty else {
            throw ImportError.notFound(L10n.chordsNotFoundUG.localized())
        }

        let capo    = CapoExtractor.extract(from: rawContent)
        let content = convertUGContent(rawContent)

        guard content.count > 10 else {
            throw ImportError.notFound(L10n.couldNotProcessSong.localized())
        }

        return Song(title: title, content: content, scrollSpeed: 40, fontSize: 22, capo: capo)
    }

    // MARK: - Konwersja formatu UG

    static func convertUGContent(_ input: String) -> String {
        var text = input

        // 1. Zamień [ch]Akord[/ch] na tymczasowy marker {{Akord}}
        text = text.replacingOccurrences(
            of:   #"\[ch\]([^\[]+)\[/ch\]"#,
            with: "{{$1}}",
            options: .regularExpression
        )

        // 2. Usuń tagi [tab]/[/tab] ale ZACHOWAJ zawartość
        text = text.replacingOccurrences(of: "[tab]",  with: "")
        text = text.replacingOccurrences(of: "[/tab]", with: "")

        // 3. Zamień sekcje na markery tymczasowe
        let sectionMappings: [(String, String)] = [
            (#"\[Intro\]"#,                "§INTRO§"),
            (#"\[Verse[^\]]*\]"#,          "§VERSE§"),
            (#"\[Chorus[^\]]*\]"#,         "§CHORUS§"),
            (#"\[Bridge[^\]]*\]"#,         "§BRIDGE§"),
            (#"\[Pre-?[Cc]horus[^\]]*\]"#, "§PRECHORUS§"),
            (#"\[Outro[^\]]*\]"#,          "§OUTRO§"),
            (#"\[Solo[^\]]*\]"#,           "§SOLO§"),
            (#"\[Interlude[^\]]*\]"#,      "§INTERLUDE§"),
            (#"\[Instrumental[^\]]*\]"#,   "§INSTRUMENTAL§"),
            (#"\[Hook[^\]]*\]"#,           "§HOOK§"),
            (#"\[Coda[^\]]*\]"#,           "§CODA§"),
            (#"\[Break[^\]]*\]"#,          "§BREAK§"),
        ]
        for (pattern, marker) in sectionMappings {
            text = text.replacingOccurrences(of: pattern, with: marker, options: [.regularExpression, .caseInsensitive])
        }

        // 4. Usuń inne tagi [...]
        text = text.replacingOccurrences(of: #"\[[^\]]*\]"#, with: "", options: .regularExpression)

        // 5. Zamień markery akordów {{Akord}} na [Akord]
        text = text.replacingOccurrences(
            of:   #"\{\{([^}]+)\}\}"#,
            with: "[$1]",
            options: .regularExpression
        )

        // 6. Usuń linie z informacją o capo
        text = CapoExtractor.removeCapoLines(from: text)

        // 7. Normalizuj newlines
        text = text.replacingOccurrences(of: "\r\n", with: "\n")
        text = text.replacingOccurrences(of: "\r",   with: "\n")

        // 8. Podziel na linie i połącz linie akordów z liniami tekstu
        let lines  = text.components(separatedBy: "\n")
        let merged = mergeChordAndLyricLines(lines)

        // 9. Zamień markery sekcji na czytelne nagłówki (zlokalizowane)
        let sectionLabels: [(String, L10n)] = [
            ("§INTRO§",        .sectionIntro),
            ("§VERSE§",        .sectionVerse),
            ("§CHORUS§",       .sectionChorus),
            ("§BRIDGE§",       .sectionBridge),
            ("§PRECHORUS§",    .sectionPrechorus),
            ("§OUTRO§",        .sectionOutro),
            ("§SOLO§",         .sectionSolo),
            ("§INTERLUDE§",    .sectionInterlude),
            ("§INSTRUMENTAL§", .sectionInstrumental),
            ("§HOOK§",         .sectionHook),
            ("§CODA§",         .sectionCoda),
            ("§BREAK§",        .sectionBreak),
        ]

        var result: [String] = []
        var emptyCount = 0

        for line in merged {
            var processed = line.trimmingCharacters(in: .whitespaces)

            for (marker, l10nKey) in sectionLabels {
                if processed.contains(marker) {
                    processed = processed
                        .replacingOccurrences(of: marker, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !result.isEmpty && result.last != "" {
                        result.append("")
                    }
                    result.append(l10nKey.localized())
                    emptyCount = 0
                    break
                }
            }

            if !sectionLabels.contains(where: { line.contains($0.0) }) {
                if processed.isEmpty {
                    emptyCount += 1
                    if emptyCount <= 1 { result.append("") }
                } else {
                    emptyCount = 0
                    result.append(processed)
                }
            }
        }

        return result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Łączenie linii akordów z liniami tekstu

    private static func mergeChordAndLyricLines(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if isChordOnlyLine(line) {
                if i + 1 < lines.count {
                    let nextLine    = lines[i + 1]
                    let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)

                    if !nextTrimmed.isEmpty && !isChordOnlyLine(nextLine) && !isSectionMarker(nextTrimmed) {
                        let merged = mergeTwoLines(chordLine: line, textLine: nextLine)
                        result.append(merged)
                        i += 2
                        continue
                    }
                }
                result.append(line)
                i += 1
            } else {
                result.append(line)
                i += 1
            }
        }

        return result
    }

    private static func isChordOnlyLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSectionMarker(trimmed) else { return false }

        let withoutChords = trimmed
            .replacingOccurrences(of: #"\[[^\]]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        let hasChord       = trimmed.range(of: #"\[[^\]]+\]"#, options: .regularExpression) != nil
        let remainingClean = withoutChords.replacingOccurrences(
            of: #"[|\-/\s\(\)x\d,\.%]+"#,
            with: "",
            options: .regularExpression
        )

        return hasChord && remainingClean.isEmpty
    }

    private static func isSectionMarker(_ line: String) -> Bool {
        line.contains("§") && line.contains("§")
    }

    private static func mergeTwoLines(chordLine: String, textLine: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\[([^\]]+)\]"#) else {
            return textLine
        }

        var chordPositions: [(chord: String, visualPosition: Int)] = []

        let nsChordLine = chordLine as NSString
        let matches = regex.matches(in: chordLine, range: NSRange(location: 0, length: nsChordLine.length))

        var visualOffset = 0
        var lastRawEnd   = 0

        for match in matches {
            let gapStart = lastRawEnd
            let gapEnd   = match.range.location
            let gap      = nsChordLine.substring(with: NSRange(location: gapStart, length: gapEnd - gapStart))

            let pos       = visualOffset + gap.count
            let chordName = nsChordLine.substring(with: match.range(at: 1))
            chordPositions.append((chordName, pos))

            visualOffset = pos + chordName.count
            lastRawEnd   = match.range.location + match.range.length
        }

        guard !chordPositions.isEmpty else { return textLine }

        let textChars = Array(textLine)
        var result    = ""
        var textIdx   = 0

        for (chord, pos) in chordPositions {
            let targetPos = min(pos, textChars.count)

            while textIdx < targetPos {
                result.append(textChars[textIdx])
                textIdx += 1
            }

            result += "[\(chord)]"
        }

        while textIdx < textChars.count {
            result.append(textChars[textIdx])
            textIdx += 1
        }

        return result
    }

    // MARK: - Helpers

    private static func dig(_ obj: Any, path: [String]) -> Any? {
        var current: Any = obj
        for key in path {
            if let dict = current as? [String: Any], let next = dict[key] {
                current = next
            } else if let arr = current as? [Any], let idx = Int(key), idx < arr.count {
                current = arr[idx]
            } else {
                return nil
            }
        }
        return current
    }

    private static func decodeHTMLEntities(_ str: String) -> String {
        var result = str
        let entities: [(String, String)] = [
            ("&quot;", "\""), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&#39;", "'"), ("&apos;", "'"), ("&#x27;", "'"), ("&#x2F;", "/"), ("&nbsp;", " "),
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}

// MARK: - Błędy importu

enum ImportError: LocalizedError {
    case parseError(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .parseError(let msg): return msg
        case .notFound(let msg):   return msg
        }
    }
}
