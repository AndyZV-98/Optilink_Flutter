# OptiLink B2B

App Flutter para que las ópticas hagan pedidos de lunas a un distribuidor
mayorista. Usa Firebase Auth para las cuentas y Cloud Firestore para el
catálogo y los pedidos. Precios en dólares (mercado ecuatoriano). Funciona en
Android y en web.

## Qué hace

**Óptica**

- Se registra con sus datos (razón social, RUC, contacto, teléfono, dirección)
  y queda pendiente hasta que el distribuidor la aprueba.
- Catálogo en tiempo real, con buscador por nombre o código y filtro por tipo
  de luna.
- Carrito con cantidades limitadas por el stock y confirmación del pedido.
- Lista y detalle de sus pedidos, con el estado de cada uno.

**Distribuidor (administrador)**

- Pedidos de todas las ópticas, con filtro por estado. Aprobar, enviar,
  entregar o cancelar. Al aprobar se descuenta el stock; si no alcanza, el
  pedido no se aprueba. Cancelar un pedido aprobado devuelve el stock.
- Productos: alta, edición y desactivación.
- Carga y descarga del catálogo en Excel.
- Ópticas: aprobar o rechazar solicitudes, y quitar el acceso.

## Puesta en marcha

1. **Reglas de seguridad.** Publica `firestore.rules`:
   `firebase deploy --only firestore:rules`. Reemplazan las reglas que tenga
   el proyecto.
2. **Primer administrador.** Se crea a mano una sola vez. Crea la cuenta en
   Firebase Authentication y, en Firestore, el documento `users/{uid}` (con el
   UID de esa cuenta) con estos campos:

   | Campo | Valor |
   |---|---|
   | `email` | el correo de la cuenta |
   | `businessName` | nombre del distribuidor |
   | `role` | `admin` |
   | `status` | `aprobado` |

3. **Catálogo.** Entra como administrador, ve a Productos → Cargar / descargar
   Excel, descarga la plantilla, llénala y cárgala.
4. **Web (opcional).** `flutter build web` y `firebase deploy --only hosting`.

Las cuentas que existían antes de los perfiles deben completar sus datos al
iniciar sesión y quedan pendientes de aprobación.

## Excel del catálogo

La primera fila lleva los títulos. Las columnas pueden ir en cualquier orden y
las que no reconoce la app se ignoran.

| Columna | Obligatoria | Notas |
|---|---|---|
| Código | Sí | Identifica al producto: si ya existe se actualiza; si no, se crea |
| Nombre | Sí | |
| Precio | Sí | En dólares. Acepta `12,50` o `12.50` |
| Tipo | No | Monofocal, Bifocal, Progresivo… Vacío: General |
| Material | No | |
| Índice | No | Número entre 1 y 2 |
| Tratamiento | No | |
| Descripción | No | |
| Stock | No | Entero. Vacío: sin control de stock |
| Imagen (URL) | No | |
| Activo | No | Sí o No. Vacío: Sí |

- Antes de guardar se muestra cuántos productos se crean y cuántos se
  actualizan.
- Si alguna fila tiene un error se indica la fila y el motivo, y no se guarda
  nada hasta corregir el archivo.
- La carga nunca borra: los productos que no están en el archivo no cambian.
  Si falta una columna opcional, ese dato no se modifica en los productos que
  ya existen.

## Datos en Firestore

`users/{uid}`

| Campo | Notas |
|---|---|
| `email`, `businessName`, `ruc`, `address`, `phone`, `contactName` | Datos de la óptica |
| `role` | `optica` o `admin` |
| `status` | `pendiente`, `aprobado` o `rechazado` |
| `createdAt` | Fecha del servidor |

`products/{id}`

| Campo | Notas |
|---|---|
| `sku` | Código, único por producto |
| `name`, `description`, `material`, `treatment`, `imageUrl` | Texto |
| `category` | Tipo de luna |
| `index` | Índice de refracción; número o nulo |
| `price` | Precio unitario en dólares |
| `stock` | Entero, o nulo si no lleva control de stock |
| `active` | Los inactivos no se muestran a las ópticas |

`orders/{id}`

| Campo | Notas |
|---|---|
| `userId`, `userEmail`, `businessName` | Óptica que hizo el pedido |
| `orderDate` | Fecha del servidor |
| `totalAmount` | Total en dólares |
| `status` | `Pendiente`, `Aprobado`, `Enviado`, `Entregado` o `Cancelado` |
| `stockDeducted` | `true` si al aprobar se descontó el stock |
| `items` | Lista: `productId`, `name`, `price`, `quantity`, `subtotal`, `imageUrl` |

## Desarrollo

Requiere Flutter 3.35.

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # Android
flutter run -d chrome  # Web
```

Las pruebas usan un Firestore y un Auth simulados en memoria, así que no
necesitan conexión ni credenciales.

Notas:

- Las versiones de `cloud_firestore` y `firebase_auth` están fijadas en
  `pubspec.yaml`; ahí se explica por qué.
- Para compilar en iOS hay que subir el destino mínimo del proyecto a iOS 15,
  que es lo que exige esta versión de Firebase.
