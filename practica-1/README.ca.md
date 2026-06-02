# Pràctica 1: Control de sortides digitals DQ amb el Siemens IOT2050

**Mòdul:** SIMATIC IOT2050 Basic PG2 + Shield IO 6ES7647-0KA01-0AA2
**Durada:** 2 hores
**Objectiu:** Aprendre a identificar, cablejar i controlar les sortides digitals DQ del shield IO.

---

## 📖 Manual oficial Siemens

Descarrega el manual complet aquí:
- **Siemens Support:** https://support.industry.siemens.com/cs/document/109745681/iot2000-extension-modules-operating-instructions
- **Document:** `A5E39456816-AB_Operating_Instructions_IOT2000_Extension_Modules_1910.pdf`

---

## 📦 Models del shield

| Model | Descripció |
|-------|-----------|
| **6ES7647-0KA01-0AA2** ⬅️ El nostre | **Input/Output Module** — 5x DI, 2x AI, **2x DQ** (amb sortides) |
| 6ES7647-0KA02-0AA2 | Input Module Sink/Source — 8x DI (només entrades) |

> El **0KA01** és el model complet amb **sortides digitals (DQ)**. El **0KA02** només té entrades.

---

## 🎯 Objectius de la pràctica

- Identificar els connectors i bornes del shield IO
- Cablejar correctament les sortides DQ amb alimentació externa
- Accedir al IoT2050 via SSH (PuTTY)
- Descobrir els GPIOs de les sortides amb `gpioinfo`
- Configurar el PCAL9535 (control de direcció hardware)
- Activar/desactivar les DQ des de terminal
- Controlar les DQ des del dashboard de Node-RED

---

# 🔧 PART 1 — HARDWARE

## 🔍 1.1 Estructura física del mòdul

**Secció 1.2.1 del manual (Pàg. 7):**

![Estructura del mòdul I/O - Pàg 7](images/structure-page7.png)

*Pàg 7 del manual: estructura del mòdul amb descripció de cada connector*

### Llegenda del mòdul 6ES7647-0KA01-0AA2:

| Núm. | Connector | Descripció |
|------|-----------|------------|
| ① | **Analog interface M** | Massa de les entrades analògiques → X12-2, X12-5 |
| | **U0, U1** | Entrades de tensió analògica (0-10V) → **X12-1, X12-4** |
| | **I0, I1** | Entrades de corrent analògica (0-20mA) → **X12-3, X12-6** |
| ② | **Digital output interface M (M1)** | Massa de les sortides digitals → X12-8 |
| | **DO0, DO1** | Sortides digitals (24V, 0.3A) → **X12-9 (DQ0), X12-10 (DQ1)** |
| ③ | **Digital input interface** | Entrades digitals → **X11-2 a X11-6 (DI0-DI4)** |
| | **M (M0)** | Massa de les entrades digitals → X11-1 |
| ④ | **X1** | Connector de bornes principal (13 pins) |
| ⑤ | **X2** | Alimentació externa per a les sortides DQ |
| ⑥ | **X3** | Connector Arduino (acoblament al IoT2050) |

---

## 🔌 1.2 Pinout del connector X1 (bornes)

### Taula resum de connexions:

| Connector | Borne | Senyal | Funció |
|-----------|-------|--------|--------|
| **X11** (inferior) | 1 | **M0** | Massa de les entrades digitals |
| | 2 | **DI0** | Entrada digital 0 |
| | 3 | **DI1** | Entrada digital 1 |
| | 4 | **DI2** | Entrada digital 2 |
| | 5 | **DI3** | Entrada digital 3 |
| | 6 | **DI4** | Entrada digital 4 |
| **X12** (superior) | 1 | **U0** | Entrada analògica 0 - tensió (+) |
| | 2 | **M** | Massa analògica 0 |
| | 3 | **I0** | Entrada analògica 0 - corrent (+) |
| | 4 | **U1** | Entrada analògica 1 - tensió (+) |
| | 5 | **M** | Massa analògica 1 |
| | 6 | **I1** | Entrada analògica 1 - corrent (+) |
| | **7** | **L+** | **Alimentació +24V DC del mòdul** |
| | **8** | **M1** | **Massa per a les sortides DQ** |
| | **9** | **DQ= (DQ0)** | **Sortida digital 0 — 24V, 0.3A, PNP** |
| | **10** | **DQ1** | **Sortida digital 1 — 24V, 0.3A, PNP** |

