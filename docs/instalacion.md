# Cómo instalar NotesFS

Guía para probar la app — no es un producto público, es un proyecto personal compartido con un grupo cercano de amigos para probarla y darme feedback.

## Android

1. Te paso el archivo `.apk`.
2. Ábrelo. El teléfono probablemente te avise que "no se permiten instalaciones de fuentes desconocidas" — dale **permitir** (solo aplica a este archivo, no cambia nada más de tu teléfono).
3. Instalar. Listo, ya está.

## iPhone — guía completa, paso a paso

Es más largo que lo de Android — no por culpa de la app, sino porque Apple pone varios rodeos deliberados para instalar algo fuera de su App Store. La primera vez toma entre 20 y 40 minutos con calma; después de eso, casi no hay que volver a tocar nada.

### 0. Qué vas a necesitar

- Una computadora (Windows, Mac o Linux) — **solo para este primer setup**, no la vuelves a necesitar después salvo que algo falle.
- Cable para conectar el iPhone a la computadora.
- Tu Apple ID normal (el mismo con el que ya usas el App Store) y su contraseña — nada de crear cuenta nueva.
- Los dos estar en la **misma red WiFi** durante el proceso (computadora e iPhone).

### 1. Instalar iTunes de Apple en la computadora (si usas Windows)

Windows necesita los drivers de Apple para reconocer el iPhone por USB. **Tiene que ser el iTunes descargado directo del sitio de Apple**, no el de la Microsoft Store — es una versión distinta y con esta no funciona bien.

- Descárgalo desde [apple.com/itunes](https://www.apple.com/itunes/) (no desde la tienda de Windows).
- Instálalo y ábrelo una vez para que termine de configurarse.
- Conecta tu iPhone por cable → en el iPhone va a aparecer un aviso "¿Confiar en esta computadora?" → **Confiar** → mete tu código del iPhone si te lo pide.

### 2. Activar el Modo Desarrollador en el iPhone

Este paso es fácil de pasar por alto porque **la opción no aparece en Ajustes hasta que el sistema la necesita** — no busques esto antes de tiempo, se activa solo un poco más adelante en el proceso (después de intentar instalar SideStore por primera vez). Cuando aparezca:

1. **Ajustes → Privacidad y Seguridad → Modo Desarrollador**
2. Activa el interruptor.
3. El iPhone te va a pedir **reiniciar** — dale reiniciar.
4. Al prender de nuevo, aparece una alerta del sistema — dale **Activar**, y mete tu código del iPhone cuando lo pida.

Sin este paso, cualquier app instalada así (incluida SideStore misma) se va a negar a abrir.

### 3. Generar el "pairing file" (solo en Windows)

SideStore necesita un archivo que le permita hablar con tu iPhone sin necesitar el cable después. Se genera con una herramienta de línea de comandos llamada `jitterbugpair`:

1. Descarga `jitterbugpair` desde la [documentación oficial de SideStore](https://docs.sidestore.io).
2. Conecta el iPhone por cable, **desbloqueado**, en la pantalla de inicio.
3. Abre la terminal (Símbolo del sistema o PowerShell) en la carpeta donde descargaste el archivo.
4. Corre el programa (doble clic o `jitterbugpair.exe` desde la terminal).
5. En el iPhone va a aparecer un aviso de confiar — acepta.

Esto genera un archivo de "pairing" que SideStore usa más adelante — no lo borres hasta terminar todo el proceso.

### 4. Instalar el instalador de SideStore en la computadora

1. Descarga el instalador para Windows desde [sidestore.io](https://sidestore.io) / [docs.sidestore.io](https://docs.sidestore.io).
2. Instálalo y ábrelo — busca su ícono en la bandeja del sistema (junto al reloj, abajo a la derecha).
3. Si Windows pregunta por permisos de red privada/firewall, **permite el acceso** — sin esto no encuentra al iPhone en la red.

### 5. El servidor Anisette (la parte más confusa, pero se hace una sola vez)

Para poder "firmar" la app en tu nombre, SideStore necesita algo llamado **datos Anisette** — información que normalmente solo genera una Mac. La app resuelve esto conectándose a un servidor que simula esa parte.

- La app suele traer uno o varios servidores públicos preconfigurados — en la mayoría de los casos **no tienes que hacer nada aquí, solo dejar el que viene por default**.
- Si el servidor público falla o tu Apple ID se comporta raro después (pide verificación en dos pasos todo el tiempo), es señal de que ese servidor público está sobrecargado — la comunidad de SideStore mantiene una [lista de servidores alternativos](https://github.com/SideStore/anisette-servers) para cambiar a otro.
- No necesitas entender cómo funciona por dentro — solo saber que si algo de la firma falla más adelante sin explicación, este es el primer lugar a revisar.

### 6. Instalar SideStore en el iPhone

1. Desde el ícono de SideStore en la computadora (bandeja del sistema), busca la opción de instalar en el dispositivo conectado.
2. Te va a pedir tu **Apple ID y contraseña** — es para firmar la app con tu cuenta, no se comparte con nadie más que Apple.
3. Espera a que termine — aparece un ícono nuevo de SideStore en el iPhone.
4. Ábrelo en el iPhone. Si no abre y te dice "desarrollador no confiable", repite el paso 2 de este documento (Modo Desarrollador) si todavía no lo activaste, y sigue con el paso 7.

### 7. Confiar en el certificado del desarrollador

1. En el iPhone: **Ajustes → General → VPN y Gestión de Dispositivos**
2. Busca tu Apple ID bajo "App de Desarrollador"
3. Tócalo → **Confiar en [tu correo]** → confirma.
4. Ahora sí, abre SideStore desde el iPhone — debería abrir normal.

### 8. Instalar la app (NotesFS)

1. Te paso el archivo `.ipa`.
2. Ábrelo con SideStore (o dentro de SideStore, usa la opción de agregar/instalar un `.ipa`).
3. Espera a que termine de firmar e instalar — el ícono de NotesFS va a aparecer en tu pantalla de inicio.

### 9. Mantenimiento — lo que sigue después

- **La firma expira cada 7 días.** SideStore la renueva sola en automático si la dejas correr de vez en cuando en segundo plano y tu iPhone tiene internet — no necesitas la computadora otra vez.
- Si un día NotesFS no abre de la nada, abre SideStore, espera un par de minutos a que refresque, e inténtalo de nuevo.
- Si después de eso sigue sin abrir, probablemente haya que repetir el paso 6 (reinstalar desde SideStore) — avísame y lo vemos juntos.

## Preguntas frecuentes

- **¿Me va a cobrar algo?** No, nunca — ni a ti ni a mí. Todo esto usa las funciones gratuitas de tu Apple ID.
- **¿Es seguro?** Sí. Es tu propio Apple ID, la app la hice yo, y el proceso completo (Modo Desarrollador, pairing file, Anisette) son mecanismos oficiales de Apple/comunidad open-source para instalar apps fuera de la App Store — no es un truco raro ni malware.
- **¿Por qué no está en la App Store?** Es un proyecto personal, no comercial — no busco publicarla ahí.
- **Se sintió largo/tedioso.** Sí, la primera vez lo es — es la naturaleza de sortear las restricciones de Apple sin pagar la cuota de desarrollador. Una vez hecho, el uso día a día es completamente normal.
