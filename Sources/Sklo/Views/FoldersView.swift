import SwiftUI

struct FoldersView: View {
    let store: NoteStore
    @Binding var tab: RootView.Tab
    @Binding var selected: Folder?

    @State private var isAdding = false
    @State private var newName = ""
    @State private var newAccent: Accent = .violet

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 2)

                ScrollView {
                    VStack(alignment: .leading, spacing: 11) {
                        Text("Мої теки")
                            .font(.system(size: 12.5, weight: .bold))
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        if store.folders.isEmpty {
                            Text("Тек поки немає. Створи першу кнопкою «+».")
                                .font(.skloPreview)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 9) {
                                ForEach(store.folders) { folder in
                                    row(folder)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 128)
                }
            }

            dock
                .padding(.bottom, 10)
        }
        .alert("Нова тека", isPresented: $isAdding) {
            TextField("Назва", text: $newName)
            Button("Створити") {
                store.addFolder(name: newName, accent: newAccent)
                newName = ""
                newAccent = Accent.allCases.randomElement() ?? .violet
            }
            Button("Скасувати", role: .cancel) { newName = "" }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.notes.count) \(NotesListView.declension(store.notes.count))")
                    .font(.skloEyebrow)
                    .textCase(.uppercase)
                    .kerning(1.4)
                    .foregroundStyle(.secondary)
                Text("Теки")
                    .font(.skloLargeTitle)
                    .kerning(-1)
            }
            Spacer(minLength: 0)
            GlassIconButton(systemName: "plus") { isAdding = true }
        }
    }

    private func row(_ folder: Folder) -> some View {
        Button {
            selected = folder
            tab = .notes
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [folder.accent.color, folder.accent.color.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.system(size: 16, weight: .bold))
                    Text(store.latestTitle(in: folder) ?? "Порожня тека")
                        .font(.system(size: 12.5, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(store.count(in: folder))")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glass(.thin, radius: 20)
        .contextMenu {
            Button(role: .destructive) {
                store.deleteFolder(folder.id)
            } label: {
                Label("Видалити теку", systemImage: "trash")
            }
        }
    }

    private var dock: some View {
        FloatingDock(items: [
            .init(systemName: "list.bullet", isActive: false) { tab = .notes },
            .init(systemName: "folder.fill", isActive: true) { tab = .folders },
            .init(systemName: "magnifyingglass", isActive: false) { tab = .notes },
        ]) {
            PrimaryCircleButton(systemName: "plus", tint: selected?.accent.color ?? Palette.violet) {
                isAdding = true
            }
        }
    }
}
