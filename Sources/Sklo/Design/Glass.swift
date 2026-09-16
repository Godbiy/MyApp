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

    fileprivate func fill(_ scheme: ColorScheme) -> [Color] {
        let (top, bottom): (Double, Double)
        switch self {
        case .thin: (top, bottom) = (0.155, 0.050)
        case .regular: (top, bottom) = (0.190, 0.060)
        case .thick: (top, bottom) = (0.190, 0.055)
        }
        if scheme == .dark {
            return [.white.opacity(top), .white.opacity(bottom)]
        }
        // У світлій темі скло не «підсвічує» тло, а згущує його до білого,
        // інакше матеріал читається як брудна пляма.
        return [.white.opacity(0.78 + top), .white.opacity(0.44 + bottom)]
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
    var tinted: Color?

    @Environment(\.colorScheme) private var scheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    func body(content: Content) -> some View {
        let shadow = tier.shadow
        return content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: tinted.map { [$0.opacity(0.90), $0.opacity(0.55)] }
                                    ?? tier.fill(scheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: tinted != nil
                                    ? [.white.opacity(0.55), .white.opacity(0.18)]
                                    : tier.stroke(scheme),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
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

extension View {
    /// Скляна поверхня. `tinted` заливає її акцентом — для головної дії.
    func glass(_ tier: GlassTier, radius: CGFloat, tinted: Color? = nil) -> some View {
        modifier(GlassSurface(tier: tier, radius: radius, tinted: tinted))
    }
}

/// Кольорове поле, яке скло заломлює. Без насиченого тла матеріал не видно —
/// на рівному сірому він виглядає просто брудним.
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Palette.inkDark : Palette.inkLight)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    bloom(Palette.violet, 0.50, CGSize(width: w * 1.15, height: h * 0.60))
                        .position(x: w * 0.12, y: h * -0.02)
                    bloom(Palette.teal, 0.36, CGSize(width: w * 1.00, height: h * 0.48))
                        .position(x: w * 0.96, y: h * 0.14)
                    bloom(Palette.pink, 0.38, CGSize(width: w * 1.05, height: h * 0.50))
                        .position(x: w * 0.74, y: h * 0.98)
                    bloom(Palette.amber, 0.26, CGSize(width: w * 0.90, height: h * 0.42))
                        .position(x: w * 0.02, y: h * 0.86)
                }
                .blur(radius: 26)
            }
        }
        .ignoresSafeArea()
    }

    private func bloom(_ color: Color, _ opacity: Double, _ size: CGSize) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(scheme == .dark ? opacity : opacity * 0.92),
                        color.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) / 2
                )
            )
            .frame(width: size.width, height: size.height)
    }
}
