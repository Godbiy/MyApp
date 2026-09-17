import SwiftUI

struct RootView: View {
    @State private var store = NoteStore()
    @State private var settings = Settings()

    @State private var pane = 0
    @State private var openNote: UUID?
    @State private var folder: Folder?
    @State private var searching = false
    @State private var query = ""
    @State private var newFolderSheet = false

    private var accent: Color {
        folder.map { $0.accent.color } ?? settings.accent
    }

    var body: some View {
        ZStack {
            AmbientBackground(
                seed: settings.bgSeed,
                speed: settings.bgSpeed,
                intensity: settings.bgIntensity,
                motion: settings.motion
            )
            GrainOverlay()

            shell

            if let id = openNote {
                NoteEditorView(store: store, noteID: id, accent: accent) {
                    openNote = nil
                }
                .id(id)
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }
        }
        .environment(\.glassDensity, settings.glass)
        .preferredColorScheme(settings.theme.colorScheme)
        .tint(settings.accent)
        .animation(settings.motion ? .spring(response: 0.38, dampingFraction: 0.86) : nil, value: openNote)
        .sheet(isPresented: $newFolderSheet) {
            NewFolderSheet(store: store) { created in
                folder = created
                pane = 0
            }
        }
    }

    // MARK: - Каркас
    //
    // Шапка й панель стоять намертво. Рухається лише сторінка між ними —
    // інакше при переході вони їдуть разом з контентом і читаються як ривок.

    private var shell: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .frame(height: searching ? 0 : 68, alignment: .bottom)
                .opacity(searching ? 0 : 1)
                .clipped()
                .animation(settings.motion ? .easeInOut(duration: 0.32) : nil, value: searching)

            pager
        }
        .overlay(alignment: .bottom) {
            Dock(
                pane: $pane,
                searching: $searching,
                query: $query,
                accent: accent,
                noteCount: store.notes.count,
                onPrimary: primaryAction
            )
            .padding(.bottom, 10)
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(headerEyebrow)
                    .font(.skloEyebrow)
                    .textCase(.uppercase)
                    .kerning(1.4)
                    .foregroundStyle(.secondary)
                Text(headerTitle)
                    .font(.skloLargeTitle)
                    .kerning(-1)
            }
            Spacer(minLength: 0)
        }
        // Старий рядок іде вгору рівно тоді, коли новий приходить знизу.
        // Порожньої паузи між ними немає — саме вона й читалась як смикання.
        .id(pane)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(settings.motion ? .easeInOut(duration: 0.3) : nil, value: pane)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerTitle: String {
        switch pane {
        case 1: return "Теки"
        case 2: return "Налаштування"
        default: return "Нотатки"
        }
    }

    private var headerEyebrow: String {
        switch pane {
        case 1: return "\(store.notes.count) \(Declension.nominative(store.notes.count))"
        case 2: return "Скло · записник"
        default: return Date.now.skloWeekdayLine
        }
    }

    private var pager: some View {
        TabView(selection: $pane) {
            NotesPane(store: store, folder: $folder, query: query, open: { openNote = $0 },
                      newFolder: { newFolderSheet = true })
                .tag(0)
            FoldersPane(store: store, selected: $folder, pane: $pane)
                .tag(1)
            SettingsPane(store: store, settings: settings)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func primaryAction() {
        switch pane {
        case 1:
            newFolderSheet = true
        case 2:
            settings.shuffleBackground()
        default:
            openNote = store.createNote(in: folder).id
        }
    }
}

#Preview {
    RootView()
}
