#!/usr/bin/env bash
#
# instalar_entorno_vim_rust.sh
# Automatiza el paso a paso: Vim + git + curl, Node.js, coc-settings.json,
# vim-plug, archivos de configuración y PlugInstall.
#
# Uso:
#   ./instalar_entorno_vim_rust.sh                 # Node vía NodeSource (Vía A, requiere sudo)
#   ./instalar_entorno_vim_rust.sh --node-local    # Node binario en ~/.local/node (Vía B, sin sudo para Node)
#   ./instalar_entorno_vim_rust.sh --node-local --linea 22   # usar la línea 22.x en vez de 24.x
#   ./instalar_entorno_vim_rust.sh --vimrc <archivo-o-URL>   # usar otro .vimrc en vez del de GitHub
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Parámetros
# ---------------------------------------------------------------------------
NODE_MODO="nodesource"   # nodesource | local
NODE_LINEA="24"          # solo aplica al modo local: 24 (LTS vigente) o 22
VIMRC_ORIGEN="https://raw.githubusercontent.com/jmartinez1000/vim-recursos/refs/heads/main/.vimrc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --node-local)      NODE_MODO="local"; shift ;;
    --node-nodesource) NODE_MODO="nodesource"; shift ;;
    --linea)           NODE_LINEA="${2:?Falta el número de línea (22 o 24)}"; shift 2 ;;
    --vimrc)           VIMRC_ORIGEN="${2:?Falta la ruta o URL del vimrc}"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Opción desconocida: $1 (use --help)"; exit 1 ;;
  esac
done

# Directorio donde reside el script (para localizar los archivos de configuración)
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

paso()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m    [OK]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m    [ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1.1 Vim, git y curl
# ---------------------------------------------------------------------------
paso "1.1 Instalando vim, git y curl"
sudo apt update
sudo apt install -y vim git curl

VIM_LINEA="$(vim --version | head -1)"
echo "    $VIM_LINEA"

# Verificar versión 9.0 o superior
VIM_VER="$(echo "$VIM_LINEA" | grep -oE '[0-9]+\.[0-9]+' | head -1)"
if [[ "$(printf '%s\n' "9.0" "$VIM_VER" | sort -V | head -1)" != "9.0" ]]; then
  error "Se requiere Vim 9.0 o superior; se detectó $VIM_VER. En Ubuntu/Debian antiguos considere el PPA jonathonf/vim o compilar desde fuente."
fi
ok "Vim $VIM_VER"

# Verificar característica +terminal (usada por :Crun y :Ctest)
if vim --version | grep -qo '+terminal'; then
  ok "Característica +terminal presente"
else
  error "El Vim instalado no tiene +terminal. Instale un paquete con soporte completo (p. ej. vim-gtk3 o vim-nox)."
fi

# ---------------------------------------------------------------------------
# 1.2 Node.js 22 o superior
# ---------------------------------------------------------------------------
NODE_MINIMO="22.15.0"

node_version_valida() {
  command -v node >/dev/null 2>&1 || return 1
  local v
  v="$(node --version | sed 's/^v//')"
  [[ "$(printf '%s\n' "$NODE_MINIMO" "$v" | sort -V | head -1)" == "$NODE_MINIMO" ]]
}

if node_version_valida; then
  paso "1.2 Node.js ya presente: $(node --version) (>= v$NODE_MINIMO) — se omite la instalación"
elif [[ "$NODE_MODO" == "nodesource" ]]; then
  paso "1.2 Instalando Node.js 22 vía repositorio NodeSource (Vía A, requiere sudo)"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs
else
  paso "1.2 Instalando Node.js línea ${NODE_LINEA}.x como binario en ~/.local/node (Vía B, sin sudo)"
  # Obtener el nombre exacto del archivo para no depender de un parche escrito a mano
  ARCHIVO="$(curl -fsS "https://nodejs.org/dist/latest-v${NODE_LINEA}.x/" \
    | grep -o "node-v[0-9.]*-linux-x64.tar.xz" | head -1)"
  [[ -n "$ARCHIVO" ]] || error "No se pudo determinar el archivo en nodejs.org/dist/latest-v${NODE_LINEA}.x/"
  echo "    Archivo detectado: $ARCHIVO"
  mkdir -p ~/.local/node
  curl -fsSL "https://nodejs.org/dist/latest-v${NODE_LINEA}.x/$ARCHIVO" \
    | tar -xJ --strip-components=1 -C ~/.local/node
  # Agregar al PATH solo si aún no está en ~/.bashrc
  if ! grep -q '\.local/node/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/node/bin:$PATH"' >> ~/.bashrc
    ok 'PATH agregado a ~/.bashrc'
  fi
  export PATH="$HOME/.local/node/bin:$PATH"