> ⚠️ **Nota:** El shield 6ES7647-0KA01-0AA2 té **dos connectors** X11 (inferior, 6 pins) i X12 (superior, 10 pins). Això correspon a les etiquetes impreses al mòdul. Les sortides DQ són **PNP (current-sourcing)** — proporcionen +24V. Càrrega entre DQ i M1 (X12-8).

## ⚡ 1.3 Cablejat de les sortides DQ

> 🔧 Important: Segons el datasheet (Pàg. 26 del manual), les DQ són **"current-sourcing" (PNP)**. Això vol dir que **proporcionen +24V** als bornes X12-9 (DQ0) i X12-10 (DQ1) quan s'activen. Per tant, la càrrega es connecta **entre DQ i M1 (X12-8)**.

**⚠️ REQUISIT INDISPENSABLE:** Les sortides DQ necessiten **alimentació externa de 24V DC** al connector X12: **L+ (borne 7)** i **M1 (borne 8)**. Sense això, no funcionen encara que el software les activi.

### 1.3.1 Alimentació de les sortides DQ (Pàg. 20 del manual)

![Alimentació DQ](images/wiring-power-dq.png)

*Pàg 20: connexió de la font d'alimentació externa per a DQ0 i DQ1 (bornes 7 (L+) i 8 (Massa))*

### 1.3.2 Connexió de les entrades digitals DI (Pàg. 21 del manual)

![Entrades digitals](images/wiring-digital-inputs.png)

*Pàg 21: connexió dels sensors / interruptors a les entrades DI0-DI4 (connector X11)*

### 1.3.3 Connexió de les sortides digitals DQ (Pàg. 22 del manual)

![Sortides digitals i entrades analògiques](images/wiring-digital-outputs-analog.png)

*Pàg 22: connexió de càrregues a DQ0/DQ1 i sensors analògics a AI0/AI1*

### 1.3.4 Esquema resum de cablejat

```
               ┌───────────────────────────────────┐
               │         IoT2050 + Shield           │
               │                                   │
  [X12-7]  ───┤ L+ (+24V)    (alimentació mòdul)  │
  [X12-8]  ───┤ M1 (GND DQ)  (massa sortides)     │
               │                                   │
  [X12-9]  ───┤ DQ0 ──── Càrrega ────┐           │
               │                      │            │
  [X12-10] ───┤ DQ1 ──── Càrrega ────┤           │
               │                      │            │
  [X12-8]  ───┤ M1 ───────────────────┘           │
               │                                   │
  [X11-2]  ───┤ DI0 ──── Sensor/Polsador          │
  [X11-3]  ───┤ DI1 ──── Sensor/Polsador          │
               └───────────────────────────────────┘
```

### 1.3.5 Exemple pràctic amb LED

```
X12-7 (L+) ──── Font 24V (+)
X12-8 (M1) ──── Font 24V (-)

X12-9 (DQ0) ──── LED 🔴 ──── R 1kΩ ──── X12-8 (M1)
```

**Funcionament:**
- Quan s'activa DQ0 → X12-9 es posa a +24V → el LED s'encén
- Quan es desactiva DQ0 → X12-9 es posa a 0V → el LED s'apaga

### 1.3.6 Prova amb multímetre (sense càrrega)

Mode **V⎓ DC**:

| Mesurar entre | DQ = ON | DQ = OFF |
|--------------|----------|-----------|
| **X12-10 (DQ1)** i **X12-8 (M1)** | ~24V ✅ | ~0V ❌ |

> 💡 El multímetre mesura la tensió que **surt** de DQ1 respecte a M1 (X12-8).

---

# 💻 PART 2 — SOFTWARE

## 🔌 2.1 Accés al IoT2050 via PuTTY

1. Obre **PuTTY**
2. Configura:
   - **Host Name:** `192.168.200.1`
   - **Port:** `22`
   - **Connection type:** `SSH`
3. Fes clic a **Open**
4. Usuari: `root`
5. Contrasenya: `123456`

> ✅ Ja ets dins del IoT2050!

### Comandes bàsiques per explorar el sistema

```bash
# Informació del sistema
uname -a

# Quin model d'IoT2050 és?
cat /proc/device-tree/model

# Quins gpiochips hi ha?
gpiodetect
```

---

## 🔍 2.2 Descobrir els GPIOs de les sortides DQ

Les sortides DQ0 i DQ1 estan connectades als GPIOs del processador del IoT2050. Per saber quins números de GPIO tenen, cal explorar el sistema.

