import SwiftUI

/// Три глибини скла з аркуша «Матеріал».
///
/// На iOS 26 це був би один виклик `.glassEffect()`. На iOS 17–18 такого API
/// немає, тому шар збирається руками з чотирьох складників:
/// матеріал (розмиває тло) → градієнтна заливка (дає тілу об'єм) →
/// світлий штрих (читається як товщина краю) → тінь (відриває від тла).
enum GlassTier {
    /// Картки нотаток. Ледь тримає форму, щоб колір тла проходив наскрізь.
    case thin
    /// Пошук, кнопки навігації, аркуш нотатки. Окремий шар над тлом.
    case regular
    /// Плаваюча панель. Єдине, що завжди поверх контенту.
    case thick

    fileprivate func fill(_ scheme: ColorScheme, _ k: Double) -> [Color] {
        // У світлій темі скло не «підсвічує» тло, а згущує його до білого,
        // інакше матеріал читається як брудна пляма. Значення для обох тем
        // різні не на множник, а по суті — тому й задані окремо.
        let top: Double
        let bottom: Double
        if scheme == .dark {
            switch self {
            case .thin: (top, bottom) = (0.155, 0.050)
            case .regular: (top, bottom) = (0.190, 0.060)
            case .thick: (top, bottom) = (0.190, 0.055)
            }
        } else {
            switch self {
            case .thin: (top, bottom) = (0.78, 0.46)
            case .regular: (top, bottom) = (0.85, 0.52)
            case .thick: (top, bottom) = (0.86, 0.55)
            }
        }
        return [.white.opacity(min(1, top * k)), .white.opacity(min(1, bottom * k))]
    }

    fileprivate func stroke(_ scheme: ColorScheme) -> [Color] {
        let edge: Double = self == .thin ? 0.16 : 0.20
        if scheme == .dark {
            // Верхній штрих яскравіший за нижній — саме ця різниця читається
            // як товщина скла, а не як прозорий прямокутник.
            return [.white.opacity(edge + 0.26), .white.opacity(edge * 0.55)]
        }
        return [.white.opacity(0.95), .white.opacity(0.70)]
    }

    fileprivate var shadow: (radius: CGFloat, y: CGFloat, opacity: Double) {
        switch self {
        case .thin: return (16, 8, 0.34)
        case .regular: return (18, 9, 0.38)
        case .thick: return (22, 12, 0.45)
        }
    }
}

private struct GlassSurface: ViewModifier {
    let tier: GlassTier
    let radius: CGFloat
    /// Розмиття лишаємо лише там, де під поверхнею справді проїжджає контент.
    /// Над уже розмитим тлом воно невидиме, але коштує окремого шару на
    /// кожен елемент — саме на цьому дохла прокрутка у веб-версії.
    let blurred: Bool
    let tinted: Color?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.glassDensity) private var density

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private var fillColors: [Color] {
        if let tinted { return [tinted.opacity(0.90), tinted.opacity(0.55)] }
        return tier.fill(scheme, density)
    }

    private var strokeColors: [Color] {
        if tinted != nil { return [.white.opacity(0.55), .white.opacity(0.18)] }
        return tier.stroke(scheme)
    }

    func body(content: Content) -> some View {
        let shadow = tier.shadow
        return content
            .background {
                ZStack {
                    if blurred {
                        shape.fill(.ultraThinMaterial)
                    }
                    shape.fill(
                        LinearGradient(colors: fillColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    shape.strokeBorder(
                        LinearGradient(colors: strokeColors, startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
                }
                .shadow(
                    color: .black.opacity(scheme == .dark ? shadow.opacity : shadow.opacity * 0.34),
                    radius: shadow.radius,
                    x: 0,
                    y: shadow.y
                )
            }
    }
}

/// Поверхня без власної тіні — для дрібних елементів, під якими тіні нікуди
/// лягти: у стрічці з прокруткою вона зрізається й читається як сіра смуга.
private struct FlatGlass: ViewModifier {
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.glassDensity) private var density

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background {
                ZStack {
                    shape.fill(
                        LinearGradient(
                            colors: GlassTier.thin.fill(scheme, density),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    shape.strokeBorder(
                        LinearGradient(
                            colors: GlassTier.thin.stroke(scheme),
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                }
            }
    }
}

private struct GlassDensityKey: EnvironmentKey {
    static let defaultValue: Double = 1
}

extension EnvironmentValues {
    var glassDensity: Double {
        get { self[GlassDensityKey.self] }
        set { self[GlassDensityKey.self] = newValue }
    }
}

extension View {
    /// Скляна поверхня. `tinted` заливає її акцентом — для головної дії.
    func glass(_ tier: GlassTier, radius: CGFloat, blurred: Bool = false, tinted: Color? = nil) -> some View {
        modifier(GlassSurface(tier: tier, radius: radius, blurred: blurred, tinted: tinted))
    }

    /// Поверхня без тіні — чіпи й таке інше.
    func flatGlass(radius: CGFloat) -> some View {
        modifier(FlatGlass(radius: radius))
    }
}
