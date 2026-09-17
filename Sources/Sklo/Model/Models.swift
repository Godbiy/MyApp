import Foundation

struct ChecklistItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String
    var isDone: Bool = false
}

struct Folder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var accent: Accent
}

struct Note: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var body: String = ""
    var folderID: UUID?
    var isPinned: Bool = false
    var createdAt: Date = .now
    var updatedAt: Date = .now
    var items: [ChecklistItem] = []

    /// Заголовок для списку. Порожня нотатка не має показуватись безіменним
    /// рядком — беремо перший рядок тексту, і лише потім здаємось.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = body
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map { String($0) }?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstLine, !firstLine.isEmpty { return firstLine }
        return "Без назви"
    }

    /// Прев'ю під заголовком: текст, а якщо його немає — самі пункти списку,
    /// щоб картка чеклиста не виглядала порожньою.
    var preview: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed.replacingOccurrences(of: "\n", with: " ")
        }
        if !items.isEmpty {
            return items.map(\.text).joined(separator: " · ")
        }
        return "Порожня нотатка"
    }

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && items.allSatisfy { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        if title.localizedCaseInsensitiveContains(q) { return true }
        if body.localizedCaseInsensitiveContains(q) { return true }
        return items.contains { $0.text.localizedCaseInsensitiveContains(q) }
    }
}

extension Date {
    /// Час для картки: сьогоднішні нотатки показують годину, старіші — дату.
    var skloShortStamp: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        if cal.isDateInToday(self) {
            f.dateFormat = "HH:mm"
        } else if cal.isDateInYesterday(self) {
            return "Учора"
        } else if cal.isDate(self, equalTo: .now, toGranularity: .year) {
            f.dateFormat = "d MMM"
        } else {
            f.dateFormat = "dd.MM.yy"
        }
        return f.string(from: self)
    }

    var skloFullStamp: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        if cal.isDateInToday(self) {
            f.dateFormat = "'Сьогодні' · HH:mm"
        } else if cal.isDateInYesterday(self) {
            f.dateFormat = "'Учора' · HH:mm"
        } else {
            f.dateFormat = "d MMMM · HH:mm"
        }
        return f.string(from: self)
    }

    var skloWeekdayLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: self).capitalizedFirst
    }
}

/// Українська потребує різних форм числа. Тримаємо їх в одному місці, бо
/// про них легко забути там, де число підставляється в рядок.
enum Declension {
    /// Місцевий відмінок: «у 1 нотатці», але «у 2 / 11 / 25 нотатках».
    static func locative(_ n: Int) -> String {
        (n % 10 == 1 && n % 100 != 11) ? "нотатці" : "нотатках"
    }

    /// Називний: 1 нотатка, 2 нотатки, 5 нотаток.
    static func nominative(_ n: Int) -> String {
        let m100 = n % 100, m10 = n % 10
        if (11...14).contains(m100) { return "нотаток" }
        if m10 == 1 { return "нотатка" }
        if (2...4).contains(m10) { return "нотатки" }
        return "нотаток"
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
