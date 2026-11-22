# Docker: счётчик в контейнере

Иванов Госман, группа 264. Выполнил на 6 баллов.

Приложение из папки `app` я не трогал, только упаковал его в Docker.

## Файлы

- `Dockerfile` - образ на основе `python:3.13-slim`, ставит зависимости и запускает `app/app.py`
- `compose.yaml` - запуск через compose
- `.env.example` - пример настроек, из него делается `.env`
- `.dockerignore` - чтобы в образ не попали `.git`, `.env` и прочее ненужное
- `logs-level4.txt` - логи первого этапа

## Запуск

```bash
cp .env.example .env
docker compose up -d --build
```

Проверить:

```bash
curl http://127.0.0.1:8080/
curl -X POST http://127.0.0.1:8080/increment
```

Остановить: `docker compose down`. Флаг `-v` не добавлять, иначе удалится volume и счётчик обнулится.

## Что можно настроить

В `.env` два параметра:

- `GREETING` - приветствие в ответе приложения
- `HOST_PORT` - порт на компьютере (по умолчанию 8080), в контейнере приложение слушает 8000

## Как это работает

Счётчик приложение хранит в SQLite, файл лежит в `/data/counter.db`. К `/data` подключён именованный volume `counter_data`, поэтому после удаления контейнера данные остаются, а новый контейнер продолжает с того же числа.

## Проверки

### Один контейнер

Собрал образ и запустил контейнер, приветствие передал через переменную окружения:

```bash
docker build -t counter-app .
docker run -d --name counter -p 8080:8000 -e GREETING="Hello from my container" counter-app
```

Приветствие из переменной окружения пришло в ответ, счётчик увеличился с 0 до 2:

```
$ curl http://127.0.0.1:8080/
{"greeting": "Hello from my container", "count": 0, "hostname": "f40bf3c38f00", "storage": "sqlite"}
$ curl -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello from my container", "count": 1, "hostname": "f40bf3c38f00", "storage": "sqlite"}
$ curl -X POST http://127.0.0.1:8080/increment
{"greeting": "Hello from my container", "count": 2, "hostname": "f40bf3c38f00", "storage": "sqlite"}
```

Логи (`docker logs counter`, они же лежат в `logs-level4.txt`):

```
2026-11-22 08:51:28,944 listening port=8000 storage=sqlite
2026-11-22 08:51:34,755 http 192.168.65.1 "GET / HTTP/1.1" 200 -
2026-11-22 08:52:35,728 http 192.168.65.1 "POST /increment HTTP/1.1" 200 -
2026-11-22 08:52:46,889 http 192.168.65.1 "POST /increment HTTP/1.1" 200 -
```

После проверки контейнер удалил командой `docker rm -f counter`.

### Compose и volume

Запуск через compose с настройками из `.env.example`:

```
$ docker compose up -d --build
 ✔ Image hw_3_template-app          Built
 ✔ Network hw_3_template_default     Created
 ✔ Volume hw_3_template_counter_data Created
 ✔ Container hw_3_template-app-1     Started
$ docker compose ps
NAME                 IMAGE                COMMAND                SERVICE   CREATED         STATUS         PORTS
hw_3_template-app-1  hw_3_template-app    "python app/app.py"    app       9 seconds ago   Up 9 seconds   0.0.0.0:8080->8000/tcp, [::]:8080->8000/tcp
$ curl http://127.0.0.1:8080/
{"greeting": "Привет из Docker!", "count": 0, "hostname": "ce23e3cb99ea", "storage": "sqlite"}
```

Поменял настройки в `.env`, приложение теперь отвечает на порту 9090 и с другим приветствием:

```
$ cat .env
GREETING=Привет!
HOST_PORT=9090
$ docker compose up -d
 ✔ Container hw_3_template-app-1  Started
$ curl http://127.0.0.1:9090/
{"greeting": "Привет!", "count": 0, "hostname": "0d34ad8ad4fc", "storage": "sqlite"}
```

Сделал три POST, счётчик дошёл до 3:

```
$ curl -X POST http://127.0.0.1:9090/increment
{"greeting": "Привет!", "count": 1, "hostname": "0d34ad8ad4fc", "storage": "sqlite"}
$ curl -X POST http://127.0.0.1:9090/increment
{"greeting": "Привет!", "count": 2, "hostname": "0d34ad8ad4fc", "storage": "sqlite"}
$ curl -X POST http://127.0.0.1:9090/increment
{"greeting": "Привет!", "count": 3, "hostname": "0d34ad8ad4fc", "storage": "sqlite"}
```

Потом удалил контейнер и создал заново (без `-v`):

```
$ docker compose down
 ✔ Container hw_3_template-app-1  Removed
 ✔ Network hw_3_template_default  Removed
$ docker compose up -d
 ✔ Network hw_3_template_default  Created
 ✔ Container hw_3_template-app-1  Started
$ curl http://127.0.0.1:9090/
{"greeting": "Привет!", "count": 3, "hostname": "5fc57ea5140a", "storage": "sqlite"}
```

`hostname` другой, значит контейнер новый, а счётчик остался 3. Следующий POST прибавил единицу:

```
$ curl -X POST http://127.0.0.1:9090/increment
{"greeting": "Привет!", "count": 4, "hostname": "5fc57ea5140a", "storage": "sqlite"}
```
