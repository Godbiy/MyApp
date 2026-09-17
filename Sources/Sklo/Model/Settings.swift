import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum ThemeChoice: String, CaseIterable, Identifiable {
    case auto, dark, light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Як у системі"
        case .dark: return "Темна"
        case .light: return "Світла"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

/// Налаштування вигляду. Живуть окремо від нотаток — це різні за природою
/// дані, і зносити одне разом з іншим не має жодного сенсу.
@Observable
final class Settings {
    var theme: ThemeChoice { didSet { save() } }
    var accent: Color { didSet { save() } }
    /// 0 — тло завмирає, далі 1…4.
    var bgSpeed: Int { didSet { save() } }
    var bgSeed: Int { didSet { save() } }
    /// Насиченість плям, 0…1.4.
    var bgIntensity: Double { didSet { save() } }
    /// Щільність скла, 0.2…1.6. Веде і заливку поверхонь, і розмиття.
    var glass: Double { didSet { save() } }
    var motion: Bool { didSet { save() } }

    static let presets: [Color] = [
        Color(hex: 0x7C5CFF), Color(hex: 0x20D0C0), Color(hex: 0xFF4D8D),
        Color(hex: 0xFFB020), Color(hex: 0x4D9FFF), Color(hex: 0xB44DFF),
    ]

    @ObservationIgnored private var loaded = false
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let d = defaults

        theme = ThemeChoice(rawValue: d.string(forKey: "theme") ?? "") ?? .auto
        accent = Color(hex: UInt32(truncatingIfNeeded: d.object(forKey: "accent") as? Int ?? 0x7C5CFF))
        bgSpeed = d.object(forKey: "bgSpeed") as? Int ?? 2
        bgSeed = d.object(forKey: "bgSeed") as? Int ?? 7
        bgIntensity = d.object(forKey: "bgIntensity") as? Double ?? 1
        glass = d.object(forKey: "glass") as? Double ?? 1
        motion = d.object(forKey: "motion") as? Bool ?? true

        bgSpeed = min(4, max(0, bgSpeed))
        bgIntensity = min(1.4, max(0, bgIntensity))
        glass = min(1.6, max(0.2, glass))
        loaded = true
    }

    /// Акцент зберігаємо як число, а не як `Color` — Color не Codable, а нам
    /// і потрібні лише ті відтінки, що є в наборі.
    var accentHex: UInt32 {
        for preset in Self.presets where preset.hexValue == accent.hexValue {
            return preset.hexValue
        }
        return accent.hexValue
    }

    private func save() {
        guard loaded else { return }
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(Int(accentHex), forKey: "accent")
        defaults.set(bgSpeed, forKey: "bgSpeed")
        defaults.set(bgSeed, forKey: "bgSeed")
        defaults.set(bgIntensity, forKey: "bgIntensity")
        defaults.set(glass, forKey: "glass")
        defaults.set(motion, forKey: "motion")
    }

    func shuffleBackground() {
        bgSeed = Int.random(in: 1...9999)
    }

    var speedTitle: String {
        ["Вимкнено", "Повільно", "Спокійно", "Жваво", "Швидко"][min(4, max(0, bgSpeed))]
    }
}

extension Color {
    /// Наближене значення для порівняння й збереження. Працює, бо всі кольори
    /// застосунку задані шістнадцятковими константами, а не обчислені.
    var hexValue: UInt32 {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32((r * 255).rounded())
        let gi = UInt32((g * 255).rounded())
        let bi = UInt32((b * 255).rounded())
        return (ri << 16) | (gi << 8) | bi
        #else
        return 0x7C5CFF
        #endif
    }
}
