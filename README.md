# AnixartiOS

Полный iOS-клон приложения **Anixart** (Android 8.5.2, `com.swiftsoft.anixartd`) на SwiftUI, работающий с реальным API `api-s.anixsekai.com`.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-F05138)
![UI](https://img.shields.io/badge/UI-SwiftUI-orange)

## Что реализовано

| Раздел | Функции |
|---|---|
| **Auth** | signIn / signUp + email-verify / восстановление пароля, гостевой режим, токен в Keychain |
| **Главная** | 6 табов (актуальное, онгоинги, завершённые, фильмы, OVA, анонсы) через `filter` |
| **Каталог** | Сортировки, полный фильтр: тип, статус, год, 79 жанров (из ресурсов APK), режим исключения жанров |
| **Поиск** | Релизы / коллекции / профили |
| **Расписание** | Понедельник–воскресенье с выделением сегодняшнего дня |
| **Релиз** | Полная карточка, статусы списков (смотрю/планы/просмотрено/отложено/брошено), избранное, оценка 1–5, связанная франшиза |
| **Эпизоды** | Озвучка (Type) → источник (Source) → серия; филлеры, просмотренные, запоминание озвучки |
| **Плеер** | AVPlayer для прямых ссылок (`video/parse` → 360p–1080p), WKWebView для Kodik/iframe; отметка просмотра + история (`history/add`) |
| **Комментарии** | Отправка, ответы, ±голоса, спойлеры, удаление своих, роли авторов |
| **Закладки** | Избранное, история, 5 списков статусов, коллекции |
| **Коллекции** | Просмотр, избранное коллекций, контент |
| **Профиль** | Свой/чужой, счётчики, списки, друзья (заявки), чёрный список, выход |
| **Уведомления** | Лента эпизодов и комментариев, «прочитать всё» |
| **Рулетка** | `release/random` |
| **Deep links** | `anixart://release/123`, `anixart://collection/5`, `anixart://profile/7` |

## Ключевые технические детали

- **Заголовок `Sign`** — 1:1 порт `com.swiftsoft.anixartd.utils.Police` (`Anixart/Core/PoliceSign.swift`). Верифицирован на проде (см. `tools/sign_reference.py`): сервер отвечает кодом уровня приложения, а не HTTP-отказом.
- **MD5 сертификата APK** зашит константой (`9aa5c7af…`), извлечён из `CERT.RSA` декомпилята.
- **User-Agent** повторяет Android-клиент: `AnixartApp/8.5.2-26032112 (Android 14; SDK 34; arm64-v8a; Google Pixel 8; ru)`.
- **Токен** передаётся query-параметром `token` на каждом запросе (как в оригинале).
- **Wire-формат** — смешанный camel/snake (`title_ru`, `episodes_released`, `releaseId`) — модели с явными `CodingKeys` по живым фикстурам (`tools/fixtures/*.json`).
- **Статусы списков профиля** (из `BookmarksTabUiLogic`): watching=1, plans=2, completed=3, hold_on=4, dropped=5.
- **ID сущностей**: категории 1=Сериал, 2=Фильм, 3=OVA, 6=Спешл; статусы 1=Вышел, 2=Выходит, 3=Анонс.
- Дизайн — тёмная тема с carmine-акцентом `#F04E4E` (портирована с веб-версии автора anixart_next).

## Сборка

Проект собирался под **Xcode 16+** (objectVersion 77, `PBXFileSystemSynchronizedRootGroup`).

### Mac / Hackintosh
```bash
cd AnixartiOS
open Anixart.xcodeproj
# Scheme: Anixart → любой iOS 17+ симулятор или устройство
```

### CI (GitHub Actions)
В `.github/workflows/build.yml` уже настроена сборка под `macos-14` runner:

```bash
git init && git add . && git commit -m "Anixart iOS"
git remote add origin <ваш-репозиторий> && git push -u origin main
```

После пуша Actions соберёт проект и приложит `.ipa` (без подписи — для своего устройства включите signing в workflow).

## Структура

```
Anixart/
  App/            Точка входа, AppState, табы, deep links
  Core/
    APIClient.swift      Все эндпоинты + Sign/UA/токен
    PoliceSign.swift     Порт алгоритма подписи + Keychain
    Models.swift         DTO с CodingKeys по фикстурам
    DesignSystem.swift   Тема, карточки, чипы, скелетоны
  Features/
    Auth/  Home/  Catalog/  Release/  Player/  Bookmarks/  Profile/
tools/
  sign_reference.py      Python-референс Sign (живая проверка API)
  fixtures/*.json        Реальные ответы API для моделей
```

## Ограничения

- **Серверные push-уведомления** недоступны: бэкенд принимает только Firebase-токены (`auth/firebase`). Реализованы in-app ленты уведомлений.
- Google/VK вход не портирован (нужны SDK и токены провайдеров); основной путь — email+пароль.
- `total_count` в `filter`-пагинации сервер не заполняет — пагинация идёт «до пустой/короткой страницы».

## Источники

- Реверс-дока: `~/Desktop/anixart_next/reference/anixart_reverse/` (194 эндпоинта, 160 моделей)
- Декомпилят: `~/Desktop/anixart_decompiled/` (jadx + apktool, smali как источник истины)
- Дизайн: `~/Desktop/anixart_next/` (Next.js версия)
