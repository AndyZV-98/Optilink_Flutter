# OptiLink B2B

App Flutter para que las ópticas hagan pedidos de lunas a un distribuidor
mayorista. Usa Firebase Auth para el inicio de sesión y Cloud Firestore para el
catálogo y los pedidos. Precios en dólares (mercado ecuatoriano).

## Qué hace

- **Inicio de sesión** con correo y contraseña, y recuperación de contraseña.
  Las cuentas las crea el distribuidor en la consola de Firebase.
- **Catálogo** en tiempo real desde la colección `products`.
- **Carrito** con control de cantidades limitado por el stock.
- **Confirmar pedido**: guarda el pedido en la colección `orders`.
- **Pedidos**: lista y detalle de los pedidos de la óptica, con su estado.

Todavía no hay panel de administración: los productos y el estado de los
pedidos se gestionan desde la consola de Firebase.

## Datos en Firestore

`products/{id}`

| Campo | Tipo | Notas |
|---|---|---|
| `name` | string | |
| `category` | string | |
| `description` | string | |
| `price` | number | Precio unitario en dólares |
| `stock` | number | Opcional. Si falta, el producto no tiene límite de unidades |
| `imageUrl` | string | Opcional |
| `isFeatured` | bool | Opcional |

`orders/{id}` (lo crea la app al confirmar un pedido)

| Campo | Tipo | Notas |
|---|---|---|
| `userId` | string | UID de la óptica |
| `userEmail` | string | Correo de la óptica |
| `orderDate` | timestamp | Fecha del servidor |
| `totalAmount` | number | Total en dólares |
| `status` | string | Empieza en `Pendiente`. Otros que la app reconoce: `Aprobado`, `Enviado`, `Entregado`, `Cancelado` |
| `items` | lista | Cada ítem: `productId`, `name`, `price`, `quantity`, `subtotal`, `imageUrl` |

Las reglas de seguridad están en `firestore.rules`. Se publican con
`firebase deploy --only firestore:rules`.

## Desarrollo

Requiere Flutter 3.35 o superior.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Las pruebas usan un Firestore y un Auth simulados en memoria, así que no
necesitan conexión ni credenciales.
