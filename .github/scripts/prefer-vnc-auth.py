#!/usr/bin/env python3
"""Просить noVNC надавати перевагу звичайному парольному входу.

noVNC перебирає схеми автентифікації в порядку, який пропонує сервер, і
бере першу підтримувану. macOS ставить першою свою фірмову (тип 30) — а її
реалізація в браузері раз за разом не доходить до кінця, навіть коли пароль
і права правильні. Поруч той самий сервер пропонує звичайний парольний вхід
(тип 2): він працює безвідмовно й не питає імені користувача.

Падає, якщо місце в клієнті змінилось, — краще зупинити збірку, ніж тихо
лишити стару поведінку й знову шукати причину годину.
"""

import io
import sys

OLD = """            this._rfbAuthScheme = -1;
            for (let type of types) {
                if (this._isSupportedSecurityType(type)) {
                    this._rfbAuthScheme = type;
                    break;
                }
            }"""

NEW = """            this._rfbAuthScheme = -1;
            if (Array.prototype.includes.call(types, securityTypeVNCAuth)) {
                this._rfbAuthScheme = securityTypeVNCAuth;
            } else {
                for (let type of types) {
                    if (this._isSupportedSecurityType(type)) {
                        this._rfbAuthScheme = type;
                        break;
                    }
                }
            }"""


def main() -> int:
    if len(sys.argv) != 2:
        print("вжиток: prefer-vnc-auth.py <шлях до core/rfb.js>", file=sys.stderr)
        return 2

    path = sys.argv[1]
    source = io.open(path, encoding="utf-8").read()

    if NEW in source:
        print("клієнт уже налаштований")
        return 0

    if OLD not in source:
        print("не знайшов місце вибору схеми — клієнт змінився", file=sys.stderr)
        return 1

    io.open(path, "w", encoding="utf-8", newline="\n").write(source.replace(OLD, NEW, 1))
    print("клієнт налаштовано на парольний вхід")
    return 0


if __name__ == "__main__":
    sys.exit(main())
