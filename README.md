# Calendario Laboral — Red de microservicios con Docker Compose

Red de contenedores que integra dos microservicios y sus respectivas bases de datos:

- **`apicalendario`** (Java 17 + Spring Boot 3, arquitectura cebolla multi-módulo): administra tipos de día y el calendario laboral. Consume los festivos de la API Festivos y los persiste en PostgreSQL.
- **`apifestivos`** (Node.js + Express + MongoDB): calcula y expone los festivos de Colombia para un año.
- **`bdcalendario`** (PostgreSQL 15): base de datos relacional del calendario.
- **`bdfestivos`** (MongoDB 7): base de datos NoSQL de festivos.

```
Navegador / Postman
        |
        v
apicalendario :8092  --->  apifestivos :3001  --->  bdfestivos (MongoDB)
        |
        v
bdcalendario (PostgreSQL)
```

---

## 1. Requisitos

- Docker Desktop con Docker Compose v2.
- Puertos libres en el equipo: `8092`, `3001`, `5434` y `27019`.

---

## 2. Ejecución

Desde la carpeta `dockercompose-redcalendariolaboral`:

```bash
docker compose up -d --build
```

La primera construcción descarga dependencias de Maven y npm, por lo que puede tardar varios minutos. Para verificar el estado:

```bash
docker compose ps
docker compose logs -f apicalendario
```

Cuando los cuatro servicios estén `running`/`healthy`, la aplicación queda disponible.

Para detenerla:

```bash
docker compose down
```

Para reiniciar desde cero (borra los datos y vuelve a ejecutar los scripts de inicialización):

```bash
docker compose down -v
docker compose up -d --build
```

---

## 3. Servicios, puertos y accesos

| Servicio | Contenedor | URL / puerto en el host | Credenciales |
| :--- | :--- | :--- | :--- |
| API Calendario (Swagger) | `dockerapicalendario` | http://localhost:8092/swagger-ui/index.html | — |
| API Calendario (OpenAPI JSON) | `dockerapicalendario` | http://localhost:8092/v3/api-docs | — |
| API Festivos (Swagger) | `dockerapifestivos` | http://localhost:3001/api-docs | — |
| PostgreSQL | `dockerbdcalendario` | `localhost:5434` | BD `calendariolaboral`, usuario `postgres`, contraseña `sa` |
| MongoDB | `dockerbdfestivos` | `localhost:27019` | BD `festivos` |

---

## 4. Endpoints de la API Calendario Laboral

Swagger UI: **http://localhost:8092/swagger-ui/index.html**

### Tipos de día — `/api/tipos`

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| `GET` | `/api/tipos/listar` | Lista los tipos de día (`Día laboral`, `Fin de semana`, `Día festivo`). |
| `GET` | `/api/tipos/obtener/{id}` | Consulta un tipo por id. |
| `POST` | `/api/tipos/agregar` | Crea un tipo. Body: `{ "tipo": "Día especial" }`. |
| `PUT` | `/api/tipos/modificar` | Modifica un tipo. Body: `{ "id": 4, "tipo": "Nuevo nombre" }`. |
| `DELETE` | `/api/tipos/eliminar/{id}` | Elimina un tipo sin calendarios asociados. |

### Calendario — `/api/calendario`

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| `GET` | `/api/calendario/listar` | Lista los registros persistidos en PostgreSQL. |
| `GET` | `/api/calendario/obtener/{id}` | Consulta un registro por id. |
| `GET` | `/api/calendario/es-festivo/{anio}/{mes}/{dia}` | Indica si una fecha es festiva (`true`/`false`). |
| `GET` | `/api/calendario/festivos-año/{anio}` | Consulta la API Festivos, persiste los festivos en PostgreSQL y los devuelve. |

> En la URL, la letra `ñ` debe ir codificada como `%C3%B1`:
> `http://localhost:8092/api/calendario/festivos-a%C3%B1o/2026`

---

## 5. Endpoints de la API Festivos

