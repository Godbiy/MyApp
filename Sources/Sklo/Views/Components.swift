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
        .buttonStyle(PressScale(scale: 0.92))
        .glass(.regular, radius: 22, blurred: true)
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
        // Картки лежать просто на розмитому тлі, тож власне розмиття їм нічого
        // не додає, а коштує окремого шару на кожну — на цьому дохне прокрутка.
        .glass(.thin, radius: 23)
        .overlay {
            if note.isPinned {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(accent.opacity(0.45), lineWidth: 1)
            }
        }
    }
}
