# Configuración de clasp para este repositorio

Proyecto Apps Script gestionado con [clasp](https://github.com/google/clasp), pensado para
trabajar desde cualquier dispositivo (incluido Claude Code on the web) usando este repo
como única fuente de verdad.

## Estructura

```
.
├── src/                  # rootDir de clasp — aquí van los .js/.gs y appsscript.json
│   └── appsscript.json   # manifest del proyecto Apps Script
├── .clasp.json           # scriptId + rootDir (se crea en el Paso 2, se versiona en git)
├── .clasp.json.example   # plantilla de referencia
├── .claspignore          # qué NO subir con clasp push
├── package.json          # dependencia @google/clasp y scripts npm
└── .gitignore            # excluye .clasprc.json (credenciales) y node_modules
```

`.clasp.json` SÍ se versiona (el scriptId no es secreto). `.clasprc.json` (las credenciales
OAuth de `clasp login`) NUNCA se versiona — está en `.gitignore`.

---

## Paso 1 — Crear o localizar el proyecto Apps Script (TÚ, fuera de mi alcance)

Necesitas un **Script ID**. Dos opciones:

- **Ya tienes un proyecto en script.google.com**: ábrelo → menú ⚙️ *Configuración del proyecto*
  → copia el **"ID del proyecto de secuencia de comandos"**.
- **No tienes proyecto todavía**: puedes crear uno nuevo desde script.google.com, o dejar que
  `clasp create` lo cree por ti en el Paso 3 (requiere estar autenticado primero).

Cuando tengas el Script ID (o decidas que `clasp create` lo genere), dímelo o dime que
proceda con `clasp create`.

## Paso 2 — Autenticación de clasp (TÚ, fuera de mi alcance)

`clasp login` abre un navegador y requiere tu cuenta de Google — esto **no lo puedo hacer yo**,
ni siquiera en un entorno cloud. Además, en un entorno cloud (como esta sesión) no hay
navegador local persistente, así que el flujo recomendado es:

1. **En tu PC de casa** (o cualquier máquina con navegador), instala clasp y haz login una vez:
   ```bash
   npm install -g @google/clasp
   clasp login
   ```
2. Eso genera un archivo de credenciales, normalmente en `~/.clasprc.json` (o
   `~\.clasprc.json` en Windows).
3. **Guarda el contenido de ese archivo como secret** en el entorno cloud donde trabajas
   (Claude Code on the web / variables de entorno del proyecto), NO en el repo. Cómo
   inyectarlo depende de la plataforma cloud que uses:
   - Si el entorno permite subir archivos de configuración privados, coloca el contenido
     como `~/.clasprc.json` en esa sesión.
   - Si solo permite variables de entorno, algunas versiones de clasp aceptan las
     credenciales vía `CLASP_CREDENTIALS` — confírmalo con `clasp --version` y su
     documentación antes de depender de esto.
   - Alternativa más robusta para automatización: crear una **cuenta de servicio de Google
     Cloud** con acceso a la Apps Script API y usar `clasp login --creds credentials.json`.
     Esto requiere entrar a Google Cloud Console, habilitar la Apps Script API y descargar
     el JSON de la cuenta de servicio — pasos que debes hacer tú.

**Regla importante**: nunca pegues el contenido de `.clasprc.json` ni credenciales de
cuenta de servicio en el chat conmigo ni en un archivo versionado en git. Son
equivalentes a una contraseña.

### Auto-configuración en Claude Code on the web

Este repo incluye un hook `SessionStart` en [.claude/settings.json](.claude/settings.json)
que, al arrancar la sesión, reconstruye `~/.clasprc.json` a partir de una variable de
entorno `CLASP_CREDENTIALS` — **si esa variable existe y el archivo aún no está
presente**. Si no hay `CLASP_CREDENTIALS`, el hook no hace nada (no rompe la sesión).

Para activarlo:

1. En tu PC (donde `clasp login` ya está hecho), abre `~/.clasprc.json` y copia su
   contenido completo (JSON) — hazlo tú mismo, no me pegues el contenido a mí.
2. En la configuración del proyecto/entorno de Claude Code on the web para este repo,
   añade un secret/variable de entorno llamado `CLASP_CREDENTIALS` con ese contenido
   exacto.
3. Cada nueva sesión cloud efímera para este repo reconstruirá `~/.clasprc.json`
   automáticamente al arrancar, sin que tengas que repetir `clasp login`.

Esto es un atajo cómodo, no la opción más segura a largo plazo: comparte las mismas
credenciales OAuth entre todas las sesiones cloud. Si prefieres aislamiento por sesión,
usa una cuenta de servicio de Google Cloud (ver más abajo) o repite `clasp login`
manualmente en cada sesión nueva.

## Paso 3 — Vincular el repo con el proyecto Apps Script

Una vez tengas clasp autenticado en el entorno donde trabajes:

- Si ya existe el proyecto y tienes el Script ID:
  ```bash
  clasp clone <SCRIPT_ID> --rootDir ./src
  ```
  (o crea `.clasp.json` manualmente a partir de `.clasp.json.example`)

- Si quieres que clasp cree un proyecto nuevo:
  ```bash
  clasp create --type standalone --rootDir ./src
  ```

Esto genera/actualiza `.clasp.json` con el `scriptId` real. Ese archivo sí se commitea,
para que cualquier dispositivo que clone este repo ya sepa a qué proyecto Apps Script
apunta (solo le falta autenticarse con `clasp login`).

## Paso 4 — Flujo de trabajo día a día

- **Traer cambios hechos en el editor web** (script.google.com) hacia el repo:
  ```bash
  clasp pull
  git add -A && git commit -m "sync: pull cambios desde script.google.com"
  git push
  ```
- **Subir cambios hechos aquí** (en el repo/Claude Code) hacia Apps Script:
  ```bash
  clasp push
  ```
  (y luego `git add -A && git commit && git push` para dejar constancia en GitHub)

Recomendación: trata el repo de GitHub como la fuente de verdad. Evita editar directamente
en script.google.com salvo para pruebas rápidas, y si lo haces, hazlo con `clasp pull` lo
antes posible para no divergir.

## Paso 5 — Convenciones de archivos (evitando romper el mapeo de Graphify)

- Todos los `.js`/`.gs` viven dentro de `src/` (rootDir de clasp).
- Los nombres de archivo se mantienen igual que en el editor de Apps Script
  (`Repository.js`, `IntegrityService.js`, etc.) — clasp respeta el nombre de archivo
  como nombre de "file" en Apps Script, así que renombrar aquí renombra allá.
- No anides los `.js` en subcarpetas salvo que sepas que tu versión de clasp/Apps Script
  soporta espacios de nombres con `/` en el nombre del archivo (por defecto, Apps Script
  aplana todo a un espacio de nombres global de funciones, así que la carpeta no afecta
  a las referencias entre funciones — pero si usas Graphify basándote en rutas de archivo,
  mejor mantenerlo plano dentro de `src/` para no romper ese mapeo).

---

## Resumen: qué necesito de ti para continuar

1. **Script ID** del proyecto Apps Script (o luz verde para que use `clasp create`).
2. Confirmación de **dónde vas a ejecutar `clasp login`** por primera vez (tu PC de casa,
   previsiblemente) y cómo prefieres pasar esas credenciales al entorno cloud (secret file,
   variable de entorno, o cuenta de servicio).
3. Cuando ambas cosas estén listas, te guío en la creación de `.clasp.json` real y el primer
   `clasp pull` o `clasp push`.

No haré `git push` a GitHub ni tocaré Apps Script hasta que confirmes cada paso.
