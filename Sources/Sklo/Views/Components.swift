import SwiftUI

/// Кругла скляна кнопка з іконкою. 44×44 — мінімальна ціль дотику за HIG.
struct GlassIconButton: View {
    let systemName: String
    var tint: Color?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint ?? .primary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glass(.regular, radius: 22)
    }
}

/// Рядок чіпів тек. «Усі» завжди перший і не видаляється.
struct FolderChips: View {
    let folders: [Folder]
    @Binding var selection: Folder?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "Усі", isActive: selection == nil) { selection = nil }
                ForEach(folders) { folder in
                    chip(title: folder.name, isActive: selection?.id == folder.id) {
                        selection = selection?.id == folder.id ? nil : folder
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollClipDisabled()
    }

    private func chip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.skloLabel)
                .foregroundStyle(isActive ? Color.black.opacity(0.88) : Color.primary.opacity(0.72))
                .padding(.horizontal, 17)
                .frame(height: 38)
        }
        .buttonStyle(.plain)
        .background {
            if isActive {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.82))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
            }
        }
        .glass(.thin, radius: 19)
        .animation(.snappy(duration: 0.22), value: isActive)
    }
}

struct SearchField: View {
    @Binding var text: String
    var placeholder: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15.5, weight: .medium))
                .textInputAutocapitalization(.sentences)
                .submitLabel(.search)
                .focused(focus)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .glass(.regular, radius: 23)
    }
}

struct NoteCard: View {
    let note: Note
    let accent: Color
    let folderName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                }
                Text(note.displayTitle)
                    .font(.skloNoteTitle)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(note.updatedAt.skloShortStamp)
                    .font(.skloCaption)
                    .foregroundStyle(.secondary)
            }

            Text(note.preview)
                .font(.skloPreview)
                .foregroundStyle(.primary.opacity(0.62))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let folderName {
                HStack(spacing: 7) {
                    Circle()
                        .fill(accent)
                        .frame(width: 6, height: 6)
                    Text(folderName)
                        .font(.skloEyebrow)
                        .foregroundStyle(.primary.opacity(0.48))
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 15, leading: 16, bottom: 14, trailing: 16))
        .glass(.thin, radius: 23)
        .overlay {
            if note.isPinned {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(accent.opacity(0.45), lineWidth: 1)
            }
        }
    }
}

/// Плаваюча панель знизу — єдиний елемент, що завжди поверх контенту.
struct FloatingDock<Trailing: View>: View {
    let items: [DockItem]
    @ViewBuilder var trailing: Trailing

    struct DockItem: Identifiable {
        var id: String { systemName }
        let systemName: String
        let isActive: Bool
        let action: () -> Void
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    Button(action: item.action) {
                        Image(systemName: item.systemName)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(item.isActive ? Color.primary : Color.primary.opacity(0.5))
                            .frame(width: 50, height: 46)
                            .background {
                                if item.isActive {
                                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                                        .fill(.primary.opacity(0.12))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 62)
            .glass(.thick, radius: 31)

            trailing
        }
        .padding(.horizontal, 20)
    }
}

/// Кругла акцентна кнопка головної дії.
struct PrimaryCircleButton: View {
    let systemName: String
    let tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
        }
        .buttonStyle(.plain)
        .glass(.thick, radius: 31, tinted: tint)
    }
}
