import SwiftUI

struct NotesPane: View {
    let store: NoteStore
    @Binding var folder: Folder?
    var query: String
    var open: (UUID) -> Void
    var newFolder: () -> Void

    @State private var pendingDelete: Note?

    private var notes: [Note] {
        store.visible(folder: folder, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            chips
            list
        }
        .confirmationDialog(
            "Видалити нотатку?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let note = pendingDelete {
                Button("Видалити", role: .destructive) { store.delete(note.id) }
                Button("Скасувати", role: .cancel) {}
            }
        } message: {
            if let note = pendingDelete {
                Text("«\(note.displayTitle)» зникне назавжди.")
            }
        }
    }

    // MARK: - Чіпи тек

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "Усі", active: folder == nil) { folder = nil }
                ForEach(store.folders) { f in
                    chip(title: f.name, active: folder?.id == f.id) {
                        folder = folder?.id == f.id ? nil : f
                    }
                }
                Button(action: newFolder) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        Text("Тека").font(.skloLabel)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                }
                .buttonStyle(PressScale(scale: 0.92))
                .flatGlass(radius: 19)
            }
            // Відступ зсередини, щоб край прокрутки збігався з краєм карток
            // і чіпи ховались рівно під ним, а не бігли до краю екрана.
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.skloLabel)
                .foregroundStyle(active ? Color.black.opacity(0.88) : Color.primary.opacity(0.7))
                .padding(.horizontal, 17)
                .frame(height: 38)
        }
        .buttonStyle(PressScale(scale: 0.92))
        .background {
            if active {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.82))
                    .overlay {
                        Capsule(style: .continuous).strokeBorder(.white.opacity(0.5), lineWidth: 1)
                    }
            }
        }
        .flatGlass(radius: 19)
        .animation(.snappy(duration: 0.22), value: active)
    }

    // MARK: - Список

    @ViewBuilder
    private var list: some View {
        if notes.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 11) {
                    ForEach(notes) { note in
                        Button {
                            open(note.id)
                        } label: {
                            NoteCard(
                                note: note,
                                accent: store.folder(note.folderID)?.accent.color ?? Palette.violet,
                                folderName: store.folder(note.folderID)?.name
                            )
                        }
                        .buttonStyle(PressScale(scale: 0.975))
                        // На iOS довге утримання — це контекстне меню. Воно ще й
                        // піднімає саму картку, тож видно, з чим працюєш.
                        .contextMenu {
                            Button {
                                store.togglePin(note.id)
                            } label: {
                                Label(note.isPinned ? "Відкріпити" : "Закріпити", systemImage: "pin")
                            }
                            Button(role: .destructive) {
                                pendingDelete = note
                            } label: {
                                Label("Видалити", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 132)
            }
            .scrollIndicators(.hidden)
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
}
