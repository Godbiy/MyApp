import SwiftUI

/// Плаваюча панель. Єдине, що рухається внизу, — кружок за активним пунктом;
/// сама панель стоїть намертво, як і шапка.
struct Dock: View {
    @Binding var pane: Int
    @Binding var searching: Bool
    @Binding var query: String
    var accent: Color
    var noteCount: Int
    var onPrimary: () -> Void

    @FocusState private var searchFocused: Bool

    /// Позиція кружка: 0 — нотатки, 1 — теки, 2 — пошук, 3 — налаштування.
    private var indicator: Int {
        if searching { return 2 }
        return pane == 0 ? 0 : (pane == 1 ? 1 : 3)
    }

    var body: some View {
        HStack(spacing: 10) {
            bar
            primaryButton
        }
        .padding(.horizontal, 20)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            dockButton("list.bullet", index: 0) { go(0) }
            dockButton("folder", index: 1) { go(1) }
            dockButton("magnifyingglass", index: 2) { startSearch() }
            dockButton("slider.horizontal.3", index: 3) { go(2) }
        }
        .padding(.horizontal, 8)
        .frame(height: 62)
        .opacity(searching ? 0 : 1)
        // Кружок живе у підкладці: GeometryReader там отримує розмір самої
        // панелі й не ламає розкладку кнопок, як ламав би всередині HStack.
        .background(alignment: .leading) {
            GeometryReader { geo in
                let slot = (geo.size.width - 16) / 4
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(.primary.opacity(0.12))
                    .frame(width: slot, height: 46)
                    .offset(x: 8 + slot * CGFloat(indicator), y: (geo.size.height - 46) / 2)
                    .opacity(searching ? 0 : 1)
            }
        }
        .overlay {
            if searching {
                searchField.padding(8)
            }
        }
        .glass(.thick, radius: 31, blurred: true)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: indicator)
        .animation(.easeInOut(duration: 0.24), value: searching)
    }

    private func dockButton(_ name: String, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(indicator == index ? Color.primary : Color.primary.opacity(0.45))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScale(scale: 0.86))
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Пошук у \(noteCount) \(Declension.locative(noteCount))", text: $query)
                .font(.system(size: 16, weight: .medium))
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(.primary.opacity(0.12))
        }
        .onAppear { searchFocused = true }
    }

    /// «+» довертається на 45° і стає «×» — та сама кнопка, інша роль.
    private var primaryButton: some View {
        Button {
            if searching { stopSearch() } else { onPrimary() }
        } label: {
            Image(systemName: primaryIcon)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(searching ? 45 : 0))
                .frame(width: 62, height: 62)
        }
        .buttonStyle(PressScale(scale: 0.9))
        .glass(.thick, radius: 31, blurred: true, tinted: accent)
        .animation(.spring(response: 0.34, dampingFraction: 0.7), value: searching)
        .animation(.easeInOut(duration: 0.28), value: pane)
    }

    private var primaryIcon: String {
        if searching { return "plus" }
        switch pane {
        case 1: return "folder.badge.plus"
        case 2: return "shuffle"
        default: return "plus"
        }
    }

    private func go(_ index: Int) {
        if searching { stopSearch() }
        pane = index
    }

    private func startSearch() {
        pane = 0
        searching = true
    }

    private func stopSearch() {
        searchFocused = false
        query = ""
        searching = false
    }
}

/// Натиск відгукується стисканням — без цього скляні кнопки здаються мертвими.
struct PressScale: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
