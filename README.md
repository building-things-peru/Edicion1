---
title: AutoEdit
emoji: 🎬
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# AutoEdit

Subes (o grabas) un video hablando a cámara y te devuelve el MP4 listo para TikTok/Reels: sin silencios, con clic al inicio, zoom y subtítulos dinámicos. Funciona en PC, iPhone y Android desde el navegador.

## Qué le hace a tu video

| Paso | Qué hace exactamente | Dónde se ajusta |
|---|---|---|
| **1. Jump cuts** | Detecta la voz con 3 métodos a la vez (red neuronal de voz, transcripción y nivel de sonido). Si **cualquiera** oye voz, ese tramo se queda: así no se come la voz bajita. Solo corta silencios de más de 0,4 s y deja 0,1 s antes y 0,18 s después de hablar, con un micro‑fundido para que no suene "clic" en el corte. | `CUT_PRESETS` |
| **2. Sonido al inicio** | Pone un clic (o pop) en el segundo 0. | `assets/sounds/` |
| **3. Zoom** | Al inicio: se acerca al 112 % en 0,35 s y vuelve suave (1,25 s en total). En los cortes: un tramo sí y otro no queda 8 % más cerca, para que el salto no se note. | `ZOOM_INTRO`, `ZOOM_PUNCH` |
| **4. Subtítulos** | Bloques de 2 palabras (configurable), letra Montserrat Black blanca con borde, y un recuadro de color que salta a la palabra que estás diciendo. Puedes corregir el texto después sin volver a subir el video. | `SUB_*` |

Además: normaliza el volumen a -14 LUFS (estándar de redes), convierte el HDR del iPhone para que los colores no salgan lavados y entrega 1080×1920 a 30 fps.

Todos los números están en **`app/config.py`**, con comentarios.

---

## Publicarlo en internet gratis (Hugging Face) — 10 minutos

Necesitas una computadora para esto (una sola vez). Después lo usas desde cualquier celular.

1. Crea una cuenta en **huggingface.co** (gratis) y confirma tu correo.
2. Entra a **huggingface.co/new-space**.
3. Llena así:
   - **Space name:** `autoedit`
   - **Select the Space SDK:** `Docker` → plantilla `Blank`
   - **Space hardware:** `CPU basic · FREE`
   - **Public** o **Private** (privado = solo tú, iniciando sesión).
4. Clic en **Create Space**.
5. Descomprime el ZIP en tu computadora. Abre la carpeta `autoedit`.
6. En tu Space: pestaña **Files** → **+ Add file** → **Upload files**.
7. Arrastra **todo lo que está dentro** de la carpeta `autoedit` (no la carpeta misma: `README.md` y `Dockerfile` tienen que quedar en la raíz). Clic en **Commit changes to main**.
8. Espera a que el estado pase de **Building** a **Running** (5‑10 min la primera vez; puedes verlo en **Logs**).
9. Listo. Tu página es: `https://TU-USUARIO-autoedit.hf.space`

**En el celular:** abre ese link → Compartir → **Agregar a pantalla de inicio**. Queda como una app.

> Si nadie la usa en 48 h, Hugging Face la "duerme". La próxima vez que entres tarda 1‑2 min en despertar.

### Cuánto demora

En el plan gratis, un video de 1 minuto tarda 1‑3 minutos. Videos de hasta 10 minutos.

---

## Usarla

1. **Celular:** *Grabar video* (abre la cámara) o *Subir video* (galería). **PC:** *Subir video* o arrastra el archivo.
2. Espera la barra. No cierres la pantalla mientras **sube**; después ya puedes salir y volver.
3. **Guardar en el celular** → *Guardar video* (va directo a tu galería). En PC: **Descargar video**.
4. ¿Una palabra mal escrita? **Corregir subtítulos**, cambias el texto y **Volver a generar el video**.

En **Ajustes** eliges color del resaltado, palabras por bloque, posición, qué tan agresivos son los cortes, el sonido y el zoom. Se recuerdan para la próxima.

---

## Cambiar cosas

Edita el archivo en tu Space (pestaña Files → clic en el archivo → **Edit**) y guarda. Se reconstruye solo.

| Quiero… | Cambia esto en `app/config.py` |
|---|---|
| Cortes más o menos agresivos | `min_silence` del preset `normal` (más alto = corta menos) |
| Que nunca se coma voz bajita | Usa **Suave** en Ajustes, o baja `vad_threshold` |
| Subtítulos más grandes | `SUB_FONT_SIZE` (0.07 → 0.08) |
| Otro color de resaltado | Agrega una línea en `SUB_COLORS` y un botón en `static/index.html` |
| Más o menos zoom | `ZOOM_INTRO["peak"]`, `ZOOM_PUNCH` |
| Subtítulos más exactos (más lento) | En el Space: **Settings → Variables** → `WHISPER_MODEL` = `medium` |

**Usar tu propio sonido de clic:** sube tu archivo a `assets/sounds/` con el nombre `clic.wav` (o `clic.mp3`) y borra el anterior.

---

## Guardarlo en GitHub (opcional, como respaldo)

1. En **github.com** → **New repository** → nombre `autoedit` → **Create repository**.
2. Clic en **uploading an existing file**, arrastra todo el contenido de la carpeta y **Commit changes**.

GitHub guarda el código y su historial; Hugging Face es el que lo hace funcionar.

## Correrlo en tu computadora (opcional)

Con Docker instalado: `docker build -t autoedit .` y luego `docker run -p 7860:7860 autoedit`. Abre `http://localhost:7860`.

---

## Problemas comunes

| Pasa esto | Haz esto |
|---|---|
| "Se cortó la conexión mientras subía" | Sube con wifi o graba en 1080p en vez de 4K (pesa 4 veces menos). |
| "El servidor se reinició y perdió este video" | El Space se reinició o lo actualizaste. Sube de nuevo. |
| Cortó una palabra | Usa **Suave**. Si pasa seguido, sube `pad_after` en el preset. |
| Dejó silencios largos | Hay ruido de fondo fuerte (ventilador, calle). Usa **Rápido**. |
| El Space dice **Runtime error** | Revisa que `README.md` y `Dockerfile` estén en la raíz del Space, no dentro de una carpeta. |

## Cómo está armado

```
app/
  config.py        todos los parámetros de edición
  cuts.py          paso 1: detección de voz y cortes
  render.py        pasos 2 y 3 + armado final con ffmpeg
  subtitles.py     paso 4: subtítulos dinámicos (.ass)
  transcribe.py    Whisper: texto y tiempo de cada palabra
  pipeline.py      une los pasos
  main.py          servidor web y cola de trabajos
static/            la página (HTML, CSS, JS)
assets/            fuente de subtítulos y sonidos
```

Siguiente fase: biblioteca de B‑roll y motion graphics (etiquetados por tema) que se agregan desde la misma página.

Fuente Montserrat bajo licencia SIL Open Font License (`assets/fonts/OFL-Montserrat.txt`).
