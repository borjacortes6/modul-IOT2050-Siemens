# Pràctica 1: Control de sortides digitals DQ amb el Siemens IOT2050

**Mòdul:** SIMATIC IOT2050 Basic PG2 + Shield IO 6ES7647-0KA01-0AA2
**Durada:** 2 hores
**Objectiu:** Aprendre a identificar, cablejar i controlar les sortides digitals DQ del shield IO.

---

## 🎯 Objectius

- Identificar els connectors i bornes del shield IO
- Cablejar correctament les sortides DQ amb alimentació externa
- Accedir al IoT2050 via SSH (PuTTY)
- Descobrir els GPIOs de les sortides amb `gpioinfo`
- Configurar el PCAL9535 (control de direcció hardware)
- Activar/desactivar les DQ des de terminal
- Controlar les DQ des del dashboard de Node-RED

---

## 🔧 PART 1 — HARDWARE

### 1.1 Connectors del shield

El shield 6ES7647-0KA01-0AA2 té **dos connectors**:

**X11 (inferior) — Entrades digitals:**
| Borne | Senyal |
|-------|--------|
| 1 | M0 |
| 2 | DI0 |
| 3 | DI1 |
| 4 | DI2 |
| 5 | DI3 |
| 6 | DI4 |

**X12 (superior) — Analògiques + Alimentació + Sortides:**
| Borne | Senyal |
|-------|--------|
| 1 | U0 |
| 2 | M |
| 3 | I0 |
| 4 | U1 |
| 5 | M |
| 6 | I1 |
| **7** | **L+** |
| **8** | **M1** |
| **9** | **DQ= (DQ0)** |
| **10** | **DQ1** |

### 1.2 Cablejat

> ⚠️ Les sortides DQ necessiten **alimentació externa 24V DC** a L+ (X12-7) i M1 (X12-8). Sense això NO funcionen.

**Esquema de cablejat:**

```
Font 24V ──┬── X12-7 (L+)
           └── X12-8 (M1)

X12-9  (DQ0) ──── LED 🔴 ──── R 1kΩ ──── X12-8 (M1)
X12-10 (DQ1) ──── LED 🔴 ──── R 1kΩ ──── X12-8 (M1)
```

Les DQ són **PNP (current-sourcing)**: proporcionen +24V quan s'activen. El corrent passa des de la DQ, a través de la càrrega, cap a M1.

---

## 💻 PART 2 — SOFTWARE

### 2.1 Accés al IoT2050

1. Obre **PuTTY**
2. Host Name: `192.168.200.1`
3. Port: `22`, SSH
4. Usuari: `root`
5. Contrasenya: `123456`

### 2.2 Descobrir els GPIOs

```bash
# Veure tots els gpiochips
gpiodetect

# Detall de cada chip
gpioinfo gpiochip3
gpioinfo gpiochip4
```

**Mapping verificat:**

| Senyal | IO | GPIO | Fórmula |
|--------|-----|------|---------|
| DI0 | IO0 | gpio437 | gpiochip3 base408 + line29 |
| DI1 | IO1 | gpio438 | gpiochip3 base408 + line30 |
| DI2 | IO2 | gpio439 | gpiochip3 base408 + line31 |
| DI3 | IO3 | gpio441 | gpiochip3 base408 + line33 |
| DI4 | IO4 | gpio345 | gpiochip4 base312 + line33 |
| **DQ0** | IO8 | **gpio360** | gpiochip4 base312 + line48 |
| **DQ1** | IO7 | **gpio355** | gpiochip4 base312 + line43 |

### 2.3 Configurar i controlar els GPIOs

