import SwiftUI

// Палітра з макета. Чотири акценти ділять одну світлість і насиченість —
// різняться тільки відтінком, тому жоден не перетягує увагу на себе.
enum Palette {
    static let violet = Color(hex: 0x7C5CFF)
    static let teal = Color(hex: 0x20D0C0)
    static let pink = Color(hex: 0xFF4D8D)
    static let amber = Color(hex: 0xFFB020)

    static let inkDark = Color(hex: 0x07070D)
    static let inkLight = Color(hex: 0xF4F1FA)
}

/// Акцент теки. Зберігається за назвою, а не за кольором, щоб палітру можна
/// було переграти, не чіпаючи збережені дані.
enum Accent: String, Codable, CaseIterable, Identifiable, Hashable {
    case violet, teal, pink, amber

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .violet: return Palette.violet
        case .teal: return Palette.teal
        case .pink: return Palette.pink
        case .amber: return Palette.amber
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// Типографіка. Системний шрифт замість Manrope/Literata з макета: SF Pro та
// New York уже на пристрої, мають повну кирилицю й правильні оптичні розміри
// на кожному кеглі. Підключати вебшрифти заради того самого сенсу немає.
extension Font {
    static let skloLargeTitle = Font.system(size: 34, weight: .heavy, design: .default)
    static let skloTitle = Font.system(size: 27, weight: .heavy, design: .default)
    static let skloNoteTitle = Font.system(size: 16.5, weight: .bold, design: .default)
    static let skloLabel = Font.system(size: 14, weight: .bold, design: .default)
    static let skloCaption = Font.system(size: 12, weight: .semibold, design: .default)
    static let skloEyebrow = Font.system(size: 11.5, weight: .semibold, design: .default)

    /// Текст самої нотатки — засічковий, щоб читався як письмо, а не як інтерфейс.
    static let skloBody = Font.system(size: 15.5, weight: .regular, design: .serif)
    static let skloPreview = Font.system(size: 13.5, weight: .regular, design: .serif)
    static let skloChecklist = Font.system(size: 14.5, weight: .regular, design: .serif)
    static let skloSettingHint = Font.system(size: 12.5, weight: .regular, design: .serif)
}
