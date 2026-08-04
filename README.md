# Network Monitor for Aurora OS

Flutter-заготовка для приложения, которое будет показывать состояние сотовой
сети: 2G/3G/4G, оператора, уровень сигнала и, если это разрешено API устройства,
данные текущей соты. Проект уже проверен сборкой RPM для `armv7hl`.

> Важно: интерфейс приложения можно разрабатывать сразу. Доступ к реальным
> данным модема — отдельная нативная задача для Авроры (D-Bus, FFI или Platform
> Channel), которую нужно проверить на физическом устройстве.

## 1. Целевая среда

Инструкция рассчитана на **нативную Ubuntu x86_64**, без Windows и WSL.
Сначала зафиксируйте версию ОС и архитектуру — это важно для системных `.deb`
пакетов:

```bash
cat /etc/os-release
uname -m
df -h "$HOME"
```

Ожидаемая архитектура хоста — `x86_64`. Если на Ubuntu нет интернета, не
устанавливайте произвольные `.deb` от другой версии Ubuntu: возьмите пакеты и
их зависимости из корпоративного зеркала именно для вашей версии ОС.

## 2. Что нужно получить из внутреннего хранилища

Скопируйте на Ubuntu следующие **два** архива:

1. `aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar`
2. `flutter-aurora-offline-kit-3.35.7.2.tar`

Контрольные суммы SHA-256:

```text
C629DC3FDE8DA48C2FE9DEB1FFB96AAA792D4C24A0C2E22AE8A51B11881A048B  aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar
68C8AF0F52582B11AE5D4E7A020A2A6A323FAE36E7335F9697FAA82FB4BD7A16  flutter-aurora-offline-kit-3.35.7.2.tar
```

Проверка:

```bash
sha256sum aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar
sha256sum flutter-aurora-offline-kit-3.35.7.2.tar
```

## 3. Системные зависимости Ubuntu

На машине с доступом к корпоративному APT-зеркалу:

```bash
sudo apt update
sudo apt install -y curl git git-lfs unzip bzip2 tar netcat-openbsd ca-certificates
```

На полностью изолированной машине сначала проверьте минимум:

```bash
command -v sudo tar bzip2 git unzip curl
```

Если отсутствует `bzip2`, не продолжайте распаковку PSDK: доставьте корректный
пакет для вашей Ubuntu через внутреннее хранилище. В PSDK-kit есть `.deb`,
подготовленный для Ubuntu 26.04 amd64; на 22.04/24.04 используйте только
совместимый пакет из вашего зеркала.

## 4. Распаковка PSDK

Предположим, архивы лежат в `~/Downloads`:

```bash
cd ~/Downloads
tar -xf aurora-psdk-offline-kit-5.1.6.110-armv7hl.tar
cd aurora-psdk-offline-kit-5.1.6.110
ls -lh
```

В каталоге должны быть три архива PSDK:

```text
Aurora_OS-5.1.6.110-MB2-Aurora_Platform_SDK_Chroot-x86_64.tar.bz2
Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Tooling-x86_64.tar.7z
Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Target-armv7hl.tar.7z
```

Проверьте официальные MD5:

```bash
md5sum Aurora_OS-5.1.6.110-MB2-Aurora_Platform_SDK_Chroot-x86_64.tar.bz2
# 5b988c7335e0d279b9cbfe383e74cc1a

md5sum Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Tooling-x86_64.tar.7z
# af8bfb90f952316f96a45c2918c672a6

md5sum Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Target-armv7hl.tar.7z
# 8b282db008df0f1f722228624b362f08
```

Создайте структуру и установите chroot:

```bash
mkdir -p ~/AuroraPlatformSDK/{tarballs,projects,toolings,targets,sdks/aurora_psdk}
cp Aurora_OS-5.1.6.110-MB2-Aurora_* ~/AuroraPlatformSDK/tarballs/

export PSDK_DIR="$HOME/AuroraPlatformSDK/sdks/aurora_psdk"
sudo tar --numeric-owner -p -xjf \
  ~/AuroraPlatformSDK/tarballs/Aurora_OS-5.1.6.110-MB2-Aurora_Platform_SDK_Chroot-x86_64.tar.bz2 \
  -C "$PSDK_DIR"
```

Добавьте удобный запуск в `~/.bashrc`:

```bash
cat >> ~/.bashrc <<'EOF'

# Aurora Platform SDK
export PSDK_DIR="$HOME/AuroraPlatformSDK/sdks/aurora_psdk"
alias aurora_psdk='$PSDK_DIR/sdk-chroot'
EOF

source ~/.bashrc
```

Создайте tooling и target из локальных архивов:

```bash
sudo "$PSDK_DIR/sdk-chroot" -u "$USER" \
  sdk-assistant --non-interactive tooling create \
  AuroraOS-5.1.6.110-MB2 \
  "$HOME/AuroraPlatformSDK/tarballs/Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Tooling-x86_64.tar.7z"

sudo "$PSDK_DIR/sdk-chroot" -u "$USER" \
  sdk-assistant --non-interactive target create \
  AuroraOS-5.1.6.110-MB2-armv7hl \
  "$HOME/AuroraPlatformSDK/tarballs/Aurora_OS-5.1.6.110-MB2-Aurora_SDK_Target-armv7hl.tar.7z"
```

Проверка:

```bash
aurora_psdk sdk-assistant list
```

Ожидается target `AuroraOS-5.1.6.110-MB2-armv7hl` и snapshot `.default`.

## 5. Распаковка Flutter Aurora

