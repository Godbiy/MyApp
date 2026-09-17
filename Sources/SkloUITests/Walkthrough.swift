import XCTest

/// Прогулянка застосунком для запису відео. Це не перевірка поведінки —
/// це єдиний спосіб побачити рух, коли під рукою немає ні Mac, ні пристрою:
/// симулятору не скажеш «тапни тут», а XCUITest може.
///
/// Паузи тут навмисно щедрі: відео мають дивитись люди, а не машина.
final class Walkthrough: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    private func beat(_ seconds: Double = 1.2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func testTour() {
        beat(3)

        // ── Список і фільтр тек ──
        tap("Робота")
        beat()
        tap("Усі")
        beat()

        // ── Гортання між сторінками ──
        app.swipeLeft()
        beat(1.6)
        app.swipeLeft()
        beat(1.6)

        // ── Налаштування: акцент, тло, щільність скла ──
        let sliders = app.sliders
        if sliders.count > 2 {
            sliders.element(boundBy: 0).adjust(toNormalizedSliderPosition: 1.0)   // швидкість тла
            beat()
            sliders.element(boundBy: 2).adjust(toNormalizedSliderPosition: 0.15)  // щільність скла
            beat(1.4)
            sliders.element(boundBy: 2).adjust(toNormalizedSliderPosition: 0.9)
            beat()
        }
        tap("Темна")
        beat(1.4)
        tap("Як у системі")
        beat()

        // Перемішати тло — кнопка дії на цій сторінці
        tap("Перемішати тло")
        beat(1.8)

        // ── Назад у список ──
        app.swipeRight()
        beat(1.2)
        app.swipeRight()
        beat(1.4)

        // ── Пошук розгортається просто в панелі ──
        tap("Пошук")
        beat(1.2)
        app.typeText("скл")
        beat(1.6)
        tap("Нова нотатка")   // та сама кнопка, повернута в «×»
        beat(1.4)

        // ── Нотатка: галочки й закріплення ──
        app.buttons.element(boundBy: 0).tap()
        let card = app.scrollViews.buttons.firstMatch
        if card.exists { card.tap() }
        beat(2)

        let boxes = app.buttons.matching(identifier: "Готово")
        _ = boxes
        tapFirstCheckbox()
        beat(1.4)

        tap("Готово")
        beat(1.6)
    }

    // MARK: - Дрібні помічники

    private func tap(_ label: String) {
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    /// Галочки не мають підписів, тож беремо їх за розміром: квадратик 23×23.
    private func tapFirstCheckbox() {
        for i in 0..<app.buttons.count {
            let b = app.buttons.element(boundBy: i)
            guard b.exists else { continue }
            let f = b.frame
            if abs(f.width - f.height) < 4, f.width > 18, f.width < 30 {
                b.tap()
                return
            }
        }
    }
}
