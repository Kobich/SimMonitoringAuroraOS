# Network Monitor for Aurora OS

Заготовка Flutter-приложения для мониторинга сети на устройствах с ОС Аврора:
тип связи (2G/3G/4G), оператор, уровень сигнала и, если это разрешено системным
API, параметры текущей соты.

> Статус: проект создан и успешно собирается в RPM под `armv7hl`. Получение
> реальных radio/cell-данных ещё не реализовано: для него потребуется отдельный
> Aurora-плагин через D-Bus, FFI или Platform Channel и проверка на устройстве.

## 1. Что нужно заранее

- Windows 11 + WSL 2 + Ubuntu. Официально для Flutter Aurora рекомендуется
  Ubuntu; текущая проверка выполнена в Ubuntu 26.04 WSL2.
- Два внутренних офлайн-архива:
  - `aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar`;
  - `flutter-aurora-offline-kit-3.35.7.2.tar`.
- Не менее 8 ГБ свободного места в WSL; комфортно — 15 ГБ и больше.
- Пароль пользователя Ubuntu для `sudo`.

Используемые версии:

| Компонент | Версия |
| --- | --- |
| Aurora Platform SDK | 5.1.6.110 |
| Target | `armv7hl` |
| Flutter Aurora | 3.35.7.2 (Flutter 3.35.7) |
| Dart | 3.9.2 |

## 2. Установка PSDK без интернета

Скопируйте оба архива на новую машину, например в `~/Downloads`. Затем в WSL:

```bash
cd ~/Downloads
sha256sum aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar
# ожидается: C629DC3FDE8DA48C2FE9DEB1FFB96AAA792D4C24A0C2E22AE8A51B11881A048B

tar -xf aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar
cd aurora-psdk-offline-kit-5.1.6.110
bash install_psdk_offline.sh
```

Скрипт проверит MD5 исходных архивов, при необходимости поставит включённый
`bzip2`, распакует chroot, tooling и target `armv7hl`. Он запросит пароль
`sudo` локально — пароль не передаётся ни в проект, ни в архив.

Закройте терминал и откройте новый. Проверка PSDK:

```bash
aurora_psdk sdk-assistant list
```

Ожидаемая структура:

```text
AuroraOS-5.1.6.110-MB2
└─AuroraOS-5.1.6.110-MB2-armv7hl
  └─AuroraOS-5.1.6.110-MB2-armv7hl.default  (snapshot)
```

## 3. Установка Flutter Aurora без интернета

```bash
cd ~/Downloads
sha256sum flutter-aurora-offline-kit-3.35.7.2.tar
# ожидается: 68C8AF0F52582B11AE5D4E7A020A2A6A323FAE36E7335F9697FAA82FB4BD7A16

tar -xf flutter-aurora-offline-kit-3.35.7.2.tar
cd flutter-aurora-offline-kit-3.35.7.2
bash install_flutter_aurora_offline.sh
```

В архив уже добавлен Aurora pub cache, поэтому первый запуск Flutter не должен
скачивать служебные пакеты из `pub.dev`.

Откройте новый терминал и проверьте версию:

```bash
flutter-aurora --no-version-check --version
```

Ожидается `Flutter 3.35.7` и `Dart 3.9.2`.

## 4. Корпоративный прокси

Настраивается в **WSL-пользователе**, не в папке Flutter и не в репозитории
проекта. Для обычного forward-proxy добавьте в `~/.bashrc`:

```bash
export http_proxy="http://PROXY_HOST:PORT"
export https_proxy="http://PROXY_HOST:PORT"
export no_proxy="localhost,127.0.0.1,::1"

# Aurora hosted pub repository. Не указывайте /api/packages/ — это внутренний API.
export PUB_HOSTED_URL="https://sdk-repo.omprussia.ru/sdk/flutter/pub/"
```

Примените настройки:

```bash
source ~/.bashrc
env | grep -i proxy
curl -I https://sdk-repo.omprussia.ru/sdk/flutter/pub/api/packages/
```

Если прокси требует пароль, не добавляйте пароль в Git или `pubspec.yaml`.
Получите у ИБ разрешённый способ аутентификации либо храните credential только
в защищённой пользовательской конфигурации.