fi

node_version_valida || error "node --version devolvió $(node --version 2>/dev/null || echo 'nada'); se requiere v$NODE_MINIMO o superior."
ok "Node.js $(node --version)"

# ---------------------------------------------------------------------------
# 1.3 coc-settings.json
# ---------------------------------------------------------------------------
paso "1.3 Escribiendo ~/.vim/coc-settings.json"
mkdir -p ~/.vim

# Respaldar un coc-settings.json existente antes de sobrescribirlo
if [[ -f ~/.vim/coc-settings.json ]]; then
  cp ~/.vim/coc-settings.json ~/.vim/coc-settings.json.bak."$(date +%Y%m%d%H%M%S)"
  ok "Respaldo del coc-settings.json anterior creado"
fi

# Contenido embebido en el propio script: no se necesita ningún archivo externo
cat > ~/.vim/coc-settings.json <<'EOF'
{
  "rust-analyzer.server.path": "~/.cargo/bin/rust-analyzer",
  "rust-analyzer.updates.checkOnStartup": false,
  "rust-analyzer.updates.prompt": "neverDownload",
  "rust-analyzer.checkOnSave": true,
  "rust-analyzer.inlayHints.parameterHints.enable": false,
  "suggest.noselect": false,
  "workspace.ignoredFolders": ["$HOME", "$HOME/.cargo/**", "$HOME/.rustup/**"]
}
EOF
ok "~/.vim/coc-settings.json generado desde el contenido embebido en el script"

# ---------------------------------------------------------------------------
# 1.3.1 vim-plug
# ---------------------------------------------------------------------------
paso "1.3.1 Instalando vim-plug"
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ok "vim-plug instalado en ~/.vim/autoload/plug.vim"

# ---------------------------------------------------------------------------
# 1.4 Archivos de configuración y PlugInstall
# ---------------------------------------------------------------------------
paso "1.4 Instalando ~/.vimrc"

# Respaldar un .vimrc existente antes de sobrescribirlo
if [[ -f ~/.vimrc ]]; then
  cp ~/.vimrc ~/.vimrc.bak."$(date +%Y%m%d%H%M%S)"
  ok "Respaldo del .vimrc anterior creado (~/.vimrc.bak.*)"
fi

if [[ "$VIMRC_ORIGEN" == http*://* ]]; then
  # Descargar el .vimrc desde la URL (por defecto, el repositorio vim-recursos de GitHub)
  echo "    Descargando: $VIMRC_ORIGEN"
  curl -fsSL "$VIMRC_ORIGEN" -o ~/.vimrc \
    || error "No se pudo descargar el .vimrc desde $VIMRC_ORIGEN"
  [[ -s ~/.vimrc ]] || error "El .vimrc descargado está vacío."
elif [[ -f "$DIR_SCRIPT/$VIMRC_ORIGEN" ]]; then
  cp "$DIR_SCRIPT/$VIMRC_ORIGEN" ~/.vimrc
elif [[ -f "$VIMRC_ORIGEN" ]]; then
  cp "$VIMRC_ORIGEN" ~/.vimrc
else
  error "No se encontró $VIMRC_ORIGEN. Indique un archivo o URL válidos con --vimrc."
fi
ok "~/.vimrc instalado"

paso "Ejecutando vim +PlugInstall +qall (instala los complementos y cierra)"
vim +PlugInstall +qall
ok "Complementos instalados"

# ---------------------------------------------------------------------------
# Resumen
# ---------------------------------------------------------------------------
paso "Instalación completada"
echo "    Vim:     $VIM_VER (+terminal)"
echo "    Node.js: $(node --version)"
echo "    Config:  ~/.vimrc, ~/.vim/coc-settings.json, ~/.vim/autoload/plug.vim"
echo
echo "    Nota: la primera vez que abra un archivo .rs, coc.nvim instalará"
echo "    la extensión coc-rust-analyzer declarada en g:coc_global_extensions."
if [[ "$NODE_MODO" == "local" ]]; then
  echo "    Recuerde abrir una nueva terminal o ejecutar: . ~/.bashrc"
fi
