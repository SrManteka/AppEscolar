# Publicar una nueva versión

Runbook — pasos mecánicos para sacar una build nueva y compartirla. El razonamiento detrás de cada decisión (por qué manual, por qué esos jobs) está en `docs/decisiones.md`, "Pipeline implementado" — esto es solo la receta.

## Pasos

1. `git push` con los cambios ya commiteados a `main`.
2. En GitHub: pestaña **Actions** → workflow **"Build"** → botón **"Run workflow"** (rama `main`). Es manual a propósito, no se dispara solo en cada push.
3. Esperar a que terminen los dos jobs (`android`, `ios-sin-firmar`) — unos minutos cada uno, corren en paralelo.
   - Con `gh` desde terminal: `gh workflow run build.yml` para disparar, `gh run watch` para esperar el resultado.
4. Bajar los artifacts desde la página del run (sección "Artifacts" al final) o vía `gh run download <run-id>`.
5. Compartir:
   - **Android:** mandar el `.apk` directo — WhatsApp, Drive, USB, lo que sea más fácil.
   - **iPhone:** subir el `.ipa` a una GitHub Release del repo (o compartir el archivo directo si prefieres no crear una Release cada vez), y mandarle a cada amigo `docs/instalacion.md` para que lo instale con SideStore.

## Si algo falla

- **El job de iOS falla en el paso de empaquetado del `.ipa`:** revisar que `flutter build ios --release --no-codesign` haya terminado bien antes de ese paso — el log del job lo muestra.
- **Cualquier job falla por dependencias/versión de Flutter:** revisar que `subosito/flutter-action` esté usando el canal `stable` correcto contra el `environment: sdk:` de `pubspec.yaml`.
- **La cuenta de GitHub bloquea el run con un mensaje de facturación:** no es el workflow — hay que revisar `https://github.com/settings/billing`.
