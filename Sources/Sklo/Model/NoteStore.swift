import Foundation
import Observation

/// Сховище нотаток. Свідомо просте: увесь стан — один JSON-файл у Application
/// Support, який пишеться повністю на кожну зміну. Для записника на кількасот
/// нотаток це дешевше й передбачуваніше за базу, і не тягне за собою міграцій
/// схеми, які нема де відлагоджувати.
@Observable
final class NoteStore {
    private(set) var notes: [Note] = []
    private(set) var folders: [Folder] = []

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private var isLoaded = false

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    // MARK: - Читання

    var pinned: [Note] {
        notes.filter(\.isPinned).sorted { $0.updatedAt > $1.updatedAt }
    }

    var unpinned: [Note] {
        notes.filter { !$0.isPinned }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func note(_ id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func folder(_ id: UUID?) -> Folder? {
        guard let id else { return nil }
        return folders.first { $0.id == id }
    }

    func count(in folder: Folder) -> Int {
        notes.filter { $0.folderID == folder.id }.count
    }

    func latestTitle(in folder: Folder) -> String? {
        notes
            .filter { $0.folderID == folder.id }
            .max { $0.updatedAt < $1.updatedAt }?
            .displayTitle
    }

    /// Список для головного екрана: спершу фільтр теки, потім пошук,
    /// закріплені завжди зверху.
    func visible(folder: Folder?, query: String) -> [Note] {
        notes
            .filter { folder == nil || $0.folderID == folder?.id }
            .filter { $0.matches(query) }
            .sorted {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.updatedAt > $1.updatedAt
            }
    }

    // MARK: - Зміни

    @discardableResult
    func createNote(in folder: Folder? = nil) -> Note {
        let note = Note(folderID: folder?.id)
        notes.append(note)
        save()
        return note
    }

    func update(_ note: Note) {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        guard notes[idx] != note else { return }
        var copy = note
        copy.updatedAt = .now
        notes[idx] = copy
        save()
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    func togglePin(_ id: UUID) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].isPinned.toggle()
        notes[idx].updatedAt = .now
        save()
    }

    func toggleItem(noteID: UUID, itemID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }),
              let i = notes[n].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[n].items[i].isDone.toggle()
        notes[n].updatedAt = .now
        save()
    }

    func addItem(noteID: UUID) {
        guard let n = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[n].items.append(ChecklistItem(text: ""))
        notes[n].updatedAt = .now
        save()
    }

    /// Прибирає нотатку, яку відкрили й закрили, нічого не написавши.
    /// Інакше кожен випадковий тап по «+» лишає сміття в списку.
    func discardIfEmpty(_ id: UUID) {
        guard let note = note(id), note.isEmpty else { return }
        delete(id)
    }

    @discardableResult
    func addFolder(name: String, accent: Accent) -> Folder? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let folder = Folder(name: trimmed, accent: accent)
        folders.append(folder)
        save()
        return folder
    }

    /// Повне стирання з наступним засівом — щоб екран не лишився порожнім
    /// без жодного пояснення.
    func wipe() {
        notes = []
        folders = []
        seed()
    }

    func deleteFolder(_ id: UUID) {
        folders.removeAll { $0.id == id }
        // Нотатки переживають свою теку — просто лишаються без неї.
        for idx in notes.indices where notes[idx].folderID == id {
            notes[idx].folderID = nil
        }
        save()
    }

    // MARK: - Диск

    private struct Payload: Codable {
        var notes: [Note]
        var folders: [Folder]
    }

    private static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        return dir.appendingPathComponent("sklo-notes.json")
    }

    private func load() {
        defer { isLoaded = true }
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            seed()
            return
        }
        notes = payload.notes
        folders = payload.folders
        if folders.isEmpty { folders = Self.defaultFolders() }
    }

    private func save() {
        guard isLoaded else { return }
        let payload = Payload(notes: notes, folders: folders)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFolders() -> [Folder] {
        [
            Folder(name: "Ідеї", accent: .violet),
            Folder(name: "Робота", accent: .teal),
            Folder(name: "Побут", accent: .amber),
            Folder(name: "Особисте", accent: .pink),
        ]
    }

    /// Перший запуск. Одна нотатка, яка пояснює застосунок собою ж, —
    /// краще за порожній екран і за окремий екран привітання.
    private func seed() {
        let defaults = Self.defaultFolders()
        folders = defaults

        var hello = Note(
            title: "Вітаю у Склі",
            body: """
            Це звичайна нотатка — гортай, правь, видаляй.

            Гортай пальцем ліворуч, щоб перейти до тек і налаштувань. Тапни «+» унизу, щоб написати свою.
            """,
            folderID: defaults.first?.id,
            isPinned: true
        )
        hello.items = [
            ChecklistItem(text: "Написати першу нотатку"),
            ChecklistItem(text: "Створити свою теку"),
            ChecklistItem(text: "Покрутити тло в налаштуваннях"),
        ]

        notes = [hello]
        isLoaded = true
        save()
    }
}
