import SwiftUI

struct NoteEditorView: View {
    let store: NoteStore
    let noteID: UUID
    var onClose: () -> Void

    @State private var draft: Note
    @State private var confirmingDelete = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title, body, item(UUID)
    }

    init(store: NoteStore, noteID: UUID, onClose: @escaping () -> Void) {
        self.store = store
        self.noteID = noteID
        self.onClose = onClose
        _draft = State(initialValue: store.note(noteID) ?? Note())
    }

    private var accent: Color {
        store.folder(draft.folderID)?.accent.color ?? Palette.violet
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                nav
                    .padding(.horizontal, 20)
                    .padding(.top, 2)

                ScrollView {
                    paper
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 132)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            dock
                .padding(.bottom, 10)
        }
        .onChange(of: draft) { _, new in
            store.update(new)
        }
        .onDisappear {
            store.discardIfEmpty(noteID)
        }
        .confirmationDialog("Видалити нотатку?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Видалити", role: .destructive) {
                store.delete(noteID)
                onClose()
            }
            Button("Скасувати", role: .cancel) {}
        }
    }

    // MARK: - Шапка

    private var nav: some View {
        HStack(spacing: 10) {
            Button {
                onClose()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text(store.folder(draft.folderID)?.name ?? "Нотатки")
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            .glass(.regular, radius: 22)

            Spacer(minLength: 0)

            GlassIconButton(
                systemName: draft.isPinned ? "pin.fill" : "pin",
                tint: draft.isPinned ? accent : nil
            ) {
                draft.isPinned.toggle()
            }

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glass(.regular, radius: 22)
        }
    }

    private var shareText: String {
        var parts = [draft.displayTitle]
        let body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty { parts.append(body) }
        let items = draft.items
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { ($0.isDone ? "☑ " : "☐ ") + $0.text }
        if !items.isEmpty { parts.append(items.joined(separator: "\n")) }
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Аркуш

    private var paper: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(draft.updatedAt.skloFullStamp)
                .font(.skloEyebrow)
                .textCase(.uppercase)
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)

            TextField("Заголовок", text: $draft.title, axis: .vertical)
                .font(.skloTitle)
                .kerning(-0.7)
                .focused($focusedField, equals: .title)
                .padding(.bottom, 14)

            TextField("Почни писати…", text: $draft.body, axis: .vertical)
                .font(.skloBody)
                .lineSpacing(5)
                .foregroundStyle(.primary.opacity(0.86))
                .focused($focusedField, equals: .body)

            if !draft.items.isEmpty {
                VStack(spacing: 11) {
                    ForEach($draft.items) { $item in
                        checklistRow($item)
                    }
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 24, leading: 22, bottom: 26, trailing: 22))
        .glass(.regular, radius: 30)
    }

    private func checklistRow(_ item: Binding<ChecklistItem>) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Button {
                item.wrappedValue.isDone.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.wrappedValue.isDone ? accent : Color.primary.opacity(0.09))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    item.wrappedValue.isDone ? .white.opacity(0.4) : .primary.opacity(0.26),
                                    lineWidth: 1
                                )
                        }
                    if item.wrappedValue.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 23, height: 23)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            TextField("Пункт", text: item.text, axis: .vertical)
                .font(.skloChecklist)
                .foregroundStyle(.primary.opacity(item.wrappedValue.isDone ? 0.4 : 0.82))
                .strikethrough(item.wrappedValue.isDone, color: .primary.opacity(0.4))
                .focused($focusedField, equals: .item(item.wrappedValue.id))
                .onSubmit { addItem() }

            if !item.wrappedValue.text.isEmpty || draft.items.count > 1 {
                Button {
                    let id = item.wrappedValue.id
                    draft.items.removeAll { $0.id == id }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 3)
            }
        }
    }

    // MARK: - Панель

    private var dock: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                dockButton("checklist") { addItem() }
                dockButton(focusedField == nil ? "textformat" : "keyboard.chevron.compact.down") {
                    if focusedField == nil {
                        focusedField = .body
                    } else {
                        focusedField = nil
                    }
                }
                dockButton("trash") { confirmingDelete = true }
            }
            .padding(.horizontal, 6)
            .frame(height: 58)
            .glass(.thick, radius: 29)

            Button {
                focusedField = nil
                onClose()
            } label: {
                Text("Готово")
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 58)
            }
            .buttonStyle(.plain)
            .glass(.thick, radius: 29, tinted: accent)
        }
        .padding(.horizontal, 20)
    }

    private func dockButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary.opacity(0.88))
                .frame(width: 46, height: 44)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func addItem() {
        let item = ChecklistItem(text: "")
        draft.items.append(item)
        focusedField = .item(item.id)
    }
}