```bash
# 1. Exportar GPIOs
echo 355 > /sys/class/gpio/export   # DQ1
echo 360 > /sys/class/gpio/export   # DQ0
echo 487 > /sys/class/gpio/export   # IO7-direction (PCAL9535)
echo 488 > /sys/class/gpio/export   # IO8-direction (PCAL9535)

# 2. PCAL9535: configurar direcció (HARDWARE) ⚠️ PAS CRÍTIC!
echo 1 > /sys/class/gpio/gpio487/value   # IO7-dir = output (DQ1)
echo 1 > /sys/class/gpio/gpio488/value   # IO8-dir = output (DQ0)

# 3. Configurar direcció dels GPIOs natius
echo out > /sys/class/gpio/gpio355/direction   # DQ1
echo out > /sys/class/gpio/gpio360/direction   # DQ0

# 4. Provar DQ0 (X12-9)
echo 1 > /sys/class/gpio/gpio360/value   # DQ0 ON 🟢
echo 0 > /sys/class/gpio/gpio360/value   # DQ0 OFF ⚫

# 5. Provar DQ1 (X12-10)
echo 1 > /sys/class/gpio/gpio355/value   # DQ1 ON 🟢
echo 0 > /sys/class/gpio/gpio355/value   # DQ1 OFF ⚫

# 6. Llegir estat
cat /sys/class/gpio/gpio355/value   # DQ1: 0 o 1
cat /sys/class/gpio/gpio360/value   # DQ0: 0 o 1
```

### 2.4 Node-RED: Dashboard

1. Obre **http://192.168.200.1:1880/** al navegador
2. Menú ☰ → **Import** → **Clipboard**
3. Obre `nodered-flow/flow.json` i enganxa'l
4. Fes clic a **Deploy**

El dashboard estarà a **http://192.168.200.1:1880/ui/** amb 4 botons per controlar les DQ.

---

## 📋 Resum de la pràctica

| Pas | Què fem | Comandes clau |
|-----|---------|---------------|
| 1 | Cablejar | Alimentació 24V a X12-7 i X12-8. LED entre DQ i M1 |
| 2 | Accedir | PuTTY → 192.168.200.1 → root / 123456 |
| 3 | Exportar | `echo 355 > /sys/class/gpio/export` (i 360, 487, 488) |
| 4 | PCAL9535 | `echo 1 > /sys/class/gpio/gpio487/value` |
| 5 | Dirigir | `echo out > /sys/class/gpio/gpio355/direction` |
| 6 | Provar | `echo 1 > /sys/class/gpio/gpio360/value` → LED 🟢 |
| 7 | Node-RED | http://192.168.200.1:1880/ui/ |

---

## 📌 Apèndix A: Configuració permanent (rc.local)

Per no repetir els passos 2.3 cada vegada:

```bash
nano /etc/rc.local
```

Afegiu **abans del `exit 0`**:

```bash
echo 355 > /sys/class/gpio/export 2>/dev/null
echo 360 > /sys/class/gpio/export 2>/dev/null
echo 487 > /sys/class/gpio/export 2>/dev/null
echo 488 > /sys/class/gpio/export 2>/dev/null
echo 1 > /sys/class/gpio/gpio487/value
echo 1 > /sys/class/gpio/gpio488/value
echo out > /sys/class/gpio/gpio355/direction
echo out > /sys/class/gpio/gpio360/direction
echo 0 > /sys/class/gpio/gpio355/value
echo 0 > /sys/class/gpio/gpio360/value
exit 0
```

```bash
chmod +x /etc/rc.local
systemctl enable rc-local
```

## 📌 Apèndix B: Reset per a la pràctica

Per començar de zero:

```bash
# Opció 1 (recomanat)
reboot

# Opció 2 (sense reiniciar)
echo 0 > /sys/class/gpio/gpio355/value
echo 0 > /sys/class/gpio/gpio360/value
echo 355 > /sys/class/gpio/unexport 2>/dev/null
echo 360 > /sys/class/gpio/unexport 2>/dev/null
echo 487 > /sys/class/gpio/unexport 2>/dev/null
echo 488 > /sys/class/gpio/unexport 2>/dev/null
```

---

*Pràctica 1 — Mòdul IOT2050 Siemens*
