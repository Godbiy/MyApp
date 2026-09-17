import SwiftUI

struct SettingsPane: View {
    let store: NoteStore
    @Bindable var settings: Settings

    @State private var confirmWipe = false

    var body: some View {
        ScrollView {
            VStack(spacing: 11) {
                appearanceGroup
                backgroundGroup
                glassGroup
                dataGroup
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 132)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Стерти все?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Стерти", role: .destructive) { store.wipe() }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Зникнуть усі нотатки й теки на цьому пристрої. Скасувати буде неможливо.")
        }
    }

    // MARK: - Групи

    private var appearanceGroup: some View {
        group("Вигляд") {
            setting("Тема") {
                Picker("Тема", selection: $settings.theme) {
                    ForEach(ThemeChoice.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
            }

            setting("Акцент", hint: "Колір кнопок і галочок. Теки лишаються при своїх кольорах.") {
                HStack(spacing: 10) {
                    ForEach(Array(Settings.presets.enumerated()), id: \.offset) { _, color in
                        Button {
                            settings.accent = color
                        } label: {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(.primary, lineWidth: isPicked(color) ? 2.5 : 0)
                                }
                                .scaleEffect(isPicked(color) ? 1.08 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: settings.accent)
            }
        }
    }

    private var backgroundGroup: some View {
        group("Тло") {
            setting("Швидкість", value: settings.speedTitle,
                    hint: "На нулі кольори завмирають. Заряд батареї це теж помітить.") {
                Slider(
                    value: Binding(
                        get: { Double(settings.bgSpeed) },
                        set: { settings.bgSpeed = Int($0.rounded()) }
                    ),
                    in: 0...4, step: 1
                )
            }

            setting("Насиченість", value: "\(Int(settings.bgIntensity * 100))%") {
                Slider(value: $settings.bgIntensity, in: 0...1.4, step: 0.05)
            }

            setting("Сід",
                    hint: "Сід задає кольори й розташування плям. Те саме число завжди дає те саме тло — запам'ятай, якщо сподобалось.") {
                HStack(spacing: 10) {
                    Text("#\(settings.bgSeed)")
                        .font(.system(size: 16, weight: .bold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.primary.opacity(0.07))
                        }
                    Button {
                        settings.shuffleBackground()
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "shuffle").font(.system(size: 14, weight: .bold))
                            Text("Інше").font(.system(size: 15, weight: .bold))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                    }
                    .buttonStyle(PressScale(scale: 0.95))
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.primary.opacity(0.07))
                    }
                }
            }
        }
    }

    private var glassGroup: some View {
        group("Скло й рух") {
            setting("Щільність скла", value: "\(Int(settings.glass * 100))%",
                    hint: "Наліво — панелі майже прозорі й тло проступає наскрізь. Направо — матове скло.") {
                Slider(value: $settings.glass, in: 0.2...1.6, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $settings.motion) {
                    Text("Анімації").font(.system(size: 15, weight: .bold))
                }
                Text("Вимикає переходи, каскади й рух тла.")
                    .font(.skloSettingHint)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataGroup: some View {
        group("Дані") {
            Text("\(store.notes.count) \(Declension.nominative(store.notes.count)) на цьому пристрої. Нічого нікуди не надсилається.")
                .font(.skloSettingHint)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Стерти все") { confirmWipe = true }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xFF4D6D), Color(hex: 0xC31F41)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .buttonStyle(.plain)
        }
    }

    // MARK: - Будівельні блоки

    private func isPicked(_ color: Color) -> Bool {
        color.hexValue == settings.accent.hexValue
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 12.5, weight: .bold))
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 18, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.thin, radius: 24)
    }

    private func setting<Content: View>(
        _ label: String,
        value: String? = nil,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.system(size: 15, weight: .bold))
                Spacer(minLength: 12)
                if let value {
                    Text(value)
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            content()
            if let hint {
                Text(hint)
                    .font(.skloSettingHint)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
