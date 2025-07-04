# 📚 Трекер Привычек "Trake-Tweek"

Приложение на Flutter для отслеживания ежедневных привычек.  
Работает на Android, iOS, Web и Desktop.

---

## ✨ Возможности

- Добавление и редактирование привычек
- Отметка выполнения привычек по дням (в том числе сегодня)
- Подсчёт серии (🔥 streak дней)
- Время для привычек по желанию (установка и очистка напоминаний)
- Хранение данных локально (SharedPreferences)
- Несколько тёмных цветовых тем (переключение вручную из списка предустановленных)
- Перетаскивание привычек для изменения порядка (drag & drop)
- Поддержка нескольких языков (инициализация локализации для даты, сейчас — русский)
- Push-уведомление для напоминания 

---

## 💥 Релизы

| Версия    | Android |  Windows |
|-----------|---------|---------|
| v1.3      |[arm64-v8a](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.3/app-arm64-v8a-release.apk)|[64x](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.3/windows.zip)|  
| v1.1      |[arm64-v8a](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.1/trake-tweek.apk)|[64x](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.1/trake-tweek.zip)|  
| v1.0      |[arm64-v8a](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.0/trake-tweek.apk)|[64x](https://github.com/Denis24-sdk/trake-tweek/releases/download/v1.0/Trake-tweek.zip)|  

_(На остальные системы скомпилируйте сами. Как скомпилировать под другую систему/платформу посмотрите в пункте "🚀 Запуск проекта".)_

---

## 🚀 Запуск проекта
1. Установить Flutter: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Клонировать репозиторий:
    ```bash
    git clone https://github.com/Denis24-sdk/trake-tweek.git
    cd trake-tweek
    ```
3. Установить зависимости:
    ```bash
    flutter pub get
    ```
4. Запустить:
    ```bash
    flutter run
    ```

---

## 📦 Зависимости 
- flutter — базовый SDK для разработки приложений
- flutter_animate — анимации виджетов
- google_fonts — подключение красивых шрифтов из Google Fonts
- intl — интернационализация и форматирование дат/чисел
- shared_preferences — локальное хранилище (ключ-значение)
- reorderables — перетаскивание и изменение порядка элементов
- uuid — генерация уникальных идентификаторов
- flutter_svg — отображение SVG-изображений
- flutter_local_notifications — локальные уведомления (для напоминаний и alerts)
- flutter_timezone — работа с часовыми поясами
- permission_handler — запрос и управление системными разрешениями
- android_intent_plus — вызов нативных Android-Intent'ов

---

## 📌 Скриншоты
![fhoto_1](./images/1.jpg)
![fhoto_2](./images/2.jpg)

---

## 💡 Планы по улучшению

- Поддержка облачной синхронизации
- Виджет на экран телефона
- История привычек

---