```bash
cd ~/Downloads
tar -xf flutter-aurora-offline-kit-3.35.7.2.tar
cd flutter-aurora-offline-kit-3.35.7.2

md5sum flutter_aurora_3.35.7.2.tar.gz
# 28711a0196c02061d7721e404be314ae

mkdir -p ~/.local/opt ~/.aurora-pub-cache
tar -xf flutter_aurora_3.35.7.2.tar.gz -C ~/.local/opt
cp -a aurora-pub-cache/. ~/.aurora-pub-cache/
```

Добавьте Flutter Aurora в PATH:

```bash
cat >> ~/.bashrc <<'EOF'

# Flutter Aurora
export PATH="$HOME/.local/opt/flutter_aurora/bin:$PATH"
alias flutter-aurora=flutter
alias dart-aurora=dart
EOF

source ~/.bashrc
```

## 6. Разрешение Flutter запускать PSDK

Flutter запускает `sdk-chroot` в фоне во время сборки. Создайте только две
узкие записи `sudoers`, затем проверьте синтаксис:

```bash
printf '%s\n' \
  "$USER ALL=(ALL) NOPASSWD: $PSDK_DIR/sdk-chroot" \
  "Defaults!$PSDK_DIR/sdk-chroot env_keep += \"SSH_AGENT_PID SSH_AUTH_SOCK\"" \
  | sudo tee /etc/sudoers.d/sdk-chroot >/dev/null
sudo chmod 0440 /etc/sudoers.d/sdk-chroot

printf '%s\n' \
  "$USER ALL=(ALL) NOPASSWD: $PSDK_DIR" \
  "Defaults!$PSDK_DIR env_keep += \"SSH_AGENT_PID SSH_AUTH_SOCK\"" \
  | sudo tee /etc/sudoers.d/mer-sdk-chroot >/dev/null
sudo chmod 0440 /etc/sudoers.d/mer-sdk-chroot

sudo visudo -cf /etc/sudoers.d/sdk-chroot
sudo visudo -cf /etc/sudoers.d/mer-sdk-chroot
```

Настройте Flutter на PSDK:

```bash
flutter-aurora --no-version-check config --aurora-psdk-dir="$PSDK_DIR"
```

## 7. Прокси и Aurora pub-репозиторий

Настройка делается в `~/.bashrc` пользователя Ubuntu, не в проекте и не внутри
Flutter SDK. Для обычного forward-proxy:

```bash
export http_proxy="http://PROXY_HOST:PORT"
export https_proxy="http://PROXY_HOST:PORT"
export no_proxy="localhost,127.0.0.1,::1"

export PUB_HOSTED_URL="https://sdk-repo.omprussia.ru/sdk/flutter/pub/"
```

После изменения:

```bash
source ~/.bashrc
env | grep -i proxy
curl -I https://sdk-repo.omprussia.ru/sdk/flutter/pub/api/packages/
```

Не указывайте `/api/packages/` в `PUB_HOSTED_URL`: это endpoint API, а не
базовый URL pub-репозитория. `AURORA_FLUTTER_STORAGE_BASE_URL` не нужен для
обычного proxy; он нужен только при использовании внутреннего зеркала Aurora
с другой базой URL.

## 8. Проверки и первая сборка

Проверка версий:

```bash
flutter-aurora --no-version-check --version
flutter-aurora --no-version-check doctor -v
```

Ожидается Flutter `3.35.7` и Dart `3.9.2`.

Flutter 3.35.7.2 без полного Aurora SDK может показать в `doctor` ошибку про
`aurora-sdk-dir`. Она нужна для эмулятора. Для PSDK-only окружения критерием
готовности является успешная RPM-сборка для `armv7hl`:

```bash
mkdir -p ~/projects
cd ~/projects
flutter-aurora create --platforms=aurora --org ru.company hello_aurora
cd hello_aurora
flutter-aurora pub get --offline
flutter-aurora build aurora --target-platform aurora-arm
```

RPM появится в каталоге:

```text
build/aurora/psdk_5.1.6.110/aurora-arm/release/RPMS/
```

## 9. VS Code на Ubuntu

Установите VS Code способом, разрешённым в организации. Затем в VS Code
установите расширения **Dart** и **Flutter**. В настройках пользователя задайте:

```json
{
  "dart.flutterSdkPath": "/home/<user>/.local/opt/flutter_aurora/bin"
}
```

Откройте проект из терминала:

```bash
cd ~/projects/hello_aurora
code .
```

## 10. Описание архивов и старых скриптов

Для конечной установки предпочтительны ручные команды из этого README.
Скрипты в архивах оставлены как автоматизированная документация тех же шагов:

- `install_psdk_offline.sh`: проверяет MD5, распаковывает chroot, создаёт
  tooling и target `armv7hl`;
- `install_flutter_aurora_offline.sh`: проверяет Flutter-архив, распаковывает
  Flutter и Aurora pub cache, создаёт `sudoers`-настройки и задаёт PSDK path.

Не запускайте оба подхода вперемешку на частично установленной системе: либо
используйте скрипты на чистой машине, либо выполняйте команды README.

## 11. Разработка Network Monitor

Следующая структура будет добавлена в проект:

```text
lib/
  app/
  features/network_monitor/
    domain/
    data/
    application/
    presentation/
  platform/
packages/aurora_cellular/
```

Экран можно сделать с mock-данными сразу. Для реального типа сети, оператора,
сигнала и параметров соты нужен отдельный Aurora-плагин; доступность этих
данных и permissions проверяются на физическом устройстве.
