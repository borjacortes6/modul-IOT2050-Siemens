# Práctica 1: Control de salidas digitales DQ con el Siemens IOT2050

**Módulo:** SIMATIC IOT2050 Basic PG2 + Shield IO 6ES7647-0KA01-0AA2
**Duración:** 2 horas
**Objetivo:** Aprender a identificar, cablear y controlar las salidas digitales DQ del shield IO.

---

## 🎯 Objetivos

- Identificar los conectores y bornes del shield IO
- Cablear correctamente las salidas DQ con alimentación externa
- Acceder al IoT2050 vía SSH (PuTTY)
- Descubrir los GPIOs de las salidas con `gpioinfo`
- Configurar el PCAL9535 (control de dirección hardware)
- Activar/desactivar las DQ desde terminal
- Controlar las DQ desde el dashboard de Node-RED

---

## 🔧 PARTE 1 — HARDWARE

### 1.1 Conectores del shield

El shield 6ES7647-0KA01-0AA2 tiene **dos conectores**:

**X11 (inferior) — Entradas digitales:**
| Borne | Señal |
|-------|-------|
| 1 | M0 |
| 2 | DI0 |
| 3 | DI1 |
| 4 | DI2 |
| 5 | DI3 |
| 6 | DI4 |

**X12 (superior) — Analógicas + Alimentación + Salidas:**
| Borne | Señal |
|-------|-------|
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

### 1.2 Cableado

> ⚠️ Las salidas DQ necesitan **alimentación externa 24V DC** en L+ (X12-7) y M1 (X12-8). Sin esto NO funcionan.

**Esquema de cableado:**

```
Fuente 24V ──┬── X12-7 (L+)
             └── X12-8 (M1)

X12-9  (DQ0) ──── LED 🔴 ──── R 1kΩ ──── X12-8 (M1)
X12-10 (DQ1) ──── LED 🔴 ──── R 1kΩ ──── X12-8 (M1)
```

Las DQ son **PNP (current-sourcing)**: proporcionan +24V cuando se activan. La corriente circula desde la DQ, a través de la carga, hacia M1.

---

## 💻 PARTE 2 — SOFTWARE

### 2.1 Acceso al IoT2050

1. Abre **PuTTY**
2. Host Name: `192.168.200.1`
3. Puerto: `22`, SSH
4. Usuario: `root`
5. Contraseña: `123456`

### 2.2 Descubrir los GPIOs

```bash
# Ver todos los gpiochips
gpiodetect

# Detalle de cada chip
gpioinfo gpiochip3
gpioinfo gpiochip4
```

**Mapping verificado:**

| Señal | IO | GPIO | Fórmula |
|-------|-----|------|---------|
| DI0 | IO0 | gpio437 | gpiochip3 base408 + line29 |
| DI1 | IO1 | gpio438 | gpiochip3 base408 + line30 |
| DI2 | IO2 | gpio439 | gpiochip3 base408 + line31 |
| DI3 | IO3 | gpio441 | gpiochip3 base408 + line33 |
| DI4 | IO4 | gpio345 | gpiochip4 base312 + line33 |
| **DQ0** | IO8 | **gpio360** | gpiochip4 base312 + line48 |
| **DQ1** | IO7 | **gpio355** | gpiochip4 base312 + line43 |

### 2.3 Configurar y controlar los GPIOs

```bash
# 1. Exportar GPIOs
echo 355 > /sys/class/gpio/export   # DQ1
echo 360 > /sys/class/gpio/export   # DQ0
echo 487 > /sys/class/gpio/export   # IO7-direction (PCAL9535)
echo 488 > /sys/class/gpio/export   # IO8-direction (PCAL9535)

# 2. PCAL9535: configurar dirección (HARDWARE) ⚠️ ¡PASO CRÍTICO!
echo 1 > /sys/class/gpio/gpio487/value   # IO7-dir = output (DQ1)
echo 1 > /sys/class/gpio/gpio488/value   # IO8-dir = output (DQ0)

# 3. Configurar dirección de los GPIOs nativos
echo out > /sys/class/gpio/gpio355/direction   # DQ1
echo out > /sys/class/gpio/gpio360/direction   # DQ0

# 4. Probar DQ0 (X12-9)
echo 1 > /sys/class/gpio/gpio360/value   # DQ0 ON 🟢
echo 0 > /sys/class/gpio/gpio360/value   # DQ0 OFF ⚫

# 5. Probar DQ1 (X12-10)
echo 1 > /sys/class/gpio/gpio355/value   # DQ1 ON 🟢
echo 0 > /sys/class/gpio/gpio355/value   # DQ1 OFF ⚫

# 6. Leer estado
cat /sys/class/gpio/gpio355/value   # DQ1: 0 o 1
cat /sys/class/gpio/gpio360/value   # DQ0: 0 o 1
```

### 2.4 Node-RED: Dashboard

1. Abre **http://192.168.200.1:1880/** en el navegador
2. Menú ☰ → **Import** → **Clipboard**
3. Abre `nodered-flow/flow.json` y pégalo
4. Haz clic en **Deploy**

El dashboard estará en **http://192.168.200.1:1880/ui/** con 4 botones para controlar las DQ.

---

## 📋 Resumen de la práctica

| Paso | Qué hacemos | Comandos clave |
|------|------------|----------------|
| 1 | Cablear | Alimentación 24V en X12-7 y X12-8. LED entre DQ y M1 |
| 2 | Acceder | PuTTY → 192.168.200.1 → root / 123456 |
| 3 | Exportar | `echo 355 > /sys/class/gpio/export` (y 360, 487, 488) |
| 4 | PCAL9535 | `echo 1 > /sys/class/gpio/gpio487/value` |
| 5 | Dirigir | `echo out > /sys/class/gpio/gpio355/direction` |
| 6 | Probar | `echo 1 > /sys/class/gpio/gpio360/value` → LED 🟢 |
| 7 | Node-RED | http://192.168.200.1:1880/ui/ |

---

## 📌 Apéndice A: Configuración permanente (rc.local)

Para no repetir los pasos 2.3 cada vez:

```bash
nano /etc/rc.local
```

Añade **antes del `exit 0`**:

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

## 📌 Apéndice B: Reset para la práctica

Para empezar de cero:

```bash
# Opción 1 (recomendada)
reboot

# Opción 2 (sin reiniciar)
echo 0 > /sys/class/gpio/gpio355/value
echo 0 > /sys/class/gpio/gpio360/value
echo 355 > /sys/class/gpio/unexport 2>/dev/null
echo 360 > /sys/class/gpio/unexport 2>/dev/null
echo 487 > /sys/class/gpio/unexport 2>/dev/null
echo 488 > /sys/class/gpio/unexport 2>/dev/null
```

---

*Práctica 1 — Módulo IOT2050 Siemens*