`AURORA_FLUTTER_STORAGE_BASE_URL` не нужно задавать для обычного прокси:
Flutter Aurora уже использует `https://sdk-repo.omprussia.ru/sdk/flutter/`.
Эта переменная нужна только если компания поднимает **зеркало** с другой базой
URL и той же структурой путей.

## 5. Что означает flutter doctor

```bash
flutter-aurora --no-version-check doctor -v
```

При установке полного Aurora SDK успешная диагностика выглядит так:

```text
[✓] Aurora toolchain - develop for Aurora OS
```

В Flutter Aurora 3.35.7.2 без полного Aurora SDK может отображаться ошибка про
`aurora-sdk-dir`. Она относится к использованию эмулятора. Для PSDK-only
связки критерием готовности служит успешная сборка тестового `armv7hl` RPM из
раздела 6, а не полностью зелёный `doctor`.

`Network resources` также может быть красным, если корпоративная сеть не
пускает к `pub.dev`, GitHub, Google или testing-репозиторию. Это не мешает
сборке, если PSDK, Flutter и зависимости проекта доступны локально/через
разрешённый Aurora-репозиторий.

## 6. Проверка нового проекта

Создать проект:

```bash
mkdir -p ~/projects
cd ~/projects
flutter-aurora create --platforms=aurora --org ru.company network_monitor
cd network_monitor
```

Получить уже закэшированные зависимости и собрать RPM:

```bash
flutter-aurora pub get --offline
flutter-aurora build aurora --target-platform aurora-arm
```

Готовый пакет появится в:

```text
build/aurora/psdk_5.1.6.110/aurora-arm/release/RPMS/*.armv7hl.rpm
```

Если `pub get --offline` не находит зависимость, пакет не был добавлен в
локальный кэш. На машине с доступом выполните `flutter-aurora pub get`, затем
передайте/зеркалируйте нужный cache или настройте внутренний pub-репозиторий.

## 7. Проверка на устройстве

Подключите телефон по USB и сначала посмотрите параметры команды:

```bash
flutter-aurora aurora-devices --help
flutter-aurora aurora-devices add --help
```

После регистрации устройства доступны:

```bash
flutter-aurora devices
flutter-aurora run
flutter-aurora install
flutter-aurora logs
```

Для корпоративного распространения потребуются ключ и сертификаты подписи.
Debug-запуск через Flutter использует ключи разработчика; релизный RPM должен
подписываться по правилам организации.

## 8. VS Code

1. Установите VS Code в Windows и расширение **WSL** от Microsoft.
2. В WSL перейдите в проект и выполните `code .`.
3. В окружении `WSL: Ubuntu` установите расширения **Dart** и **Flutter**.
4. В WSL-настройках VS Code укажите:

   ```json
   {
     "dart.flutterSdkPath": "/home/<user>/.local/opt/flutter_aurora/bin"
   }
   ```

5. Если нужен прокси, запускайте `code .` из WSL-терминала, где уже применён
   `~/.bashrc`, чтобы VS Code унаследовал переменные окружения.

## 9. План реализации Network Monitor

```text
lib/
  app/                         # запуск и тема
  features/network_monitor/
    domain/                    # CellularSnapshot, RadioAccessType, интерфейсы
    data/                      # источник реальных данных и mock-источник
    application/               # опрос и управление состоянием
    presentation/              # экран мониторинга
  platform/                    # bridge Flutter <-> Aurora
packages/aurora_cellular/      # нативный Aurora-плагин
```

Сначала реализуется UI на mock-данных. Реальные данные о radio access type,
уровне сигнала и соте требуют отдельного Aurora-плагина. Он будет обращаться к
доступному системному D-Bus API или Platform Channel; доступность CID/LAC/TAC/
PCI и требуемые permissions необходимо проверить на реальном устройстве.

## 10. Git

В Git храните исходный код, `pubspec.yaml`, `pubspec.lock`, `aurora/`, README
и скрипты CI. Не храните там PSDK, Flutter SDK, локальные кэши, `build/` и RPM.
Офлайн-kit публикуйте во внутреннее хранилище артефактов.

Рекомендуемый `.gitignore`:

```gitignore
.dart_tool/
.idea/
.vscode/
build/
*.rpm
```