Swagger UI: **http://localhost:3001/api-docs**

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| `GET` | `/api/festivos/obtener/{anio}` | Lista de festivos del año (consumido por el calendario). |
| `GET` | `/api/festivos/verificar/{anio}/{mes}/{dia}` | Devuelve `Es Festivo` o `No es festivo`. |
| `GET` | `/api/festivos/listar` | Lista los festivos configurados. |
| `GET` | `/api/tipos` | Lista los tipos de cálculo con sus festivos. |
| `POST` | `/api/festivos/agregar` | Agrega un festivo. |
| `PUT` | `/api/festivos/modificar` | Modifica un festivo. |
| `DELETE` | `/api/festivos/eliminar/{id}` | Elimina un festivo. |

---

## 6. Demostración de la integración entre microservicios

La prueba clave demuestra que **`apicalendario` consume a `apifestivos`** y guarda el resultado en PostgreSQL. Usa `curl.exe` en PowerShell (el alias `curl` apunta a `Invoke-WebRequest`).

### Paso 1 — Consultar directamente la API Festivos

```bash
curl.exe http://localhost:3001/api/festivos/obtener/2026
```

Devuelve los festivos calculados por el microservicio Node.js, por ejemplo:

```json
[
  { "festivo": "Año nuevo", "fecha": "2026-01-01" },
  { "festivo": "Santos Reyes", "fecha": "2026-01-12" }
]
```

### Paso 2 — Consultar el calendario (aquí ocurre la integración)

```bash
curl.exe "http://localhost:8092/api/calendario/festivos-a%C3%B1o/2026"
```

El microservicio Java llama internamente a `http://dockerapifestivos:3000/api/festivos/obtener/2026`, transforma la respuesta y **persiste cada festivo** en PostgreSQL con el tipo `Día festivo`.

### Paso 3 — Verificar la persistencia en PostgreSQL

```bash
curl.exe http://localhost:8092/api/calendario/listar
```

```bash
docker exec -it dockerbdcalendario psql -U postgres -d calendariolaboral -c "SELECT c.id, c.fecha, t.tipo, c.descripcion FROM calendario c JOIN tipo t ON t.id = c.idtipo ORDER BY c.fecha;"
```

### Paso 4 — Verificar una fecha concreta

```bash
curl.exe http://localhost:8092/api/calendario/es-festivo/2026/1/1
```

Respuesta esperada: `true`.

### Paso 5 — Evidenciar la dependencia (opcional)

Si se detiene la API Festivos, el calendario responde `503` porque no puede consumirla:

```bash
docker compose stop apifestivos
curl.exe "http://localhost:8092/api/calendario/festivos-a%C3%B1o/2026"
# {"mensaje":"No se pudo consultar la API Festivos externa..."}
docker compose start apifestivos
```

Esto demuestra que el calendario **no calcula festivos por su cuenta**: depende de la API Festivos.

---

## 7. Estructura del proyecto

```
dockercompose-redcalendariolaboral/
├── docker-compose.yml
├── .gitignore
├── README.md
├── apicalendario/          # API Java (Spring Boot)
│   ├── dockerfile
│   ├── dominio/
│   ├── core/
│   ├── aplicacion/
│   ├── infraestructura/
│   └── presentacion/
├── apifestivos/            # API Node.js (Express + MongoDB)
│   ├── dockerfile
│   └── src/
├── bdcalendario/           # PostgreSQL
│   ├── dockerfile
│   ├── DDL_CalendarioLaboral.sql
│   └── DML_CalendarioLaboral.sql
└── bdfestivos/             # MongoDB
    └── iniciarBDFestivos.js
```

---

## 8. Notas

- Los scripts de inicialización solo se ejecutan cuando el volumen de datos está vacío. Si se modifican, hay que ejecutar `docker compose down -v` y volver a levantar.
- La contraseña `sa` es de uso académico; en un entorno real debe manejarse por variables de entorno o secretos.
- El archivo `.env` de `apifestivos` no se versiona; en Docker las variables se inyectan desde `docker-compose.yml`.