### Pas 1: Identificar els gpiochips

```bash
gpiodetect
```

Al nostre IoT2050 hi ha **6 gpiochips**. Els que ens interessen són els que tenen els senyals **IO0-IO13**:

| Chip | GPIOs | Dispositiu | Funció |
|------|-------|-----------|--------|
| **gpiochip3** | **408-463** | **42110000.gpio** | **GPIOs del processador** |
| **gpiochip4** | **312-407** | **600000.gpio** | **GPIOs del processador** |
| gpiochip1 | 480-495 | PCAL9535 (I2C) | Direcció IO0-IO13 |
| gpiochip0 | 496-511 | PCAL9535 (I2C) | Pull-ups |

### Pas 2: Llistar les línies de cada chip

```bash
gpioinfo gpiochip3
gpioinfo gpiochip4
```

A **gpiochip3** (base 408, 56 línies) trobem les **entrades digitals**:
```
line 29: "IO0" → gpio408+29 = gpio437 → DI0 (Borne 1)
line 30: "IO1" → gpio408+30 = gpio438 → DI1 (Borne 2)
line 31: "IO2" → gpio408+31 = gpio439 → DI2 (Borne 3)
line 33: "IO3" → gpio408+33 = gpio441 → DI3 (Borne 4)
```

A **gpiochip4** (base 312, 96 línies) trobem més entrades i les **sortides**:
```
line 33: "IO4" → gpio312+33 = gpio345 → DI4 (Borne 5)
line 43: "IO7" → gpio312+43 = gpio355 → DQ1 (X12-10) ✅
line 48: "IO8" → gpio312+48 = gpio360 → DQ0 (X12-9) ✅
```

### Pas 3: Fórmula per calcular el número de GPIO

```
Número GPIO = BASE_DEL_CHIP + NÚMERO_DE_LÍNIA

Exemple per DQ1: gpiochip4 (base 312) + line 43 (IO7) = gpio355
Exemple per DQ0: gpiochip4 (base 312) + line 48 (IO8) = gpio360
```

### Pas 4: Confirmació experimental

Un cop els GPIOs estiguin exportats i configurats (secció 2.3), proveu:

```bash
# DQ1 (X12-10)
echo 1 > /sys/class/gpio/gpio355/value   # DQ1 ON 🟢
echo 0 > /sys/class/gpio/gpio355/value   # DQ1 OFF ⚫

# DQ0 (X12-9)
echo 1 > /sys/class/gpio/gpio360/value   # DQ0 ON 🟢
echo 0 > /sys/class/gpio/gpio360/value   # DQ0 OFF ⚫
```

Verificar l'estat:
```bash
cat /sys/class/gpio/gpio355/value   # DQ1: 0 o 1
cat /sys/class/gpio/gpio360/value   # DQ0: 0 o 1
```

> 📝 Els números de GPIO (355 = DQ1, 360 = DQ0) depenen de com el kernel de Linux assigna els controladors en arrencar. En un altre IoT2050 podrien ser diferents, per això és important saber com descobrir-ho amb `gpioinfo`.

---

### ⚠️ 2.2.1 Arquitectura del shield: PCAL9535 (el pas ocult!)

El shield 6ES7647-0KA01-0AA2 utilitza **tres PCAL9535** (GPIO expanders per I2C) per gestionar les E/S. Aquests xips **controlen la direcció** dels senyals IO0-IO13 al nivell hardware:

| I2C Addr | gpiochip | Funció |
|----------|----------|--------|
| **0x21** | **gpiochip1 (GPIOs 480-495)** | **Direction control per IO0-IO13** |
| 0x25 | gpiochip2 (GPIOs 464-479) | Pull-up/down resistors |
| 0x20 | gpiochip0 (GPIOs 496-511) | Enables i pull de les entrades analògiques |

**Per què les DQ no funcionen de primeres?**

Perquè **gpiochip1** inicialitza totes les direccions a **input (lo)**. Per poder escriure a DQ0/DQ1 cal posar el pin de direcció corresponent a **output (hi)**:

| Senyal | IO | GPIO direction | Cal per DQ |
|--------|-----|---------------|------------|
| **DQ1** (X12-10) | IO7 | **gpio487** (IO7-direction) | **hi** = output |
| **DQ0** (X12-9) | IO8 | **gpio488** (IO8-direction) | **hi** = output |

**Com comprovar l'estat actual:**

