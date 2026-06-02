# Práctica 2: Lectura de entradas digitales DI con el Siemens IOT2050

**Módulo:** SIMATIC IOT2050 Basic PG2 + Shield IO 6ES7647-0KA01-0AA2
**Duración:** 2 horas
**Objetivo:** Aprender a identificar, cablear y leer las entradas digitales DI del shield IO.

---

## 📖 Manual oficial Siemens

Descarga el manual completo aquí:
- **Siemens Support:** https://support.industry.siemens.com/cs/document/109745681/iot2000-extension-modules-operating-instructions
- **Documento:** `A5E39456816-AB_Operating_Instructions_IOT2000_Extension_Modules_1910.pdf`

---

## 📦 Modelos del shield

| Modelo | Descripción |
|--------|------------|
| **6ES7647-0KA01-0AA2** ⬅️ El nuestro | **Input/Output Module** — **5x DI**, 2x AI, 2x DQ |
| 6ES7647-0KA02-0AA2 | Input Module Sink/Source — 8x DI (solo entradas) |

> El **0KA01** es el modelo completo con **entradas y salidas**.

---

## 🎯 Objetivos de la práctica

- Identificar los conectores y bornes de las entradas digitales DI
- Cablear un pulsador / interruptor a una DI
- Acceder al IoT2050 vía SSH (PuTTY)
- Descubrir los GPIOs de las entradas con `gpioinfo`
- Comprender que las DI ya están en modo **input** por defecto (sin configurar PCAL9535)
- Leer el estado de las DI desde terminal con `cat`
- Visualizar el estado de las DI en el dashboard de Node-RED

---

# 🔧 PARTE 1 — HARDWARE

## 🔍 1.1 Estructura física del módulo

**Sección 1.2.1 del manual (Pág. 7):**

![Estructura del módulo I/O - Pág 7](../practica-1/images/structure-page7.png)

*Pág 7 del manual: estructura del módulo con descripción de cada conector*

### Leyenda del módulo 6ES7647-0KA01-0AA2 (entradas):

| Núm. | Conector | Descripción |
|------|----------|-------------|
| ③ | **Digital input interface** | Entradas digitales → **X11-2 a X11-6 (DI0-DI4)** |
| | **M (M0)** | Masa de las entradas digitales → X11-1 |
| ④ | **X1** | Connector de bornes principal (13 pins) |
| ⑥ | **X3** | Connector Arduino (acoplamiento al IoT2050) |

> En esta práctica nos centramos solo en el conector **X11 (inferior)**.

---

## 🔌 1.2 Pinout del conector X11 (entradas digitales)

| Connector | Borne | Señal | Función |
|-----------|-------|-------|---------|
| **X11** (inferior) | **1** | **M0** | **Masa (GND) de las entradas digitales** |
| | **2** | **DI0** | **Entrada digital 0** |
| | **3** | **DI1** | **Entrada digital 1** |
| | **4** | **DI2** | **Entrada digital 2** |
| | **5** | **DI3** | **Entrada digital 3** |
| | **6** | **DI4** | **Entrada digital 4** |

> ⚠️ El conector X11 está en la **parte inferior** del shield. Los bornes están numerados del 1 al 6. M0 (borne 1) es la masa común para todas las entradas.

## ⚡ 1.3 Cableado de una entrada digital

### 1.3.1 Conexión de las entradas digitales DI

Por defecto, las DI del shield leen **1** cuando no hay nada conectado (estado flotante). Para invertir la lógica y que en reposo lean **0**, hay que:

1. Conectar la **DI a positivo (+24V)** a través de un pulsador NA
2. Conectar un **pull-down de 10kΩ** de la DI a M0 (GND)

```
         ════ CONEXIÓN EXTERNA ════

    +24V ───────────── Pulsador NA ─────┐
    (X12-7 L+)                           │
                                         ├── DI0 (X11-2)
    GND  ────────[ 10kΩ ]───────────────┘
    (X11-1 M0)    pull-down

         ═══════════════════════════════
```

**Funcionamiento:**
- **Pulsador NO pulsado** → pull-down a GND → DI0 = **0** (reposo)
- **Pulsador SÍ pulsado** → +24V a DI0 → DI0 = **1** (activo)

> ⚠️ La resistencia de **10kΩ** es necesaria para que cuando el pulsador está abierto, la DI no quede flotante sino que se mantenga firmemente a 0V (GND).

### 1.3.2 Ejemplo práctico con pulsador

```
X12-7 (L+, +24V) ──── Pulsador NA ──── DI0 (X11-2)

X11-2 (DI0) ──── R 10kΩ ──── X11-1 (M0, GND)
```

