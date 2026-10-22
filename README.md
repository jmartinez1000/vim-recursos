## 1. Instalación paso a paso de la configuración

### 1.1 Vim, git y curl

```bash
sudo apt install -y vim git curl
vim --version | head -1
vim --version | grep -o '+terminal'
```

La primera línea debe mostrar 9.0 o superior; la segunda confirma la característica `+terminal`, que usan `:Crun` y `:Ctest`.

### 1.2 Node.js 22 o superior

Vía A, repositorio de NodeSource, requiere `sudo` y deja Node instalado para todo el sistema; el guion `setup_22.x` está documentado en [downloads.nodesource.com](https://downloads.nodesource.com/):

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version
```

Vía B, binario oficial en el directorio personal, sin `sudo`; útil en laboratorios con cuentas restringidas. La línea LTS vigente es la 24.x según la [página de versiones de Node.js](https://nodejs.org/en/about/previous-releases), y el directorio `latest-v24.x` de `nodejs.org/dist` siempre apunta a su último parche (al momento de redactar, `node-v24.21.0-linux-x64.tar.xz`):

```bash
ARCHIVO=$(curl -s https://nodejs.org/dist/latest-v24.x/ | grep -o 'node-v[0-9.]*-linux-x64.tar.xz' | head -1)
mkdir -p ~/.local/node
curl -fsSL "https://nodejs.org/dist/latest-v24.x/$ARCHIVO" \
  | tar -xJ --strip-components=1 -C ~/.local/node
echo 'export PATH="$HOME/.local/node/bin:$PATH"' >> ~/.bashrc
. ~/.bashrc
node --version
```

La primera línea obtiene el nombre exacto del archivo para no depender de un número de parche escrito a mano; lo que importa es que `node --version` devuelva 22.15.0 o superior. La misma orden con `latest-v22.x` sirve si se prefiere la línea 22, que también sigue en mantenimiento.

### 1.3 coc-setting
El archivo de configuración de coc que acompaña al `.vimrc` es `~/.vim/coc-settings.json`:

```json
{
  "rust-analyzer.server.path": "~/.cargo/bin/rust-analyzer",
  "rust-analyzer.updates.checkOnStartup": false,
  "rust-analyzer.updates.prompt": "neverDownload",
  "rust-analyzer.checkOnSave": true,
  "rust-analyzer.inlayHints.parameterHints.enable": false,
  "suggest.noselect": false,
  "workspace.ignoredFolders": ["$HOME", "$HOME/.cargo/**", "$HOME/.rustup/**"]
}
```

### 1.3.1 vim-plug

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### 1.4 Los archivos de configuración

```bash
cp vimrc_rust_corregido.vim ~/.vimrc
mkdir -p ~/.vim
cp coc-settings.json ~/.vim/coc-settings.json
vim +PlugInstall +qall
```

La última orden abre Vim, instala los cuatro complementos y cierra. La primera vez que se abra un archivo `.rs`, coc.nvim instalará la extensión `coc-rust-analyzer` (declarada en `g:coc_global_extensions`); 