```bash
cat /sys/class/gpio/gpio487/value   # 0 = input (per defecte) ❌
cat /sys/class/gpio/gpio488/value   # 1 = output (si ja està configurat) ✅
```

> Aquesta és la **causa #1** de per què DQ1 no funciona: el PCAL9535 té IO7 en mode **input** i cal posar-lo a **output** abans d'escriure al GPIO natiu.

---

## ⚙️ 2.3 Configurar i controlar els GPIOs

### 2.3.1 Exportar tots els GPIOs necessaris

Cal exportar **tres** coses: els GPIOs de dades (DQ) **i** els GPIOs de control de direcció (PCAL9535):

```bash
# Exportar GPIOs de dades (DQ)
echo 355 > /sys/class/gpio/export   # DQ1 - IO7 de dades
echo 360 > /sys/class/gpio/export   # DQ0 - IO8 de dades

# Exportar GPIOs de control de direcció (PCAL9535 a I2C 0x21)
echo 487 > /sys/class/gpio/export   # IO7-direction (controla DQ0)
echo 488 > /sys/class/gpio/export   # IO8-direction (controla DQ1)
```

> Si dona l'error "Device or resource busy", vol dir que ja estan exportats — no passa res.

### 2.3.2 Configurar la direcció al PCAL9535 (HARDWARE)

**Aquest pas és crític!** Si no es fa, les DQ no funcionaran encara que la direcció del GPIO natiu estigui a "out".

```bash
# Configurar IO7 i IO8 com a SORTIDES al PCAL9535
echo 1 > /sys/class/gpio/gpio487/value   # IO7-direction = output (DQ1)
echo 1 > /sys/class/gpio/gpio488/value   # IO8-direction = output (DQ0)
```

### 2.3.3 Configurar la direcció dels GPIOs natius (SOFTWARE)

```bash
echo out > /sys/class/gpio/gpio355/direction   # DQ1 com a sortida
echo out > /sys/class/gpio/gpio360/direction   # DQ0 com a sortida
```

### 2.3.4 Activar i desactivar les sortides

```bash
# DQ1 ON
echo 1 > /sys/class/gpio/gpio355/value
# El borne 10 es posa a +24V → DQ1 activa

# DQ1 OFF
echo 0 > /sys/class/gpio/gpio355/value

# DQ0 ON
echo 1 > /sys/class/gpio/gpio360/value
# El borne 9 es posa a +24V → DQ0 activa

# DQ0 OFF
echo 0 > /sys/class/gpio/gpio360/value
```

### 2.3.5 Llegir l'estat actual

```bash
cat /sys/class/gpio/gpio355/value   # DQ1: Retorna 0 (OFF) o 1 (ON)
cat /sys/class/gpio/gpio360/value   # DQ0
```

### 2.3.6 Sobre l'arrencada automàtica

> 📌 **Per a la pràctica:** feu els passos 2.3.1 a 2.3.5 cada cop que comenceu. Així aprenem tot el procés!
>
> 🔧 **Si voleu desar la configuració permanentment** per evitar repetir-ho, vegeu l'**Apèndix A** al final del document.

---

## 🎛️ 2.4 Node-RED: Dashboard amb botons ON/OFF

### 2.4.1 Instal·lar node-red-dashboard (si no està)

```bash
cd /usr/lib/node_modules/node-red
npm install node-red-dashboard
systemctl restart node-red
```

### 2.4.2 Importar el flow

1. Obre **http://192.168.200.1:1880/** al navegador
2. Menú ☰ → **Import** → **Clipboard**
3. Obre el fitxer `nodered-flow/flow.json` i enganxa'l
4. Fes clic a **Deploy** (botó taronja a dalt a la dreta)

### 2.4.3 Estructura del flow

```
┌─────────────────────────────────────────────────┐
│              Timer (cada 3s)                     │
│         Llegeix l'estat de DQ0 i DQ1            │
└────────┬──────────────┬─────────────────────────┘
         │              │
  ┌──────▼──────┐  ┌───▼────────┐
  │ Llegir DQ0  │  │ Llegir DQ1 │
  └──────┬──────┘  └────┬───────┘
         │              │
  ┌──────▼──────┐  ┌───▼────────┐
  │ Estat DQ0   │  │ Estat DQ1  │
  └─────────────┘  └────────────┘

┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ DQ0 ⬤ ON│   │ DQ0 ◯ OFF│   │ DQ1 ⬤ ON│   │ DQ1 ◯ OFF│
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │
     └──────┬───────┘              └──────┬───────┘
            │                            │
     ┌──────▼──────┐              ┌──────▼──────┐
     │ Exec DQ0    │              │ Exec DQ0    │
     │ echo > gpio355/value       │ echo > gpio360/value
     └─────────────┘              └─────────────┘
```