**Lógica:**
- **Sin pulsar** → pull-down a GND → DI0 = **0** (reposo)
- **Pulsando** → +24V a DI0 → DI0 = **1** (activo)

> ⚠️ Para usar más de una DI: cada pulsador entre L+ y la DI, con su pull-down de 10kΩ a M0.

---

# 💻 PARTE 2 — SOFTWARE

## 🔌 2.1 Acceso al IoT2050 vía PuTTY

1. Abre **PuTTY**
2. Configura:
   - **Host Name:** `192.168.200.1`
   - **Port:** `22`
   - **Connection type:** `SSH`
3. Haz clic en **Open**
4. Usuario: `root`
5. Contraseña: `123456`

> ✅ ¡Ya estás dentro del IoT2050!

---

## 🔍 2.2 Descubrir los GPIOs de las entradas DI

Las entradas digitales DI0-DI4 están conectadas a los GPIOs del procesador del IoT2050.

### Paso 1: Identificar los gpiochips

```bash
gpiodetect
```

Los chips que nos interesan para las entradas:

| Chip | GPIOs | Dispositivo | Función |
|------|-------|-------------|---------|
| **gpiochip3** | **408-463** | **42110000.gpio** | **GPIOs del procesador (DI0-DI3)** |
| **gpiochip4** | **312-407** | **600000.gpio** | **GPIOs del procesador (DI4)** |

### Paso 2: Listar las líneas de cada chip

```bash
gpioinfo gpiochip3
gpioinfo gpiochip4
```

En **gpiochip3** (base 408, 56 líneas):

```
line 29: "IO0" → gpio408+29 = gpio437 → DI0 (X11-2) ✅
line 30: "IO1" → gpio408+30 = gpio438 → DI1 (X11-3) ✅
line 31: "IO2" → gpio408+31 = gpio439 → DI2 (X11-4) ✅
line 33: "IO3" → gpio408+33 = gpio441 → DI3 (X11-5) ✅
```

En **gpiochip4** (base 312, 96 líneas):

```
line 33: "IO4" → gpio312+33 = gpio345 → DI4 (X11-6) ✅
```

### Paso 3: Fórmula para calcular el número de GPIO

```
Número GPIO = BASE_DEL_CHIP + NÚMERO_DE_LÍNEA

Ejemplo para DI0: gpiochip3 (base 408) + line 29 (IO0) = gpio437
Ejemplo para DI4: gpiochip4 (base 312) + line 33 (IO4) = gpio345
```

---

### ⚠️ 2.2.1 Arquitectura del shield: PCAL9535 (sin cambios necesarios)

El shield 6ES7647-0KA01-0AA2 utiliza **tres PCAL9535** (GPIO expanders por I2C). Recordemos de la Práctica 1:

| I2C Addr | gpiochip | Función |
|----------|----------|---------|
| **0x21** | **gpiochip1 (GPIOs 480-495)** | **Direction control para IO0-IO13** |

**¿Por qué las DI funcionan sin configurar nada?**

Porque **gpiochip1** inicializa TODAS las direcciones a **input (0)** por defecto. Como las DI ya tienen que ser entradas, su pin de dirección ya está bien:

| Señal | IO | GPIO direction | Valor por defecto |
|-------|-----|---------------|-------------------|
| **DI0** | IO0 | **gpio480** (IO0-direction) | **0 = input** ✅ |
| **DI1** | IO1 | **gpio481** (IO1-direction) | **0 = input** ✅ |
| **DI2** | IO2 | **gpio482** (IO2-direction) | **0 = input** ✅ |
| **DI3** | IO3 | **gpio483** (IO3-direction) | **0 = input** ✅ |
| **DI4** | IO4 | **gpio484** (IO4-direction) | **0 = input** ✅ |

> 💡 **Diferencia clave con la Práctica 1:** En las DQ tuvimos que cambiar la dirección a **output (1)** en el PCAL9535. En las DI, como ya son **input (0)**, **no hace falta hacer nada** en el PCAL9535. Solo exportar y leer.

También hay un segundo PCAL9535 que controla las resistencias **pull-up/pull-down** de las entradas:

| I2C Addr | gpiochip | Función |
|----------|----------|---------|
| 0x25 | gpiochip2 (GPIOs 464-479) | Pull-up/down resistors |

Por defecto, las DI tienen pull-ups desactivados. Si al dejar el pulsador sin pulsar el valor es inestable, se puede habilitar el pull-up interno desde `gpiochip2`.

---

## ⚙️ 2.3 Configurar y leer las entradas DI

A diferencia de la Práctica 1 (donde configurábamos las DQ como salidas), aquí **solo necesitamos exportar los GPIOs y leerlos**. El PCAL9535 ya los tiene como entradas por defecto.

