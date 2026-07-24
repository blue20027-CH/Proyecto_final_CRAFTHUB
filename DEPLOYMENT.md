# Cómo publicar CraftHub en internet

Guía paso a paso para dejar la app accesible en una URL pública que cualquiera pueda abrir desde su browser. Usa:

- **Render** — hostea el backend FastAPI (free tier)
- **Vercel** — hostea el frontend Flutter Web (free tier)
- **Supabase** — ya está en la nube (no cambia)

Tiempo total la primera vez: ~2 horas.

---

## 1. Backend en Render

### 1.1. Preparar cuenta y repo

1. Andá a https://render.com y creá cuenta (con GitHub).
2. Autorizá a Render a leer tu repo `Proyecto_final_CRAFTHUB`.

### 1.2. Crear el Web Service

1. Dashboard → **New +** → **Web Service** → conectá el repo.
2. Configuración:

| Campo | Valor |
|---|---|
| Name | `crafthub-api` (el que quieras, será parte de la URL) |
| Region | Oregon (o la más cercana) |
| Branch | `main` |
| Root Directory | `BACK/CraftHub` |
| Runtime | `Python 3` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn main:app --host 0.0.0.0 --port $PORT` |
| Instance Type | Free |

### 1.3. Variables de entorno

En la sección **Environment**, agregá estas variables (las mismas que tenés en tu `.env` local):

| Key | Value |
|---|---|
| `SUPABASE_URL` | Tu URL de Supabase |
| `SUPABASE_KEY` | Tu key de Supabase (service_role) |
| `MISTRAL_API_KEY` | Tu key de Mistral |
| `FRONTEND_URL` | *(dejala vacía por ahora, la vas a agregar en el paso 3.4)* |

⚠️ **NUNCA** pegues estas keys en el repo. Solo en la config de Render.

### 1.4. Deploy

Tocá **Create Web Service**. Render clona el repo, instala deps, arranca el server. Tarda 3-5 minutos.

Cuando termine, arriba te muestra la URL, algo tipo `https://crafthub-api.onrender.com`. **Guardala** — la vas a usar en el frontend.

### 1.5. Probar

Abrí `https://crafthub-api.onrender.com/docs` en el browser. Deberías ver la doc interactiva de FastAPI (Swagger UI).

⚠️ Free tier: el servicio se "duerme" después de 15 min sin uso. La primera request tras dormir tarda ~30s en despertar. Para producción de verdad, upgrade a $7/mes.

---

## 2. Frontend en Vercel

### 2.1. Buildear el web con la URL del backend

En tu máquina, desde `FROT/`:

```bash
flutter build web --release --dart-define=API_URL=https://crafthub-api.onrender.com
```

Reemplazá `crafthub-api.onrender.com` por la URL real que te dio Render.

Esto genera la carpeta `FROT/build/web/` con todos los archivos estáticos.

### 2.2. Publicar en Vercel

**Opción A — CLI (más rápida)**:

```bash
npm install -g vercel
cd FROT/build/web
vercel --prod
```

Vercel te pregunta el nombre y publica. Al final te da la URL, tipo `https://crafthub.vercel.app`.

**Opción B — Dashboard web**:

1. https://vercel.com → login con GitHub.
2. Add New → Project → conectá el repo.
3. **Framework Preset**: Other
4. **Root Directory**: `FROT/build/web`
5. **Build Command**: (vacío, ya está buildeado)
6. **Output Directory**: `.`
7. Deploy.

### 2.3. Cerrar el círculo — actualizar CORS

Volvé a Render → tu servicio → Environment → editá `FRONTEND_URL` y ponele la URL de Vercel (`https://crafthub.vercel.app`, sin barra al final).

Render reinicia el servicio automáticamente. Ya está.

### 2.4. Probar

Abrí la URL de Vercel. Deberías ver el login de CraftHub. Registrate y probá el flujo.

Si algo falla, abrí la consola del browser (F12) y revisá los errores — el más común es un error de CORS, se soluciona confirmando que `FRONTEND_URL` en Render coincida exacto con la URL de Vercel.

---

## 3. Cuando cambies algo

### Cambios en el backend

Cada `git push origin main` → Render redeploya solo. Nada que hacer.

### Cambios en el frontend

Tenés que buildear de nuevo con la URL correcta y volver a publicar:

```bash
cd FROT
flutter build web --release --dart-define=API_URL=https://crafthub-api.onrender.com
cd build/web
vercel --prod
```

O si usaste el dashboard, hacé un git push y Vercel se encarga (pero necesita saber cómo buildear Flutter — habría que agregarle un build script; con la CLI es más simple).

---

## 4. Alternativas

- **Railway** (en vez de Render) — más rápido para arrancar, tier gratis limitado.
- **Fly.io** — free tier generoso pero requiere config con `Dockerfile`.
- **Cloudflare Pages** (en vez de Vercel) — 100% gratis sin límites de banda.
- **Netlify** — igual que Vercel, tier gratis.

Todas funcionan con los mismos archivos, cambia solo el paso de UI.

---

## 5. Checklist previo al deploy

- [ ] `.env` NO está trackeado (`git ls-files | grep .env` no devuelve nada).
- [ ] `MISTRAL_API_KEY` solo está en `.env` local y en Render Environment.
- [ ] Sacaste el PNG raro `acf22330-...png` si no lo usás (pesa 1.6MB).
- [ ] Probaste local con la URL de producción funcionando:
  ```bash
  flutter run -d chrome --dart-define=API_URL=https://crafthub-api.onrender.com
  ```

---

## 6. Costos estimados si crece

| Servicio | Free tier | Pago |
|---|---|---|
| Render Web Service | Duerme a los 15 min | $7/mes (siempre despierto) |
| Vercel | 100 GB banda/mes | $20/mes |
| Supabase | 500 MB DB, 1 GB storage, 50k usuarios/mes | $25/mes desde ahí |
| Mistral API | Tier gratis con rate limits | Pay-per-token (barato) |

Para arrancar y probar con amigos/beta: **$0**. Si tenés tráfico real serio: ~$30-50/mes.
