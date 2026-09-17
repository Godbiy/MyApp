import SwiftUI

/// Той самий генератор, що й у веб-версії: сід однозначно задає тло, тож
/// число можна запам'ятати й повернути ту саму картинку.
struct SeededRandom {
    private var state: UInt32

    init(seed: Int) {
        let mixed = UInt32(truncatingIfNeeded: seed &* 2_654_435_761)
        state = mixed == 0 ? 1 : mixed
    }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return Double(state) / Double(UInt32.max)
    }

    mutating func next(_ lower: Double, _ upper: Double) -> Double {
        lower + next() * (upper - lower)
    }
}

private struct Bloom: Identifiable {
    let id: Int
    let hue: Double
    let size: CGSize
    /// Частка від сторони — щоб тло однаково працювало на будь-якому екрані.
    let anchor: CGPoint
    let opacity: Double
    let travel: CGSize
    let period: Double
}

/// Кольорове поле, яке скло заломлює. Без насиченого тла матеріал не видно —
/// на рівному сірому він виглядає просто брудним.
struct AmbientBackground: View {
    var seed: Int
    var speed: Int
    var intensity: Double
    var motion: Bool

    @Environment(\.colorScheme) private var scheme
    @State private var drifting = false

    private var blooms: [Bloom] {
        var rng = SeededRandom(seed: seed)
        let baseHue = rng.next() * 360
        // Періоди взаємно прості, щоб візерунок не повторювався тим самим циклом.
        let periods: [Double] = [34, 43, 37, 47]
        return (0..<4).map { i in
            let hue = (baseHue + Double(i) * rng.next(70, 120)).truncatingRemainder(dividingBy: 360)
            let w = rng.next(0.9, 1.5)
            let h = w * rng.next(0.72, 1.18)
            // Карусель удвічі більша за екран, тож видима його частина — це
            // лише середина. Плями поза нею просто не видно.
            let ax = rng.next(0.34, 0.66)
            let ay = rng.next(0.34, 0.66)
            let op = rng.next(0.38, 0.60)
            let tx = rng.next(-0.18, 0.18)
            let ty = rng.next(-0.14, 0.14)
            return Bloom(
                id: i, hue: hue,
                size: CGSize(width: w, height: h),
                anchor: CGPoint(x: ax, y: ay),
                opacity: op,
                travel: CGSize(width: tx, height: ty),
                period: periods[i]
            )
        }
    }

    private var base: Color {
        scheme == .dark ? Palette.inkDark : Palette.inkLight
    }

    private var spinDuration: Double {
        speed <= 0 ? 0 : 190 / Double(speed)
    }

    var body: some View {
        GeometryReader { geo in
            let side = max(geo.size.width, geo.size.height)
            let canvas = side * 2

            ZStack {
                base
                ZStack {
                    ForEach(blooms) { bloom in
                        bloomView(bloom, canvas: canvas)
                    }
                }
                .frame(width: canvas, height: canvas)
                .rotationEffect(.degrees(drifting && animating ? 360 : 0))
                .animation(
                    animating ? .linear(duration: spinDuration).repeatForever(autoreverses: false) : nil,
                    value: drifting
                )
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        // Зміна сіда чи швидкості перезапускає анімації з нуля.
        .id("\(seed)-\(speed)-\(motion)")
        .onAppear { drifting = true }
    }

    private var animating: Bool { motion && speed > 0 }

    private func bloomView(_ bloom: Bloom, canvas: CGFloat) -> some View {
        let w = canvas * bloom.size.width * 0.5
        let h = canvas * bloom.size.height * 0.5
        let dx = canvas * bloom.travel.width * (drifting && animating ? 1 : 0)
        let dy = canvas * bloom.travel.height * (drifting && animating ? 1 : 0)
        let scale = drifting && animating ? 1.22 : 0.9
        let duration = speed > 0 ? bloom.period / Double(speed) : bloom.period

        return Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hue: bloom.hue / 360, saturation: 0.92, brightness: 0.62)
                            .opacity(bloom.opacity * intensity),
                        Color(hue: bloom.hue / 360, saturation: 0.92, brightness: 0.62)
                            .opacity(0),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(w, h) / 2
                )
            )
            .frame(width: w, height: h)
            .scaleEffect(scale)
            .offset(x: dx, y: dy)
            .position(x: canvas * bloom.anchor.x, y: canvas * bloom.anchor.y)
            .blur(radius: 50)
            .animation(
                animating
                    ? .easeInOut(duration: duration).repeatForever(autoreverses: true)
                    : nil,
                value: drifting
            )
    }
}

/// Дрібна крупа поверх тла — прибирає смугастість градієнтів.
struct GrainOverlay: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if scheme == .dark {
            Canvas { context, size in
                var rng = SeededRandom(seed: 99)
                let step: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    var x: CGFloat = 0
                    while x < size.width {
                        if rng.next() > 0.55 {
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.white.opacity(0.05))
                            )
                        }
                        x += step
                    }
                    y += step
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}