### 2.3.1 Exportar los GPIOs de las entradas DI

```bash
# Exportar GPIOs de las entradas digitales
echo 437 > /sys/class/gpio/export   # DI0
echo 438 > /sys/class/gpio/export   # DI1
echo 439 > /sys/class/gpio/export   # DI2
echo 441 > /sys/class/gpio/export   # DI3
echo 345 > /sys/class/gpio/export   # DI4
```

> Si da el error "Device or resource busy", significa que ya están exportados — no pasa nada.

### 2.3.2 Leer el valor de una entrada

```bash
cat /sys/class/gpio/gpio437/value   # DI0: 0 o 1
```

Prueba a pulsar el pulsador mientras lees:

```bash
# Mantén pulsado el pulsador y lee:
cat /sys/class/gpio/gpio437/value   # DI0 → debe dar 0 (conectado a M0)

# Suelta el pulsador y lee:
cat /sys/class/gpio/gpio437/value   # DI0 → debe dar 1 (pull-up o floating)
```

### 2.3.3 Leer todas las entradas a la vez

```bash
echo "DI0: $(cat /sys/class/gpio/gpio437/value) | DI1: $(cat /sys/class/gpio/gpio438/value) | DI2: $(cat /sys/class/gpio/gpio439/value) | DI3: $(cat /sys/class/gpio/gpio441/value) | DI4: $(cat /sys/class/gpio/gpio345/value)"
```

### 2.3.4 Leer en bucle (tiempo real)

```bash
while true; do clear; echo "=== ENTRADAS DIGITALES ==="; echo "DI0: $(cat /sys/class/gpio/gpio437/value)"; echo "DI1: $(cat /sys/class/gpio/gpio438/value)"; echo "DI2: $(cat /sys/class/gpio/gpio439/value)"; echo "DI3: $(cat /sys/class/gpio/gpio441/value)"; echo "DI4: $(cat /sys/class/gpio/gpio345/value)"; sleep 0.5; done
```

Para salir del bucle pulsa `Ctrl + C`.

### 2.3.5 Sobre el arranque automático

> 📌 **Para la práctica:** haced los pasos 2.3.1 a 2.3.4 cada vez que empecéis. ¡Así aprendemos todo el proceso!
>
> 🔧 **Si queréis guardar la configuración permanentemente** para evitar repetir la exportación, ved el **Apéndice A** al final del documento.

### 2.3.6 Confirmación experimental

Una vez los GPIOs estén exportados, probad las entradas con el cableado invertido (pull-down + pulsador a L+):

```bash
# Con el pulsador instalado en DI0 (X11-2), pull-down 10kΩ a M0,
# y pulsador entre DI0 y L+ (X12-7):

# Sin pulsar:
cat /sys/class/gpio/gpio437/value   # → 0 (LOW) ✅  ← ahora 0 en reposo!

# Pulsando:
cat /sys/class/gpio/gpio437/value   # → 1 (HIGH) ✅ ← ahora 1 al pulsar!
```

Podéis repetir la prueba conectando el pulsador a otras DI (DI1-DI4).

---

## 🎛️ 2.4 Node-RED: Dashboard con indicadores de DI

### 2.4.1 Importar el flow

1. Abre **http://192.168.200.1:1880/** en el navegador
2. Menú ☰ → **Import** → **Clipboard**
3. Abre el archivo `nodered-flow/flow-di.json` y pégalo
4. Haz clic en **Deploy** (botón naranja arriba a la derecha)

### 2.4.2 Estructura del flow

```
                ┌───────────────────────┐
                │   Timer (cada 1s)      │
                └─────────┬─────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼────┐    ┌────▼───┐      ┌───▼────┐
    │ cat DI0  │    │cat DI1 │ ...  │cat DI4 │
    │gpio437   │    │gpio438 │      │gpio345 │
    └─────┬────┘    └────┬───┘      └───┬────┘
          │              │              │
    ┌─────▼────┐    ┌────▼───┐      ┌───▼────┐
    │Estado DI0│    │Estado  │      │Estado  │
    │  (text)  │    │DI1     │      │DI4     │
    └──────────┘    └────────┘      └────────┘
```

### 2.4.3 Acceder al Dashboard

Abre en el navegador:

> **http://192.168.200.1:1880/ui/**

Veréis el estado de cada entrada digital:

```
┌──────────────────────────────────────────┐
│  🎛️ CONTROL IoT2050                      │
├──────────────────────────────────────────┤
│  ENTRADAS DIGITALES                      │
│                                          │
│  DI0 (X11-2) — gpio437:   1              │
│  DI1 (X11-3) — gpio438:   1              │
│  DI2 (X11-4) — gpio439:   1              │
│  DI3 (X11-5) — gpio441:   1              │
│  DI4 (X11-6) — gpio345:   1              │
└──────────────────────────────────────────┘
```

