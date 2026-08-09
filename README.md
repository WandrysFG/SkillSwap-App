<div align="center">

# 📱 SkillSwap

### Aprende algo nuevo. Enseña lo que ya sabes. Sin dinero de por medio.

SkillSwap es una aplicación móvil que conecta a personas para intercambiar habilidades entre sí — tú enseñas lo que sabes, y aprendes lo que necesitas, sin que el dinero sea parte de la ecuación.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-blue)]()

</div>

---

## 📋 Tabla de contenido

- [Idea del proyecto](#-idea-del-proyecto)
- [Funcionalidades](#-funcionalidades)
- [Stack tecnológico](#-stack-tecnológico)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Modelo de datos](#-modelo-de-datos)
- [Instalación y ejecución](#-instalación-y-ejecución)
- [Cuentas de demostración](#-cuentas-de-demostración)
- [Decisiones técnicas destacadas](#-decisiones-técnicas-destacadas)
- [Roadmap](#-roadmap)
- [Equipo](#-equipo)

---

## 💡 Idea del proyecto

Aprender algo nuevo suele costar dinero, y mucha gente tiene conocimiento valioso sin un espacio simple para compartirlo. SkillSwap resuelve esto conectando a dos tipos de necesidad al mismo tiempo:

> *"Te enseño diseño gráfico, tú me enseñas inglés."*

Un usuario publica lo que sabe hacer y lo que le gustaría aprender; la app lo conecta con otras personas compatibles, y todo el proceso —desde la solicitud hasta la calificación final— ocurre dentro de la misma aplicación.

## ✨ Funcionalidades

### 🔐 Cuentas y perfil
- Registro e inicio de sesión con Supabase Auth
- Edición de perfil (nombre, biografía, foto)
- Catálogo de habilidades por categoría, con selección de lo que **ofreces** y lo que **quieres aprender**

### 🔍 Búsqueda inteligente
- Navegación por categoría → habilidad específica
- Búsqueda global por texto (nombre o habilidad), con debounce para no saturar la base de datos

### 🤝 Ciclo completo de intercambio
- Solicitud de intercambio: quien la envía elige qué quiere aprender; quien la **acepta** decide qué habilidad recibe a cambio
- Estados: `pendiente` → `aceptada` → `esperando_confirmación` → `completada` (o `rechazada` / `cancelada`)
- **Doble confirmación bilateral**: un intercambio solo se cierra cuando ambas partes confirman que ocurrió
- Reporte de ausencia ("no se presentó"), con registro en base de datos

### 💬 Chat en tiempo real
- Conversación 1 a 1 por cada intercambio aceptado, usando Supabase Realtime
- Bandeja dividida en conversaciones activas e historial
- Borrado de mensajes propios, sincronizado en tiempo real para ambos usuarios

### ⭐ Reputación y confianza
- Sistema de reseñas de 1 a 5 estrellas tras completar un intercambio
- **Reseñas ciegas**: ocultas hasta que ambas partes califiquen, o pasen 48 horas — evita calificaciones por venganza
- Promedio y cantidad de reseñas visibles en cada perfil, basado exclusivamente en intercambios reales

---

## 🧰 Stack tecnológico

| Categoría | Tecnología |
|---|---|
| Frontend | Flutter (Dart) |
| Backend / Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth |
| Tiempo real | Supabase Realtime |
| Control de versiones | Git + GitHub |

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada, inicialización de Supabase
├── models/                    # Clases de datos (Usuario, Intercambio, Reseña, etc.)
├── screens/                   # Pantallas de la aplicación
├── services/                  # Lógica de negocio y conexión con Supabase
├── utils/                     # Tema visual y transiciones globales
└── widgets/                   # Componentes reutilizables (botones, chips, badges...)
```

| Carpeta | En una frase |
|---|---|
| `models/` | Cómo se estructuran los datos de la app |
| `services/` | Toda la lógica de negocio real — el corazón del proyecto |
| `screens/` | La experiencia visible del usuario |
| `widgets/` | Piezas reutilizables para mantener consistencia visual |

---

## 🗄️ Modelo de datos

<details>
<summary><strong>Ver esquema SQL completo</strong> (tablas, tipos y relaciones principales)</summary>

```sql
-- Tipos enumerados
create type skill_tipo as enum ('ofrece', 'quiere');
create type exchange_estado as enum (
  'pendiente', 'aceptada', 'rechazada', 'cancelada',
  'esperando_confirmacion', 'completada'
);

-- Perfiles de usuario (vinculados a Supabase Auth)
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  email text unique not null,
  bio text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Catálogo de habilidades
create table public.skills (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  categoria text not null
);

-- Relación usuario-habilidad
create table public.user_skills (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.users(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  tipo skill_tipo not null,
  unique (usuario_id, skill_id, tipo)
);

-- Intercambios
create table public.exchanges (
  id uuid primary key default gen_random_uuid(),
  usuario_origen_id uuid not null references public.users(id) on delete cascade,
  usuario_destino_id uuid not null references public.users(id) on delete cascade,
  skill_ofrecida_id uuid references public.skills(id),      -- se define al aceptar
  skill_solicitada_id uuid not null references public.skills(id),
  estado exchange_estado not null default 'pendiente',
  confirmado_origen boolean not null default false,
  confirmado_destino boolean not null default false,
  completed_at timestamptz,
  no_show_reportado_por uuid references public.users(id),
  no_show_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Mensajes de chat por intercambio
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  exchange_id uuid not null references public.exchanges(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text not null,
  created_at timestamptz default now()
);
alter table public.messages replica identity full; -- necesario para propagar DELETE por Realtime

-- Reseñas (ciegas hasta que ambas partes califiquen o pasen 48h)
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  exchange_id uuid not null references public.exchanges(id) on delete cascade,
  evaluator_id uuid not null references public.users(id) on delete cascade,
  evaluated_id uuid not null references public.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  reply text,
  is_reported boolean not null default false,
  created_at timestamptz default now(),
  unique (exchange_id, evaluator_id)
);
```

Todas las tablas tienen **Row Level Security (RLS)** activado. La política más particular es la de `reviews`, que usa una función `security definer` (`can_view_review`) para evitar recursión infinita al verificar si una reseña ya "dejó de ser ciega".

</details>

---

## 🚀 Instalación y ejecución

### Requisitos previos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado
- Una cuenta en [Supabase](https://supabase.com)

### Pasos

```bash
# 1. Clona el repositorio
git clone https://github.com/WandrysFG/SkillSwap-App.git
cd SkillSwap-App

# 2. Instala las dependencias
flutter pub get

# 3. Crea el archivo .env en la raíz del proyecto
```

Contenido del `.env`:
```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

```bash
# 4. Aplica el esquema SQL (ver sección "Modelo de datos") en el
#    SQL Editor de tu proyecto de Supabase, junto con sus políticas RLS

# 5. Corre la aplicación
flutter run
```

### Generar el APK

```bash
flutter build apk --release
```

El instalable queda en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Cuentas de demostración

| Usuario | Correo | Contraseña |
|---|---|---|
| Carlos López | carlos.lopez@demo.com | `Demo12345` |
| Sofía Martínez | sofia.martinez@demo.com | `Demo12345` |
| Javier Ortiz | javier.ortiz@demo.com | `Demo12345` |
| Laura Ruiz | laura.ruiz@demo.com | `Demo12345` |
| Diego Silva | diego.silva@demo.com | `Demo12345` |

> Carlos, Sofía, Laura y Diego ya cuentan con un intercambio completado y reseñas cruzadas, para poder ver el sistema de reputación funcionando desde el primer momento.

---

## 🧠 Decisiones técnicas destacadas

- **Doble confirmación bilateral**: ningún intercambio se marca como completado con la acción de una sola persona; ambas partes deben confirmarlo por separado, evitando cierres falsos o unilaterales.
- **Reseñas ciegas sin recursión RLS**: la política de seguridad necesitaba consultar la propia tabla que protegía, lo que generaba un error de recursión infinita (`42P17`). Se resolvió delegando esa verificación a una función `security definer`, que consulta la tabla sin volver a disparar la política.
- **Quién decide qué a cambio de qué**: quien envía una solicitud solo elige qué quiere aprender; es quien **acepta** quien decide, en ese momento, qué habilidad recibe a cambio — evitando que el remitente imponga una condición unilateral.
- **Búsqueda en tres niveles**: por categoría, por habilidad específica y por texto libre, conviviendo en la misma pantalla sin disparar consultas innecesarias (debounce de 400ms en la búsqueda de texto).

---

## 🗺️ Roadmap

- [ ] Notificaciones push
- [ ] Niveles de habilidad (principiante / intermedio / avanzado)
- [ ] Matching automático de usuarios compatibles
- [ ] Filtros avanzados de búsqueda
- [ ] Versión web pública

---

<div align="center">

Hecho con 💙 usando Flutter y Supabase

</div>
