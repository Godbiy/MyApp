import XCTest

/// Прогулянка застосунком для запису відео. Це не перевірка поведінки —
/// це єдиний спосіб побачити рух, коли під рукою немає ні Mac, ні пристрою:
/// симулятору не скажеш «тапни тут», а XCUITest може.
///
/// Паузи тут навмисно щедрі: відео мають дивитись люди, а не машина.
/// Жоден крок не валить тест — обірвана прогулянка все одно дає відео.
final class Walkthrough: XCTestCase {

    // Явний ідентифікатор, а не XCUIApplication() без аргументів: без нього
    // запуск залежить від налаштування цілі, і коли воно не підхопилось,
    // записався домашній екран замість застосунку.
    private let app = XCUIApplication(bundleIdentifier: "com.godbiy.sklo")

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func beat(_ seconds: Double = 1.2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    /// Тапає кнопку з таким підписом, якщо вона є. Мовчки пропускає, якщо ні.
    @discardableResult
    private func tap(_ label: String, wait: Double = 3) -> Bool {
        let button = app.buttons[label]
        guard button.waitForExistence(timeout: wait), button.isHittable else {
            print("пропускаю «\(label)» — не знайшов")
            return false
        }
        button.tap()
        return true
    }

    func testTour() {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "застосунок не вийшов на передній план")
        beat(3)

        // ── Список і фільтр тек ──
        tap("Робота")
        beat()
        tap("Усі")
        beat(1.6)

        // ── Гортання сторінок ──
        app.swipeLeft()
        beat(1.8)
        app.swipeLeft()
        beat(1.8)

        // ── Налаштування ──
        let sliders = app.sliders
        if sliders.count >= 3 {
            sliders.element(boundBy: 0).adjust(toNormalizedSliderPosition: 1.0)   // швидкість тла
            beat(1.6)
            sliders.element(boundBy: 2).adjust(toNormalizedSliderPosition: 0.15)  // щільність скла
            beat(1.6)
            sliders.element(boundBy: 2).adjust(toNormalizedSliderPosition: 0.95)
            beat(1.2)
        } else {
            print("повзунків знайшлось \(sliders.count)")
        }

        tap("Темна")
        beat(1.6)
        tap("Як у системі")
        beat(1.2)
        tap("Перемішати тло")
        beat(2.2)

        // ── Назад у список ──
        app.swipeRight()
        beat(1.4)
        app.swipeRight()
        beat(1.6)

        // ── Пошук розгортається просто в панелі ──
        if tap("Пошук") {
            beat(1.2)
            app.typeText("скл")
            beat(2)
            tap("Нова нотатка")   // та сама кнопка, повернута в «×»
            beat(1.6)
        }

        // ── Нотатка ──
        let card = app.scrollViews.buttons.firstMatch
        if card.waitForExistence(timeout: 3) {
            card.tap()
            beat(2.4)
            tap("Готово")
            beat(1.8)
        }

        // Наприкінці хвилина спокою: видно, як рухається тло саме по собі.
        beat(20)
    }
}