Cada DI muestra **1** (no pulsado / HIGH) o **0** (pulsado / LOW) en tiempo real, actualizándose cada segundo.

---

## 🧪 Prueba rápida completa

### Desde SSH (PuTTY):

```bash
# 1. Exportar GPIOs
echo 437 > /sys/class/gpio/export   # DI0
echo 345 > /sys/class/gpio/export   # DI4

# 2. Leer (sin conectar nada todavía)
cat /sys/class/gpio/gpio437/value   # → puede dar 0 o 1 (flotante)

# 3. Conecta:
#    - Resistencia 10kΩ entre DI0 (X11-2) y M0 (X11-1) → pull-down
#    - Pulsador NA entre X12-7 (L+, +24V) y DI0 (X11-2)

# 4. Leer sin pulsar
cat /sys/class/gpio/gpio437/value   # → 0 (pull-down a GND) ✅

# 5. Leer pulsando (mantén el pulsador apretado)
cat /sys/class/gpio/gpio437/value   # → 1 (+24V) ✅ ✨
```

### Desde Node-RED:

1. Abre **http://192.168.200.1:1880/ui/**
2. Pulsa el pulsador y observa cómo cambia el indicador en el dashboard

> ⚠️ **Si no funciona:** Comprueba que has exportado el GPIO (`echo 437 > /sys/class/gpio/export`), que el pulsador está entre DI y L+ (X12-7), que el pull-down de 10kΩ está entre DI y M0 (X11-1), y que el cableado llega hasta los bornes correctos.

---

## 📋 Resumen de la práctica

| Paso | Qué hacemos | Comandos clave |
|------|------------|----------------|
| 1 | Cablear | Pull-down 10kΩ DI→M0 (GND). Pulsador NA DI→L+ (+24V) |
| 2 | Acceder | PuTTY → 192.168.200.1 → root / 123456 |
| 3 | Descubrir | `gpiodetect`, `gpioinfo gpiochip3/4` |
| 4 | Exportar | `echo 437 > /sys/class/gpio/export` (y 438, 439, 441, 345) |
| 5 | Leer | `cat /sys/class/gpio/gpio437/value` → 0 o 1 |
| 6 | Node-RED | http://192.168.200.1:1880/ui/ |

### Diferencia clave con la Práctica 1 (DQ)

| Aspecto | DQ (Práctica 1) | DI (Práctica 2) |
|---------|-----------------|-----------------|
| Dirección | **Output** | **Input** |
| PCAL9535 | **Hay que configurarlo** (1 = output) | **Ya está a input (0)** por defecto |
| Acción | Escribir (`echo 1 > value`) | Leer (`cat value`) |
| Node-RED | Botones ON/OFF | Indicadores de estado |

---

## 📁 Contenido de la práctica

```
practica-2/
├── README.ca.md                    ← Esta guía (catalán)
├── README.es.md                    ← Guía en castellano
├── nodered-flow/
│   └── flow-di.json                ← Flow de Node-RED (lectura DI)
```

> Las imágenes del manual (estructura, pinout, cableado) son las mismas que en la Práctica 1 y están en `practica-1/images/`.

---

## 📌 Apéndice A: Configuración permanente (rc.local)

Si queréis que los GPIOs de las DI se exporten **automáticamente en cada arranque**:

```bash
nano /etc/rc.local
```

Añadid **antes del `exit 0`**:

```bash
# Exportar GPIOs de las entradas digitales
echo 437 > /sys/class/gpio/export 2>/dev/null   # DI0
echo 438 > /sys/class/gpio/export 2>/dev/null   # DI1
echo 439 > /sys/class/gpio/export 2>/dev/null   # DI2
echo 441 > /sys/class/gpio/export 2>/dev/null   # DI3
echo 345 > /sys/class/gpio/export 2>/dev/null   # DI4

exit 0
```

```bash
chmod +x /etc/rc.local
systemctl enable rc-local
```

---

## 📌 Apéndice B: Reset para la práctica

```bash
# Opción 1 (recomendada)
reboot

# Opción 2 (sin reiniciar)
echo 437 > /sys/class/gpio/unexport 2>/dev/null
echo 438 > /sys/class/gpio/unexport 2>/dev/null
echo 439 > /sys/class/gpio/unexport 2>/dev/null
echo 441 > /sys/class/gpio/unexport 2>/dev/null
echo 345 > /sys/class/gpio/unexport 2>/dev/null
```

---

## 📄 Licencia

MIT — Uso educativo libre

---

*Práctica 2 — Módulo IOT2050 Siemens*
