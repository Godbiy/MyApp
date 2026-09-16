import SwiftUI

struct NotesListView: View {
    let store: NoteStore
    @Binding var tab: RootView.Tab
    @Binding var openNote: UUID?
    @Binding var folder: Folder?

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var notes: [Note] {
        store.visible(folder: folder, query: query)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 2)

                SearchField(text: $query, placeholder: placeholder, focus: $searchFocused)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                FolderChips(folders: store.folders, selection: $folder)
                    .padding(.top, 14)

                list
            }

            dock
                .padding(.bottom, 10)
        }
    }

    private var placeholder: String {
        let n = store.notes.count
        return "Пошук у \(n) \(Self.declension(n))"
    }

    /// Місцевий відмінок: «у 1 нотатці», але «у 2 / 11 / 25 нотатках».
    static func declension(_ n: Int) -> String {
        let isSingular = n % 10 == 1 && n % 100 != 11
        return isSingular ? "нотатці" : "нотатках"
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.skloWeekdayLine)
                    .font(.skloEyebrow)
                    .textCase(.uppercase)
                    .kerning(1.4)
                    .foregroundStyle(.secondary)
                Text("Нотатки")
                    .font(.skloLargeTitle)
                    .kerning(-1)
            }
            Spacer(minLength: 0)
            GlassIconButton(systemName: "ellipsis") {}
        }
    }

    @ViewBuilder
    private var list: some View {
        if notes.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 11) {
                    ForEach(notes) { note in
                        Button {
                            openNote = note.id
                        } label: {
                            NoteCard(
                                note: note,
                                accent: store.folder(note.folderID)?.accent.color ?? Palette.violet,
                                folderName: store.folder(note.folderID)?.name
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                store.togglePin(note.id)
                            } label: {
                                Label(note.isPinned ? "Відкріпити" : "Закріпити", systemImage: "pin")
                            }
                            Button(role: .destructive) {
                                store.delete(note.id)
                            } label: {
                                Label("Видалити", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 128)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: query.isEmpty ? "square.on.square.dashed" : "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)
            Text(query.isEmpty ? "Тут поки порожньо" : "Нічого не знайшлось")
                .font(.system(size: 17, weight: .bold))
            Text(query.isEmpty
                 ? "Тапни «+», щоб написати першу нотатку."
                 : "Спробуй інші слова або скинь фільтр теки.")
                .font(.skloPreview)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dock: some View {
        FloatingDock(items: [
            .init(systemName: "list.bullet", isActive: true) { tab = .notes },
            .init(systemName: "folder", isActive: false) { tab = .folders },
            .init(systemName: "magnifyingglass", isActive: false) { searchFocused = true },
        ]) {
            PrimaryCircleButton(systemName: "plus", tint: folder?.accent.color ?? Palette.violet) {
                openNote = store.createNote(in: folder).id
            }
        }
    }
}