### 2.4.4 Accedir al Dashboard

Obre al navegador:

> **http://192.168.200.1:1880/ui/**

Veureu 4 botons:

```
┌──────────────────────────────────────────┐
│  🎛️ CONTROL IoT2050                      │
├──────────────────────────────────────────┤
│  SORTIDES DIGITALS                       │
│                                          │
│  ┌──────────────┐  ┌──────────────┐      │
│  │  DQ0 ⬤ ON   │  │  DQ0 ◯ OFF  │      │
│  └──────────────┘  └──────────────┘      │
│  Estat DQ0: 0                            │
│                                          │
│  ┌──────────────┐  ┌──────────────┐      │
│  │  DQ1 ⬤ ON   │  │  DQ1 ◯ OFF  │      │
│  └──────────────┘  └──────────────┘      │
│  Estat DQ1: 0                            │
└──────────────────────────────────────────┘
```

### 2.4.5 Com funciona cada botó

| Botó | Acció | Comando que s'executa |
|------|-------|----------------------|
| DQ1 ⬤ ON | Activa DQ1 | `echo 1 > /sys/class/gpio/gpio355/value` |
| DQ1 ◯ OFF | Desactiva DQ1 | `echo 0 > /sys/class/gpio/gpio355/value` |
| DQ0 ⬤ ON | Activa DQ0 | `echo 1 > /sys/class/gpio/gpio360/value` |
| DQ0 ◯ OFF | Desactiva DQ0 | `echo 0 > /sys/class/gpio/gpio360/value` |

Cada botó és un node `ui_button` que envia `"1"` o `"0"` a un node `exec`. L'exec fa un `echo` amb redirecció `>` al fitxer del GPIO corresponent.

---

## 🧪 Prova ràpida completa

### Des de PuTTY (SSH):

```bash
# 1. Exportar GPIOs (dades + direcció PCAL9535)
echo 355 > /sys/class/gpio/export   # DQ1
echo 360 > /sys/class/gpio/export   # DQ0
echo 487 > /sys/class/gpio/export   # IO7-direction (PCAL9535)
echo 488 > /sys/class/gpio/export   # IO8-direction (PCAL9535)

# 2. Configurar direcció al PCAL9535 (HARDWARE) ⚠️ IMPRESCINDIBLE!
echo 1 > /sys/class/gpio/gpio487/value   # DQ1 = output (IO7)
echo 1 > /sys/class/gpio/gpio488/value   # DQ0 = output (IO8)

# 3. Configurar direcció dels GPIOs natius
echo out > /sys/class/gpio/gpio355/direction   # DQ1
echo out > /sys/class/gpio/gpio360/direction   # DQ0

# 4. Provar DQ0
echo 1 > /sys/class/gpio/gpio355/value   # 🔵 DQ1 ON
echo 0 > /sys/class/gpio/gpio355/value   # ⚫ DQ1 OFF

# 5. Provar DQ0
echo 1 > /sys/class/gpio/gpio360/value   # 🔵 DQ0 ON
echo 0 > /sys/class/gpio/gpio360/value   # ⚫ DQ0 OFF
```

### Des del Node-RED:

1. Obre **http://192.168.200.1:1880/ui/**
2. Prem els botons i observa els indicadors

> ⚠️ **Si no funciona:** Comprova que tens 24V DC als bornes 7 (L+) i 8 (Massa), i que el GPIO està en mode "out" (`cat /sys/class/gpio/gpio355/direction`).

---

## 📋 Resum de la pràctica

| Pas | Què fem | Comandes clau |
|-----|---------|---------------|
| 1 | Cablejar | Alimentació 24V a X12-7 i X12-8. LED entre DQ i M1 |
| 2 | Accedir | PuTTY → 192.168.200.1 → root / 123456 |
| 3 | Descobrir | `gpiodetect`, `gpioinfo gpiochip3/4` |
| 4 | Exportar | `echo 355 > /sys/class/gpio/export` (i 360, 487, 488) |
| 5 | PCAL9535 | `echo 1 > /sys/class/gpio/gpio487/value` (direction HW) |
| 6 | Dirigir | `echo out > /sys/class/gpio/gpio355/direction` |
| 7 | Provar | `echo 1 > /sys/class/gpio/gpio360/value` → LED 🟢 |
| 8 | Node-RED | http://192.168.200.1:1880/ui/ |

