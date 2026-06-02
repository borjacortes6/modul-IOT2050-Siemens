# Mòdul IOT2050 Siemens

Pràctiques amb el **SIMATIC IOT2050 Basic PG2** i el **Shield IO 6ES7647-0KA01-0AA2**.

## 📚 Pràctiques disponibles

| # | Títol | Català | Castellano |
|---|-------|--------|------------|
| 1 | Control de sortides digitals DQ | [`practica-1/README.ca.md`](practica-1/README.ca.md) | [`practica-1/README.es.md`](practica-1/README.es.md) |
| 2 | Lectura d'entrades digitals DI | [`practica-2/README.ca.md`](practica-2/README.ca.md) | [`practica-2/README.es.md`](practica-2/README.es.md) |

## 📁 Estructura del repositori

```
modul-IOT2050-Siemens/
├── practica-1/
│   ├── README.ca.md          ← Guia en català
│   ├── README.es.md          ← Guía en castellano
│   ├── scripts/
│   │   ├── export-gpios.sh   ← Exporta i configura GPIOs
│   │   └── setup-gpios.sh    ← Per a rc.local (arrencada)
│   ├── nodered-flow/
│   │   └── flow.json         ← Flow Node-RED (4 botons DQ)
│   └── images/
│       ├── structure-page7.png
│       ├── hardware-interface-pinout.png
│       ├── wiring-power-dq.png
│       ├── wiring-digital-inputs.png
│       └── wiring-digital-outputs-analog.png
└── practica-2/
    ├── README.ca.md          ← Guia en català
    ├── README.es.md          ← Guía en castellano
    └── nodered-flow/
        └── flow-di.json      ← Flow Node-RED (lectura DI)
```

## 🔗 Enllaços útils

- **Manual oficial Siemens:** https://support.industry.siemens.com/cs/document/109745681/
- **Repositori de documentació completa:** https://github.com/borjacortes6/iot2050-io-shield

## 📄 Llicència

MIT — Ús educatiu lliure
