import SwiftUI

struct RootView: View {
    enum Tab {
        case notes, folders
    }

    @State private var store = NoteStore()
    @State private var tab: Tab = .notes
    @State private var openNote: UUID?
    @State private var folder: Folder?

    var body: some View {
        ZStack {
            AmbientBackground()

            // Редактор не штовхається в NavigationStack: він займає весь екран
            // і має власну панель, тож простий перехід між двома станами
            // чесніший за навігаційний стек з прихованим тулбаром.
            Group {
                if let id = openNote {
                    NoteEditorView(store: store, noteID: id) {
                        openNote = nil
                    }
                    .id(id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    switch tab {
                    case .notes:
                        NotesListView(store: store, tab: $tab, openNote: $openNote, folder: $folder)
                            .transition(.opacity)
                    case .folders:
                        FoldersView(store: store, tab: $tab, selected: $folder)
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.3), value: openNote)
        .animation(.easeInOut(duration: 0.2), value: tab)
        .tint(Palette.violet)
    }
}

#Preview {
    RootView()
}