---

## 📁 Contingut de la pràctica

```
practica-1/
├── README.ca.md                    ← Aquesta guia (català)
├── README.es.md                    ← Guía en castellano
├── scripts/
│   ├── export-gpios.sh          ← Exporta i configura GPIOs
│   └── setup-gpios.sh           ← Per a rc.local (arrencada)
├── nodered-flow/
│   └── flow.json                ← Flow de Node-RED (4 botons)
└── images/
    ├── structure-page7.png      ← Pàg 7: estructura del mòdul
    ├── hardware-interface-pinout.png ← Pàg 30: pinout X1
    ├── wiring-power-dq.png      ← Pàg 20: alimentació DQ
    ├── wiring-digital-inputs.png← Pàg 21: connexions DI
    └── wiring-digital-outputs-analog.png ← Pàg 22: connexions DQ+AI
```

---

## 📌 Apèndix A: Configuració permanent (rc.local)

Si voleu que els GPIOs es configurin **automàticament en cada arrencada** (per exemple, si el mòdul està instal·lat en un entorn de producció i no feu la pràctica des de zero cada cop):

### Pas 1: Editar rc.local

```bash
nano /etc/rc.local
```

### Pas 2: Afegir el contingut

Poseu **abans del `exit 0`**:

```bash
# Exportar GPIOs del shield IO
echo 355 > /sys/class/gpio/export 2>/dev/null
echo 360 > /sys/class/gpio/export 2>/dev/null
echo 487 > /sys/class/gpio/export 2>/dev/null
echo 488 > /sys/class/gpio/export 2>/dev/null

# PCAL9535: configurar direcció (HARDWARE) — imprescindible!
echo 1 > /sys/class/gpio/gpio487/value   # IO7-direction = output (DQ1)
echo 1 > /sys/class/gpio/gpio488/value   # IO8-direction = output (DQ0)

# Configurar direcció dels GPIOs natius
echo out > /sys/class/gpio/gpio355/direction   # DQ1
echo out > /sys/class/gpio/gpio360/direction   # DQ0

# Inicialitzar a OFF
echo 0 > /sys/class/gpio/gpio355/value
echo 0 > /sys/class/gpio/gpio360/value

exit 0
```

### Pas 3: Donar permís d'execució i activar servei

```bash
chmod +x /etc/rc.local

# En Debian modern (systemd) cal activar el servei:
systemctl enable rc-local
```

### Pas 4: Provar

```bash
# Executar ara per veure si funciona
bash /etc/rc.local

# Comprovar
echo 1 > /sys/class/gpio/gpio360/value   # DQ0 ON 🟢
echo 0 > /sys/class/gpio/gpio360/value   # DQ0 OFF ⚫
```

> ✅ A partir d'ara, cada cop que arrenqui el IoT2050, els GPIOs estaran llestos i les sortides a OFF.

---

## 📌 Apèndix B: Reset per a la pràctica

Per tornar a **estat inicial** i començar la pràctica des de zero:

### Opció 1 — Reiniciar el IoT2050 (recomanat)

```bash
reboot
```

Després de l'arrencada, el sistema està net i els alumnes comencen des del Pas 2.3.1.

### Opció 2 — Només netejar GPIOs (sense reiniciar)

```bash
# Posar sortides a OFF
echo 0 > /sys/class/gpio/gpio355/value
echo 0 > /sys/class/gpio/gpio360/value

# Si cal desexportar (per començar de zero)
echo 355 > /sys/class/gpio/unexport 2>/dev/null
echo 360 > /sys/class/gpio/unexport 2>/dev/null
echo 487 > /sys/class/gpio/unexport 2>/dev/null
echo 488 > /sys/class/gpio/unexport 2>/dev/null
```

### Opció 3 — Si es va activar el rc.local, desactivar-lo

```bash
# Desactivar el servei
systemctl disable rc-local

# O netejar el fitxer
echo '#!/bin/sh -e' > /etc/rc.local
echo 'exit 0' >> /etc/rc.local
chmod +x /etc/rc.local
```

> 💡 **Per a la pràctica diària:** Opció 1 (reboot) + seguir els passos 2.3.1 a 2.3.5 cada cop.

---

## 📄 Llicència

MIT — Ús educatiu lliure

---

*Pràctica 1 — Mòdul IOT2050 Siemens*
