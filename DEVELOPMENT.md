# Зависимости через OMP Russia (без Git-зависимостей)

В pubspec.yaml разрешены Flutter SDK и пакеты из OMP Russia. Зависимости вида git: не добавлять: они обходят корпоративный пакетный репозиторий.

Перед pub get в новой shell-сессии:

    export PUB_HOSTED_URL='https://sdk-repo.omprussia.ru/sdk/flutter/pub/'
    export AURORA_FLUTTER_STORAGE_BASE_URL='https://sdk-repo.omprussia.ru/sdk/flutter/'

Если прокси задаётся переменными окружения:

    export https_proxy='http://proxy.company.local:PORT'
    export http_proxy="$https_proxy"

Проверка, что нет Git-зависимостей:

    rg '^\s*git:' pubspec.yaml pubspec.lock

Твои команды после доступа к OMP Russia:

    flutter-aurora pub get
    flutter test
    flutter-aurora build aurora --target-platform aurora-x64
