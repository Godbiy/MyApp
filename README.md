# MyApp

iOS-застосунок на SwiftUI. Збирається виключно в GitHub Actions на macOS-раннері —
локальний Mac або Xcode не потрібні.

## Як це влаштовано

| Файл | Навіщо |
|---|---|
| `project.yml` | Опис Xcode-проєкту для [XcodeGen](https://github.com/yonaskolb/XcodeGen). Сам `.xcodeproj` у git **не** лежить — генерується в CI. |
| `Sources/MyApp/` | Код застосунку + `Info.plist` + асети. |
| `.github/workflows/ios.yml` | Збірка: перевірка під симулятор → unsigned archive під пристрій → пакування `.ipa`. |

**Повна інструкція — [docs/GUIDE.md](docs/GUIDE.md).** Нижче стисла версія.

## Отримати збірку

1. Пушнути в `main` (або запустити workflow вручну: вкладка **Actions** → *iOS Build* → **Run workflow**).
2. Дочекатися завершення джоби, відкрити її сторінку.
3. Внизу в секції **Artifacts** завантажити `MyApp-unsigned-ipa`.
4. Розпакувати zip — усередині `MyApp-unsigned.ipa`.

Або постійним посиланням, яке оновлюється при кожному пуші в `main`:
<https://github.com/Godbiy/MyApp/releases/latest>

Або через CLI:

```bash
gh run watch                       # стежити за поточною збіркою
gh run download --name MyApp-unsigned-ipa
```

Теги виду `v1.0.0` додатково створюють окремий іменований GitHub Release.

### Про `dist/*.ipa`

У `dist/` лежить закомічена збірка — щоб `.ipa` був видно прямо в репо.
Це **знімок на момент коміту**: він не оновлюється сам і застаріває, щойно
зміниться код. За свіжою збіркою завжди йди в `releases/latest` або
`gh run download`.

Тримати бінарники в git загалом не варто — вони лишаються в історії назавжди,
і коли застосунок обросте асетами, кожна закомічена копія додаватиме десятки
мегабайт до розміру клону. Поки `.ipa` важить 12 КБ, це не проблема; коли
почне важити — цю теку варто прибрати й користуватись релізами.

## Встановити на айфон

`.ipa` **непідписаний** — Apple не дасть поставити його як є. Підписати треба
на своєму боці, безкоштовним Apple ID:

- **[Sideloadly](https://sideloadly.io/)** (Windows/macOS) — підключаєш айфон
  кабелем, перетягуєш `.ipa`, вводиш Apple ID, тиснеш Start.
- **[AltStore](https://altstore.io/)** — те саме, але вміє автоматично
  переустановлювати застосунок, поки ПК у тій же мережі.

Обмеження безкоштовного Apple ID: підпис живе **7 днів**, далі застосунок треба
переустановити; максимум 3 застосунки одночасно.

Коли захочеться TestFlight — потрібен платний Apple Developer Program ($99/рік),
сертифікат + provisioning profile + App Store Connect API key у GitHub Secrets,
і крок `exportArchive` замість ручного пакування.

## Розробка

Редагуємо `Sources/MyApp/*.swift` — нові файли підхоплюються автоматично,
бо `project.yml` включає теку цілком, і перелічувати їх десь окремо не треба.

Щоб перейменувати застосунок: `project.yml` (`name`, `PRODUCT_NAME`,
`PRODUCT_BUNDLE_IDENTIFIER`), `.github/workflows/ios.yml` (блок `env`),
`Sources/MyApp/Info.plist` (`CFBundleDisplayName`) і назва теки.
