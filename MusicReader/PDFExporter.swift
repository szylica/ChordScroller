import UIKit
import Foundation

final class PDFExporter {
    
    private var currentY: CGFloat = 0
    private let pageWidth: CGFloat = 595.0    // A4
    private let pageHeight: CGFloat = 842.0   // A4
    private let margin: CGFloat = 40.0
    private var contentWidth: CGFloat { pageWidth - margin * 2 }
    
    private let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
    private let metaFont = UIFont.systemFont(ofSize: 11, weight: .regular)
    private let chordFont = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
    private let textFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private let sectionFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
    private let footerFont = UIFont.systemFont(ofSize: 8, weight: .light)
    
    private let chordColor = UIColor.systemOrange
    private let textColor = UIColor.black
    private let metaColor = UIColor.darkGray
    private let sectionColor = UIColor.systemOrange
    private let lineColor = UIColor.lightGray
    
    private var pdfContext: UIGraphicsPDFRendererContext!
    
    // MARK: - Publiczne API
    
    static func generatePDF(for song: Song) -> Data {
        let exporter = PDFExporter()
        return exporter.render(song: song)
    }
    
    // MARK: - Rendering
    
    private func render(song: Song) -> Data {
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )
        
        return renderer.pdfData { context in
            self.pdfContext = context
            
            beginNewPage()
            
            // Tytuł
            drawText(
                song.title.isEmpty ? "Bez tytulu" : song.title,
                font: titleFont, color: .black
            )
            currentY += 6
            
            // Metadane
            if let capo = song.capo, capo > 0 {
                drawText("Capo: \(capo). prog", font: metaFont, color: metaColor)
            }
            
            let chords = ChordDatabase.extractChords(from: song.content)
            if !chords.isEmpty {
                drawText("Akordy: \(chords.joined(separator: ", "))", font: metaFont, color: metaColor)
            }
            
            if !song.tags.isEmpty {
                drawText("Tagi: \(song.tags.joined(separator: ", "))", font: metaFont, color: metaColor)
            }
            
            currentY += 4
            drawHorizontalLine()
            currentY += 8
            
            // Treść piosenki
            let lines = ChordFormatter.parseContent(song.content)
            
            for line in lines {
                if line.isEmpty {
                    currentY += textFont.lineHeight * 0.5
                    continue
                }
                
                if !line.hasChords {
                    let text = line.rawText
                    let sectionEmojis = ["🎸", "📝", "🎵", "🌉", "🎶", "🔚", "🎹", "🎼", "🪝", "🔄", "⏸"]
                    let isSection = sectionEmojis.contains(where: { text.hasPrefix($0) })
                    
                    if isSection {
                        currentY += 10
                        drawText(text, font: sectionFont, color: sectionColor)
                        currentY += 2
                    } else {
                        drawText(text, font: textFont, color: textColor)
                    }
                } else {
                    drawChordAndTextLine(segments: line.segments)
                }
            }
            
            // Stopka
            drawFooter()
        }
    }
    
    // MARK: - Rysowanie
    
    private func beginNewPage() {
        pdfContext.beginPage()
        currentY = margin
    }
    
    private func ensureSpace(for height: CGFloat) {
        if currentY + height > pageHeight - margin - 20 {
            drawFooter()
            beginNewPage()
        }
    }
    
    private func drawText(_ text: String, font: UIFont, color: UIColor) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let boundingRect = attrString.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        let height = ceil(boundingRect.height) + 2
        ensureSpace(for: height)
        
        attrString.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: height))
        currentY += height
    }
    
    private func drawHorizontalLine() {
        ensureSpace(for: 10)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY + 4))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY + 4))
        lineColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        currentY += 8
    }
    
    private func drawFooter() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.lightGray
        ]
        let text = NSAttributedString(string: "Wygenerowano w ChordScroller", attributes: attrs)
        text.draw(at: CGPoint(x: margin, y: pageHeight - margin + 10))
    }
    
    // MARK: - Linia akordów + tekst
    
    private func drawChordAndTextLine(segments: [ChordSegment]) {
        let chordHeight = chordFont.lineHeight
        let textHeight = textFont.lineHeight
        let totalHeight = chordHeight + textHeight + 6
        
        ensureSpace(for: totalHeight)
        
        // Buduj obie linie z pozycjami
        var chordLine = ""
        var textLine = ""
        
        for segment in segments {
            let word = segment.text
            let chord = segment.chord ?? ""
            
            if chord.isEmpty {
                chordLine += String(repeating: " ", count: word.count)
                textLine += word
            } else {
                let chordLen = chord.count
                let wordLen = word.count
                
                if chordLen >= wordLen {
                    chordLine += chord + " "
                    textLine += word + String(repeating: " ", count: max(0, chordLen - wordLen) + 1)
                } else {
                    chordLine += chord + String(repeating: " ", count: wordLen - chordLen)
                    textLine += word
                }
            }
        }
        
        // Trim trailing spaces
        let trimmedChord = chordLine.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let trimmedText = textLine.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        
        // Rysuj akord
        if !trimmedChord.trimmingCharacters(in: .whitespaces).isEmpty {
            let chordAttrs: [NSAttributedString.Key: Any] = [
                .font: chordFont,
                .foregroundColor: chordColor
            ]
            NSAttributedString(string: trimmedChord, attributes: chordAttrs)
                .draw(at: CGPoint(x: margin, y: currentY))
            currentY += chordHeight + 2
        }
        
        // Rysuj tekst
        if !trimmedText.trimmingCharacters(in: .whitespaces).isEmpty {
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor
            ]
            NSAttributedString(string: trimmedText, attributes: textAttrs)
                .draw(at: CGPoint(x: margin, y: currentY))
        }
        currentY += textHeight + 4
    }
}
