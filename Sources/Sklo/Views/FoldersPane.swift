import SwiftUI

struct FoldersPane: View {
    let store: NoteStore
    @Binding var selected: Folder?
    @Binding var pane: Int

    @State private var pendingDelete: Folder?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 11) {
                Text("Мої теки")
                    .font(.system(size: 12.5, weight: .bold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                if store.folders.isEmpty {
                    Text("Тек поки немає. Створи першу великою кнопкою внизу.")
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
            .padding(.bottom, 132)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog(
            pendingDelete.map(\.name) ?? "",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let folder = pendingDelete {
                Button("Видалити теку", role: .destructive) {
                    if selected?.id == folder.id { selected = nil }
                    store.deleteFolder(folder.id)
                }
                Button("Скасувати", role: .cancel) {}
            }
        } message: {
            if let folder = pendingDelete {
                let count = store.count(in: folder)
                Text(count > 0
                     ? "Нотатки (\(count)) лишаться, але без теки."
                     : "Тека порожня.")
            }
        }
    }

    private func row(_ folder: Folder) -> some View {
        Button {
            selected = folder
            pane = 0
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [folder.accent.color, folder.accent.color.opacity(0.72)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
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
        .buttonStyle(PressScale(scale: 0.975))
        .glass(.thin, radius: 20)
        .contextMenu {
            Button(role: .destructive) {
                pendingDelete = folder
            } label: {
                Label("Видалити теку", systemImage: "trash")
            }
        }
    }
}

/// Аркуш створення теки: назва плюс колір, щоб теки різнились з першого погляду.
struct NewFolderSheet: View {
    let store: NoteStore
    var onCreate: (Folder) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var accent: Accent = .violet
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Нова тека")
                .font(.system(size: 20, weight: .heavy))
                .kerning(-0.4)

            TextField("Назва", text: $name)
                .font(.system(size: 17))
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.primary.opacity(0.07))
                }
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(create)

            HStack(spacing: 10) {
                ForEach(Accent.allCases) { option in
                    Button {
                        accent = option
                    } label: {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(option.color)
                            .frame(width: 44, height: 44)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.primary, lineWidth: accent == option ? 2.5 : 0)
                            }
                            .scaleEffect(accent == option ? 1.06 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: accent)

            HStack(spacing: 10) {
                Button("Скасувати") { dismiss() }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.primary.opacity(0.07))
                    }
                Button("Створити", action: create)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accent.color)
                    }
            }
            .font(.system(size: 16, weight: .bold))
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(300)])
        .presentationBackground(.thickMaterial)
        .onAppear {
            // Беремо колір, якого ще немає, — теки мають різнитись одразу.
            let used = Set(store.folders.map(\.accent))
            accent = Accent.allCases.first { !used.contains($0) } ?? .violet
            focused = true
        }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folder = store.addFolder(name: trimmed, accent: accent)
        dismiss()
        if let folder { onCreate(folder) }
    }
}
