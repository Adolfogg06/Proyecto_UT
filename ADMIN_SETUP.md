# Administrador para el prototipo

El primer administrador se provisiona manualmente desde Firebase Console. La app no ofrece registro de administradores.

1. Registra en la app una cuenta normal de consumidor con el correo que usaras como administrador.
2. En Firebase Console, abre Authentication, busca esa cuenta y copia su UID.
3. Abre Firestore y edita `users/{UID}`. Cambia `role` de `consumidor` a `admin`; conserva `accountStatus: approved`.
4. Cierra sesion y vuelve a entrar con esa cuenta. Abrira la bandeja de solicitudes pendientes.

Las nuevas cuentas de comercio se crean con `accountStatus: pending`. Un administrador puede aprobarlas o rechazarlas desde la bandeja. Los perfiles pendientes no pueden publicar canastas; la regla tambien bloquea la publicacion aunque alguien intente llamar directamente a Firestore.

Esta provision manual es adecuada para el prototipo. Para produccion, provisiona administradores desde un entorno confiable con Firebase Admin SDK o claims personalizados y verifica la documentacion legal/comercial del establecimiento antes de aprobarlo.
