# Anixart (Flutter)

Клиент **Anixart** на Flutter: единая кодовая база для Android и iOS, UI повторяет Android-приложение 8.5.2 (снято по скриншотам с реального устройства, см. `android_reference/`).

![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)
![Flutter](https://img.shields.io/badge/Flutter-stable-02569B)

## Скриншоты сравнения (оригинал → наша Flutter-версия)

Главная, Обзор, Закладки, Профиль, Релиз, Выбор озвучки, Фильтр, Расписание, Популярное, Коллекции, Уведомления, Настройки — всё повторено: тёмная тема `#121212`, поверхности `#252525`, 4 таба с пилюлей активной иконки, списки с постером слева, баннеры и плитки в Обзоре, донат-диаграмма статистики профиля.

## Реализовано

- **API**: полный Sign-заголовок (порт `Police` из APK, проверен на проде), User-Agent, токен в query, автоматический failover `api-s.anixsekai.com` ↔ `api-s2.anixart.tv`
- **Главная**: вкладки Моя вкладка / Последнее / Онгоинги / Анонсы / Завершенные (`filter`)
- **Обзор**: баннеры (`discover/interesting`), плитки Популярное / Расписание / Коллекции / Фильтр / Рандом, рекомендации, обсуждаемое сегодня
- **Релиз**: блюр-фон, постер, пилюли статуса/закладок/комментариев, «Воспроизвести» / «СКОРО», инфо-строки, жанры
- **Выбор озвучки** (Type → Source → Episode) + **плеер**: прямые ссылки через `video_player` (после `video/parse`), iframe (Kodik) через WebView, отметки просмотра и история
- **Закладки**: Коллекции / История / Избранное / Смотрю / В планах / Просмотрено / Отложено / Брошено
- **Профиль**: счётчики, статистика с донатом (fl_chart), редактирование
- **Поиск** (аниме/коллекции/профили), **Фильтр** (страна/категория/жанры/статус/год), **Расписание** по дням, **Популярное** (рейтинг с номерами), **Коллекции**, **Уведомления**, **Настройки**, **Вход/Регистрация с email-кодом**

## Сборка

CI (GitHub Actions, `macos-15`) при каждом пуше собирает и прикладывает артефакты:
- **`Anixart-apk`** — `app-release.apk` (подписан debug-ключом → ставится напрямую на Android)
- **`Anixart-ipa`** — unsigned IPA для AltStore/Sideloadly

Локально:
```bash
flutter create . --platforms ios,android --org com.kharki --project-name anixart
flutter pub get
flutter run
```

## Структура

```
lib/
  core/    police_sign.dart (Sign), api.dart (клиент+failover), models.dart, theme.dart
  ui/      root.dart (4 таба), home/, discover/, bookmarks/, profile/, search/,
           release/ (релиз + озвучки), player/, filter/, schedule/, popular/,
           collections/, notifications/, settings/, auth/, widgets.dart
android_reference/   скриншоты оригинального приложения (эталон UI)
tools/               python-референс Sign + фикстуры API
```
