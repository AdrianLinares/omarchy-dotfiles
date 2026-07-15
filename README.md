# omarchy-dotfiles

Personal dotfiles que integran [**Gentleman.Dots**](https://github.com/Gentleman-Programming/Gentleman.Dots) sobre [**Omarchy**](https://github.com/omarchy-linux/omarchy) en Arch Linux.

Este repositorio registra **la configuración final, activa y verificada** de tres piezas que el instalador de Gentleman.Dots no deja 100% operativas cuando coexisten con Omarchy: **Ghostty**, **tmux** y **fish**.

> Las configs de Omarchy (hypr, waybar, mako, walker, omarchy) se incluyen como referencia del estado-base; el foco de este commit es la capa Gentleman.Dots.

---

## 0. Por qué este repo existe

El instalador `gentleman-dots` (fórmula Homebrew) escribe:

- `~/.tmux.conf` (config de tmux + lista de plugins TPM)
- `~/.config/ghostty/config` + un bundle de shaders
- `~/.config/fish/config.fish` y archivos `conf.d`/`functions`

El problema que resolvimos: con `XDG_CONFIG_HOME` activo (Omarchy lo define en el entorno), **tmux 3.7 prioriza `~/.config/tmux/tmux.conf` sobre `~/.tmux.conf`**. Omarchy preinstala el primero, por lo que el de Gentleman.Dots queda silenciosamente ignorado y TPM nunca carga los plugins (kanagawa, vim-tmux-navigator, tmux-yank, etc.).

Este repo deja el config de Gentleman.Dots en la ruta XDG y deja `~/.tmux.conf` como **symlink** hacia ese archivo, adicionalmente **pin-neando** `TMUX_PLUGIN_MANAGER_PATH` en el config para que futuras reinstalaciones no puedan volver a desincronizar.

---

## 1. Requisitos previos (máquina destino)

Antes de aplicar este repo, la máquina destino debe tener Omarchy corriendo y:

- **Arch Linux** (o derivado compatible con los paquetes listados)
- **Homebrew / Linuxbrew** instalado
- **Git**, **stow** (opcional pero recomendado para aplicar los dotfiles)
-Usuario con permiso de `sudo` para cambiar el login shell

Verificar:

```bash
ls ~/.config/omarchy/current/theme.name   # Omarchy presente
command -v brew && brew --version          # Homebrew
command -v git && command -v stow          # utilidades
```

_TODO el resto de dependencias se instalan en los pasos siguientes._

---

## 2. Instalación de la funda Gentleman.Dots

### 2.1. Fórmula y binario del instalador TUI

```bash
brew tap gentleman-programming/tap
brew install gentleman-dots
```

Esto instala el binario `gentleman-dots` (ELF Go, ~5 MB), un instalador TUI para Fish+Tmux+Ghostty y Neovim.

### 2.2. Ejecutar el instalador (no-interactivo)

```bash
gentleman-dots --non-interactive --shell=fish --terminal=ghostty --wm=tmux --nvim
```

Flags usados en esta configuración:

- `--shell=fish`
- `--terminal=ghostty`
- `--wm=tmux`
- `--nvim`
- `--backup=true` (default: respalda configs existentes en `~/.gentleman-backup-<ts>/`)

El instalador genera `~/.tmux.conf`, `~/.config/ghostty/config`, `~/.config/fish/config.fish`, crea dirs placeholder `~/.tmux/plugins/<plugin>` (vacíos) y un bundle de ~50 shaders en `~/.config/ghostty/shaders/`.

### 2.3. Fish como login shell

```bash
# Fish viene de Linuxbrew; verificar ruta absoluta
BREW_FISH=$(command -v fish)
echo "$BREW_FISH"   # Debe ser /home/linuxbrew/.linuxbrew/bin/fish

# Agregar a /etc/shells si no está
grep -q "$BREW_FISH" /etc/shells || echo "$BREW_FISH" | sudo tee -a /etc/shells

# Cambiar login shell
chsh -s "$BREW_FISH"
```

`~/.tmux.conf` referencia `/home/linuxbrew/.linuxbrew/bin/fish` explícitamente (`set -g default-command` y `default-shell`). Si Linuxbrew está en otra ruta, ajustar esas dos líneas.

---

## 3. Resolución del conflicto tmux (paso crítico)

Tras el paso 2.2, **~/.tmux.conf (Gentleman.Dots) y ~/.config/tmux/tmux.conf (Omarchy) coexisten**. tmux 3.7 cargará el segundo y el primero será ignorado. Hay que promover Gentleman.Dots a la ruta XDG y dejar `~/.tmux.conf` como symlink.

```bash
# Respaldar el de Omarchy (NO pérdida de datos)
cp ~/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf.omarchy.bak

# Promover Gentleman.Dots a la ruta XDG (la que tmux realmente lee)
mv ~/.tmux.conf ~/.config/tmux/tmux.conf

# Symlink clásico -> XDG para futuras reinstalaciones
ln -s ~/.config/tmux/tmux.conf ~/.tmux.conf
```

El `tmux.conf` versionado en este repo **ya incluye** la línea de pin al inicio, para que TPM no vuelva a dividirse entre rutas:

```tmux
set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.config/tmux/plugins/"
```

Si en lugar de copiar este repo aplicás el archivo versionado directamente, esa línea viene incluida; solo asegurate de que el `set-environment` quede antes del `set -g @plugin 'tmux-plugins/tpm'` y del `run '~/.tmux/plugins/tpm/tpm'`.

---

## 4. Instalar plugins TPM

TPM (Tmux Plugin Manager) ya queda clone-executable tras el instalador, pero los plugins listados en el `tmux.conf` están como dirs vacíos (placeholder). Hay que clonarlos de verdad:

```bash
# Si ~/.tmux/plugins/tpm no existe todavía:
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Clonar los 7 plugins declarados
~/.tmux/plugins/tpm/bin/install_plugins
```

Salida esperada (7 "download success"):

```
Installing "tpm"                         ... download success
Installing "tmux-sensible"              ... download success
Installing "tmux-yank"                  ... download success
Installing "vim-tmux-navigator"         ... download success
Installing "tmux-resurrect"             ... download success
Installing "tmux-which-key"              ... download success
Installing "tmux-kanagawa"              ... download success
```

Plugins clonados en `~/.config/tmux/plugins/` (ruta de TPM bajo XDG). Verificar:

```bash
for d in tpm tmux-sensible tmux-yank vim-tmux-navigator \
         tmux-resurrect tmux-which-key tmux-kanagawa; do
  p=~/.config/tmux/plugins/$d
  [ -d "$p/.git" ] && echo "OK  $d @ $(git -C $p rev-parse --short HEAD)"
done
```

El script anterior debe listar los 7 con un hash corto cada uno.

---

## 5. Dependencias del entorno fish

El `config.fish` de Gentleman.Dots inicializa varias herramientas CLI. Instalarlas todas vía Homebrew:

```bash
brew install fisher starship zoxide atuin fzf carapace \
             nvm rustup-init coreutils
```

Notas:

- **`coreutils`** es **imprescindible en Linux**: el `config.fish` define `alias ls='gls --color=auto'` en Linux (gls es el binario GNU `ls` de coreutils, no el de busybox). Sin coreutils, todo `ls` falla con "command not found: gls".
- **`fisher`** es el gestor de plugins de fish; el `config.fish` lo auto-instala vía `curl | source` si no está, pero instalarlo por brew da una versión estable y offline.
- **`carapace`** provee completions multi-shell; en `config.fish` se corre `carapace --list | ... | xargs touch` para crear stubs en `~/.config/fish/completions/` (esos stubs son derivados y **no se comitean** — ver `.gitignore`).
- **`nvm`** (jorgebucaran/nvm.fish) está auto-gestionado por Fisher.

### Plugins fish (via Fisher, ya versionados en `fish_plugins`)

```bash
fisher install jorgebucaran/fisher
fisher install jorgebucaran/nvm.fish
fisher install patrickf1/fzf.fish
fisher install oh-my-fish/plugin-pj
```

Los archivos `functions/nvm.fish`, `functions/fisher.fish`, `functions/pj.fish`, `functions/tmux.fish` y `conf.d/nvm.fish` son parte de esos plugins y se incluyen en el repo por conveniencia (para inspección offline); fisher los reescribirá idempotente al reinstalar.

---

## 6. Aplicar este repo a la nueva máquina

### 6.1. Clonar

```bash
git clone https://github.com/AdrianLinares/omarchy-dotfiles.git ~/omarchy-dotfiles
```

### 6.2. Aplicar con stow (recomendado)

```bash
cd ~/omarchy-dotfiles
# stow creará los symlinks bajo ~/.config para cada subdirectorio de .config/
stow --adopt --target="$HOME" .config
# Para paquetes individuales:
#   stow --target="$HOME" .config/ghostty
#   stow --target="$HOME" .config/tmux
#   stow --target="$HOME" .config/fish
```

### 6.2-alt. Aplicar copiando (sin stow)

```bash
cp -r .config/ghostty/config .config/ghostty/shaders \
      ~/.config/ghostty/
cp .config/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf

mkdir -p ~/.config/fish
cp .config/fish/config.fish .config/fish/fish_plugins \
   .config/fish/fish_variables ~/.config/fish/
cp -r .config/fish/conf.d   ~/.config/fish/
cp -r .config/fish/functions ~/.config/fish/
cp -r .config/fish/themes   ~/.config/fish/
```

### 6.3. Symlink del shader (la config usa ruta relativa a `~/.config/ghostty`)

```bash
# ghostty resuelve `custom-shader = shaders/cursor_smear_gentleman.glsl`
# como relativo a ~/.config/ghostty/, así que solo copiarlo ahí basta:
ls ~/.config/ghostty/shaders/cursor_smear_gentleman.glsl
```

---

## 7. Verificación final (una terminal fish nueva)

Abrí una **nueva terminal Ghostty** y ejecutá:

```bash
# Fish cargó gentleman-dots
echo $fish_color_command   # 7AA89F cyan  -> matches config.fish línea ~103
echo $fish_color_param     # A3B5D6 purple
echo $fish_greeting        # "" (vacío)
fish_vi_key_bindings; echo $vi_mode   # 'normal' o similar

# Fish: ls funciona (gls existe)
brew list coreutils | grep bin/gls
ls ~                    # no debe tirar "command to run: gls"

# Tmux arrancó por config.fish (línea 42-44) y ahora carga gentleman-dots
tmux ls                 # main: 1 windows
tmux show-options -g prefix            # prefix C-a
tmux show-options -g @plugin | head   # tpm, tmux-sensible, tmux-yank, vim-tmux-navigator, ...
tmux show-environment -g TMUX_PLUGIN_MANAGER_PATH
# -> TMUX_PLUGIN_MANAGER_PATH=/home/<user>/.config/tmux/plugins/

# Kanagawa status bar corriendo (scripts de plugin ejecutándose):
tmux show-options -g status-right
# -> incluye #(/home/<u>/.config/tmux/plugins/tmux-kanagawa/scripts/git.sh) etc.

# Bindings activos:
tmux list-keys -T root | grep -E 'C-(h|j|k|l)'  # vim-tmux-navigator
tmux list-keys -T root | grep M-g                # floating scratch window
tmux list-keys -T prefix | grep -E '^\s*bind-key -T prefix [vd] '  # split v/d
```

Si todo eso responde, Gentleman.Dots está corriendo sobre Omarchy. Si algo falta, revisar:

- `~/.config/tmux/plugins/<plugin>/.git` existe para los 7.
- `~/.tmux.conf` es symlink hacia `~/.config/tmux/tmux.conf` (`readlink ~/.tmux.conf`).
- `environment.d` o el shell de login exportan `XDG_CONFIG_HOME=/home/<u>/.config`.

---

## 8. Estructura del repo

```
.config/
├── fish/                      # Gentleman.Dots + plugins fisher (versionados por conveniencia)
│   ├── config.fish
│   ├── fish_plugins           # lista de plugins fisher
│   ├── fish_variables         # estado universal (sin secretos)
│   ├── conf.d/
│   │   ├── nvm.fish
│   │   ├── rustup.fish
│   │   └── fish_frozen_*.fish
│   ├── functions/             # fisher + nvm functions
│   └── themes/                # *.theme
├── ghostty/                   # Gentlemen.Dots
│   ├── config
│   └── shaders/
│       └── cursor_smear_gentleman.glsl
├── tmux/                      # Gentleman.Dots promovido a XDG (+ pin de TPM path)
│   └── tmux.conf
├── hypr/                      # Omarchy base (no modificado por gentleman-dots)
├── mako/
├── omarchy/
├── waybar/
├── walker/
└── yadm/
```

### No incluido en este commit (intencionalmente)

> Nota: los archivos bajo `~/.config/omarchy/current/`, `hypr/`, `waybar/`, `walker/`, `mako/`, `omarchy/` ya existen en el commit inicial (`1945c23`) y **no se re-añaden ni modifican en este commit**. La lista siguiente se refiere a lo que **este commit** no reintroduce.

- `~/.config/fish/completions/` — autogenerado por carapace; muchas miles de stubs.
- `~/.config/fish/fish_history` — historial interactive del usuario.
- `~/.config/ghostty/shaders/*.glsl` (los otros ~51 shaders) — bundle del instalador; solo se comitea `cursor_smear_gentleman.glsl` (único referenciado por configuración).
- `~/.config/tmux/tmux.conf.omarchy.bak` — respaldo local del config original de Omarchy.
- `~/.tmux/plugins/` y `~/.config/tmux/plugins/` — clones de TPM (código de terceros, regenerable).
- Tema/runtime state nuevo bajo `~/.config/omarchy/current/` (los del commit inicial se conservan como referencia del estado-base de Omarchy, no se sobrescribe).

---

## 9. DR: deshacer / rollback

```bash
# Reinstalar Omarchy tmux original:
mv ~/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf.gentleman.bak
mv ~/.config/tmux/tmux.conf.omarchy.bak ~/.config/tmux/tmux.conf
unlink ~/.tmux.conf   # symlink

# Reinstalar Gentleman.Dots desde cero
gentleman-dots --non-interactive --shell=fish --terminal=ghostty --wm=tmux --nvim
```

---

## 10. Versión de referencia (codificada en este commit)

- `gentleman-dots` formula 2.12.1 (Gentleman.Installer linux-amd64)
- tmux 3.7b (Arch)
- Ghostty 1.3.1-arch2
- fish 4.3+ (`fish_vi_key_bindings` activo; `fish_frozen_*` migrados a global)
- TPM @ e261deb
- Plugins: tmux-sensible 25cb91f, tmux-yank acfd36e, vim-tmux-navigator e41c431, tmux-resurrect cff343c, tmux-which-key 85fb975, tmux-kanagawa b4e40a9

Llave XIV de comprobación: `tmux show-options -g prefix` debe responder `prefix C-a`.

---

_Última revisión: 2026-07-15._