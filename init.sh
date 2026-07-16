askForProcessing(){
  local processingTarget="$1"
  printf "Do you want to $processingTarget ?(y/N/q): -> "
  read ans < /dev/tty
  # downcase the answer, btw, ${ans^^} for upcase
  ans=${ans,,}
  # if the anser is q, quit program immediately
  [[ $ans == "q" ]] && exit
  # return 0 if ans is yes, return 1 if ans is no
  [[ $ans == "y" ]]
}

installSystemPackages(){
    if [[ $(command -v apt) ]]
    then
	installAPTpackages
    elif [[ $(command -v dnf) ]]
    then
	 installDnfPackages
    fi
}

installDnfPackages(){
    askForProcessing "install dnf packages" || return
    printf "now installing DNF packages..\r"
    inputMethod="fcitx5 fcitx5-chewing fcitx5-anthy fcitx5-pinyin"
    commonBuildDependencies="make automake gcc gcc-c++ kernel-devel git curl wget cmake"
    utilities="fzf fd-find ripgrep bat xclip neovim httpie emacs-nox"
    container="podman podman-compose qemu-system-x86"
    desktopApps="mpv alacritty obs-studio musescore ardour9 audacity"

    sudo dnf install -yq ${inputMethod} ${commonBuildDependencies} ${utilities} ${container} ${desktopApps}
}

installAPTpackages(){
  askForProcessing "install apt packages" || return
  printf "now installing APT packages...\r"
  inputMethod="im-config fcitx5 fcitx5-chewing fcitx5-anthy fcitx5-pinyin"
  commonBuildDependencies="build-essential git curl wget cmake"
  utilities="fzf fd-find ripgrep bat xclip neovim httpie emacs-nox"
  container="podman podman-compose qemu-system-x86"
  desktopApps="mpv alacritty obs-studio musescore ardour audacity"

  rubyDependencies="zlib1g-dev libreadline-dev libffi-dev libyaml-dev"
  sudo apt-get install -yqq ${inputMethod} ${commonBuildDependencies} ${utilities} ${rubyDependencies} ${container} ${desktopApps}
}

downloadFonts(){
  askForProcessing "download fonts" || return
  mkdir -p ~/.local/share/fonts

  # nerd fonts
  local fontNames=(CascadiaCode FiraCode D2Coding Hasklig Lilex)
  for fontName in $fontNames
  do
    curl -sfLo ${fontName}.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/${fontName}.zip
    unzip -jo ${fontName}.zip '*.ttf' -d ~/.local/share/fonts && rm -f ${fontName}.zip
  done

  # jetbrain mono
  curl -sfLo JetBrainsMono.zip https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip
  unzip -jo JetBrainsMono.zip  '*.ttf' -d ~/.local/share/fonts/ && rm -f JetBrainsMono.zip

  # victor
  curl -sfLo VictorMono.zip https://rubjo.github.io/victor-mono/VictorMonoAll.zip
  unzip -jo VictorMono.zip '*.ttf' -d ~/.local/share/fonts/ && rm -f VictorMono.zip

  fc-cache -fv
}

configureInputMethod(){
  askForProcessing "configure input method" || return
  echo "please select Update input method config, and activate fcitx5 framework"
  im-config
  echo "please open up fcitx5 configuration window, and activate the input methods you need"
  fcitx5-configtool
}

installStarship(){
  askForProcessing "configure starship" || return
  curl -sS https://starship.rs/install.sh | sh
}

installASDF(){
  askForProcessing "install asdf version manager" || return
  wget "https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz" -O asdf.tar.gz
  tar xf asdf.tar.gz
  sudo mv asdf /usr/local/bin/
  rm -f asdf.tar.gz
  mkdir -p ~/.asdf
  local plugins=(ruby rust golang nodejs gleam)
  for plugin in $plugins
  do
    asdf plugin add ${plugin}
  done
}

configureAlacritty(){
    askForProcessing "configure alacritty" || return
    mkdir -p ~/.config/alacritty
    cat <<'EOF' > ~/.config/alacritty/alacritty.toml
[general]
live_config_reload = true

[window]
opacity = 0.82
padding = { x = 8, y = 3 }
dimensions = { columns = 110, lines = 36 }

[font]
#normal = { family = "CaskaydiaCove Nerd Font", style = "Regular" }
#bold = { family = "CaskaydiaCove Nerd Font", style = "Bold" }
normal = { family = "JetBrains Mono", style = "Regular" }
bold = { family = "JetBrains Mono", style = "Bold" }
size = 15.5

[cursor.style]
shape = "Beam"
blinking = "Always"

[colors.primary]
background = "#1a1b26"
foreground = "#a9b1d6"
EOF
}

configureBash(){
  askForProcessing "configure bash" || return
  _configureBashAlias
  _configureBashEnv
  _configureBashPath
  _installZoxide

  cat << 'BashRC' > ~/.bashrc_custom
source ~/.bashrc_custom_alias
source ~/.bashrc_custom_env
source ~/.bashrc_custom_path
eval "$(fzf --bash)"
eval "$(starship init bash)"
eval "$(zoxide init bash)"
BashRC

if [[ $(cat ~/.bashrc | grep 'bashrc_custom' | wc -l) -eq 0 ]]
then
  echo "source ~/.bashrc_custom" >> ~/.bashrc
fi
}

_configureBashAlias(){
  cat << 'BashAlias' > ~/.bashrc_custom_alias
# git
alias gst="git status"
alias glg="git log"
alias glgo='git log --oneline'
alias gb="git branch"
alias gbm="gb -m"
alias grb="git rebase"
alias grbi="grb -i"
alias grs="git reset"
alias ga="git add"
alias gap="ga -p"
alias gau="ga -u"
alias gpl="git pull"
alias gp="git push"
alias gf="git fetch"
alias gck="git checkout"
alias gc="git commit"
alias gcm="gc -m"
alias gd="git diff"
alias grmt="git remote"
alias gsh="git stash"

# navi
alias b="cd .."
alias bb="cd ../.."
alias c="clear"

# ruby bundler
alias bd="bundle"
alias bda="bd add"
alias bde="bd exec"
alias bdi="bd install"
alias bdr="bd remove"
alias bdu="bd update"

# others
alias vim="nvim"
alias v="vim"
alias fd="fdfind"
alias t="batcat"
alias e="emacs"

# podman
alias docker="podman"
alias dk="docker"
alias dev="distrobox enter dev"

cb(){
  if [[ -z $1 ]]
  then
    xclip -sel clip
    return 0
  fi

  if [[ -f $1 ]] && [[ $(du $1 | awk '{print $1}') -lt 2000 ]]
  then
    xclip -sel clip < $1
  else printf $1 | xclip -sel clip
  fi
}

getwh(){
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1 "$1"
}

mp(){
  getwh "$1"
  mpv --autofit=100%x480 "$1" > /dev/null
}

detect_processor_encoder(){
  local cache_path=$HOME/.cache/processor_encoder_name
  if [[ -f $cache_path ]]
  then
    cat $cache_path
  else
    if ffmpeg -f lavfi -i nullsrc -c:v h264_nvenc -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=cuda
    elif ffmpeg -f lavfi -i nullsrc -c:v h264_qsv -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=qsv
    elif ffmpeg -f lavfi -i nullsrc -c:v h264_amf -frames:v 1 -f null - 2>/dev/null
    then
      encoder_name=amf
    else
      encoder_name=none
    fi
    printf $encoder_name > $cache_path
    printf $encoder_name
  fi
}

scale_p(){
  local scale_param_name
  case $(detect_processor_encoder) in
  cuda)
    printf scale_cuda
    ;;
  qsv)
    printf scale_qsv
    ;;
  amf)
    printf scale_amf
    ;;
  none)
    printf scale
    ;;
  esac
}

xv(){
  local input="$1"
  local _vwh=$(getwh "$input")
  local vwidth=$(echo $_vwh | rg -Po '(?<=width=)\d+')
  local vheight=$(echo $_vwh | rg -Po '(?<=height=)\d+')
  local is_landscape=$(($vwidth / $vheight))
  local output=$(echo "$input" | sed 's/[ ()]//g')
  output=${output%.*}.mp4
  local full_output_path="$HOME/Videos/xxx/$output"
  scale_option=$(scale_p)
  local vf
  if [[ -z "$2" ]]
  then
    if [[ $is_landscape == 1 ]]
    then
      [[ $vheight -gt 880 ]] && vf="-vf ${scale_option}=-1:880"
    elif [[ $is_landscape == 0 ]]
    then
      [[ $vwidth -gt 880 ]] && vf="-vf ${scale_option}=880:-1"
    fi
  else
    if [[ "$2" == w* ]]
    then
      vf="${2##*w}"
      vf="-vf ${scale_option}=$vf:-1"
    elif [[ "$2" == h* ]]
    then
      vf="${2##*h}"
      vf="-vf ${scale_option}=-1:$vf"
    else
      echo "incorrect, scale number, either w\d+ or h\d+ should be given!"
      return 1
    fi
  fi
  local extra_options=$(echo "${@:2}" | sed 's/scale=/scale_qsv=/')
  local command="ffmpeg -hide_banner -loglevel error -hwaccel qsv -hwaccel_output_format qsv -i '$input' -c:v hevc_qsv -c:a libopus -af loudnorm=I=-16:TP=-1.5:LRA=11,volume=-2dB  -preset medium -b:v 5M -progress pipe:1 $vf '$full_output_path' | rg -o -P '(?<=time=)\d{2}:\d{2}:\d{2}\.\d{2}'"
  echo "$command"
  eval "$command" &&
    echo "'$input' -> '$output' COMPLETE!"
}

hashrename(){
  local input=$(basename "$1")
  local ext=${input##*.}
  local base=${input%.*}
  local hash_part=$(md5sum "$input"  | awk '{print $1}' | rg '^.{8}' -o)
  local orig_part=$(echo $base | sed 's/[ ()]//g' | rg -o '^.{1,8}')
  local new_name="${hash_part}${orig_part}.${ext}"
  mv "$input" "${new_name}" &&
  echo "$input --> $new_name"
}
BashAlias
}

_configureBashEnv(){
  cat << 'BashEnv' > ~/.bashrc_custom_env
export ASDF_DIR=~/.asdf
# Avoid duplicates
HISTCONTROL=ignoredups:erasedups
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend

# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
$(command -v gsettings > /dev/null)  && gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'
$(command -v gsettings > /dev/null) && gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
BashEnv
}

_configureBashPath(){
  cat << 'BashPath' > ~/.bashrc_custom_path
export PATH=$ASDF_DIR/shims:$PATH
export PATH=$HOME/.local/bin:$PATH
BashPath
}

_installZoxide(){
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

configureSSHkey(){
  askForProcessing "configure ssh key" || return
  ssh-keygen -b 4096 -t ed25519 -f ~/.ssh/personal -q -N ""
  cat << 'SSHConfig' >> ~/.ssh/config
Host mygithub
  Hostname github.com
  User git
  IdentityFile ~/.ssh/personal
SSHConfig
}

configureGit(){
  askForProcessing "configure git" || return

  command -v git > /dev/null
  if ! [[ $? == 0 ]]
  then
    echo "git not installed !"
    return 1
  fi
  git config --global user.name "Pero.Xie"
  git config --global user.email "perox@duck.com"
  git config --global rebase.abbreviateCommands true
  git config --global core.editor nvim
  git config --global init.defaultBranch tua-bue
  git config --global rebase.abbreviateCommands true
}

configurePodman(){
  askForProcessing "configure podman" || return
  sudo wget https://github.com/containers/gvisor-tap-vsock/releases/download/v0.8.7/gvproxy-linux-amd64 -O /usr/libexec/podman/gvproxy && sudo chmod +x /usr/libexec/podman/gvproxy
  curl -fsLo virtiofsd.zip https://gitlab.com/-/project/21523468/uploads/0298165d4cd2c73ca444a8c0f6a9ecc7/virtiofsd-v1.13.2.zip
  sudo unzip -jo virtiofsd.zip  -d /usr/local/libexec/podman && rm -f virtiofsd.zip
  podman machine init
#  podman machine start
}

configureNeovim(){
  askForProcessing "configure neovim" || return

  mkdir -p ~/.config/nvim
  cat << 'EOF' > ~/.config/nvim/init.lua
-- init.lua
--------------------------------------------------
-- 基礎外觀
--------------------------------------------------
vim.opt.tabstop	      = 2
vim.opt.shiftwidth    = 2
vim.opt.expandtab     = true
vim.opt.filetype      = 'on'        -- 其實 nvim 預設就開，留著相容
vim.opt.syntax        = 'on'        -- 等同 syntax on
vim.opt.cursorline    = true        -- set cursorline
vim.opt.number        = true        -- set number
vim.opt.mouse         = ''          -- 關閉 mouse（等同 set mouse=）
-- 高亮游標所在行
vim.opt.cursorline = true

-- 高亮游標所在列（垂直）
vim.opt.cursorcolumn = true

--------------------------------------------------
-- 相對載入
--------------------------------------------------
local function source_lua_relatively(name)
  -- 載入 ~/.config/nvim/<name>.vim
  local path = vim.fn.stdpath('config') .. '/' .. name .. '.lua'
  vim.cmd('source ' .. path)
end

-- 快捷鍵設定

-- 上下左右、翻頁、首尾
local keymap = vim.keymap.set

-- <C-p> = 上箭頭
keymap({'n', 'i', 'v'}, '<C-p>', '<Up>')

-- <C-v> = PageDown
keymap({'n', 'i', 'v'}, '<C-v>', '<PageDown>')

-- <A-v> = PageUp（注意：Alt 組合在終端可能需額外設定）
keymap({'n', 'i', 'v'}, '<A-v>', '<PageUp>')

-- <C-n> = 下箭頭
keymap({'n', 'i', 'v'}, '<C-n>', '<Down>')

-- <C-b> = 左箭頭
keymap({'n', 'i', 'v'}, '<C-b>', '<Left>')

-- <C-f> = 右箭頭
keymap({'n', 'i', 'v'}, '<C-f>', '<Right>')

-- <C-a> = Home
keymap({'n', 'i', 'v'}, '<C-a>', '<Home>')

-- <C-e> = End
keymap({'n', 'i', 'v'}, '<C-e>', '<End>')

-- Insert 模式下 <C-d> = Delete
keymap('i', '<C-d>', '<Delete>')

-- Multi edit: <C-x><C-n> = cgn（normal 模式）
keymap('n', '<C-x><C-n>', 'cgn')

-- ESC（退出 insert/visual/normal 模式）
keymap({'n', 'i', 'v'}, '<C-\\>', '<Esc>')
keymap({'n', 'i', 'v'}, '<C-g>', '<Esc>')

-- 模仿 emacs 的 <C-k>：刪除游標後到行尾的內容
vim.keymap.set('i', '<C-k>', '<C-o>D', { silent = true })

-- 禁用 <C-o> 的跳轉功能（設為 Nop）
keymap({'n', 'i', 'v'}, '<C-o>', '<Nop>')
EOF
}

configureEmacs(){
    askForProcessing "configure emacs" || return
    cat << 'EOF' > ~/.emacs
(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "http://stable.melpa.org/packages/") t)
(package-initialize)

(defvar package-list-stamp-file
  (expand-file-name ".package-refresh-stamp" user-emacs-directory))

(defun ensure-fresh-package-list (&optional hours)
  "Refresh package list if stamp older than HOURS (default 6)."
  (let* ((max-age (or hours 60))
         (elapsed (if (file-exists-p package-list-stamp-file)
                      (- (float-time)
                         (float-time (nth 5 (file-attributes package-list-stamp-file))))
                    most-positive-fixnum)))  ;; 不存在 = 強制 refresh
    (when (> elapsed (* max-age 3600))
      (package-refresh-contents)
      (write-region "" nil package-list-stamp-file)
      (message "Package list refreshed."))))

(add-hook 'after-init-hook (lambda () (ensure-fresh-package-list 77)))

(setq make-backup-files nil)
(setq auto-save-default nil)
(global-display-line-numbers-mode t)
(setq scroll-step 1
      scroll-conservatively 10000)
(setq inhibit-startup-screen t)
(setq scroll-margin 3)


(setq js-indent-level 2)
(setq typescript-indent-level 2)
(setq sh-basic-offset 2)

(add-to-list 'auto-mode-alist '("\\\\.tsx\\\\'" . typescript-mode))

(use-package aider
  :ensure t
  :config
  ;; For latest claude sonnet model
  (setq aider-args '("--model" "4o" "--no-auto-accept-architect")) ;; add --no-auto-commits if you don't want it
  (setenv "OPENAI_API_KEY" "sk-no-key-needed")
  (setenv "OPENAI_API_URL" "http://localhost:8080/v1")
  ;; Or chatgpt model
  ;; (setq aider-args '("--model" "o4-mini"))
  ;; (setenv "OPENAI_API_KEY" <your-openai-api-key>)
  ;; Or use your personal config file
  ;; (setq aider-args ("--config" ,(expand-file-name "~/.aider.conf.yml")))
  ;; ;;
  ;; Optional: Set a key binding for the transient menu
  (global-set-key (kbd "C-c a") 'aider-transient-menu) ;; for wider screen
  ;; or use aider-transient-menu-2cols / aider-transient-menu-1col, for narrow screen
  (aider-magit-setup-transients) ;; add aider magit function to magit menu
  ;; auto revert buffer
  (global-auto-revert-mode 1)
  (auto-revert-mode 1))

(use-package minuet
    :ensure t
    :bind
    (("M-y" . #'minuet-complete-with-minibuffer)
    :map minuet-active-mode-map)
    :config
    (setq minuet-provider 'openai-fim-compatible)
    (setq minuet-max-tokens 50)
    (setq minuet-n-completions 1)
    (setq minuet-context-window 256)
    (plist-put minuet-openai-fim-compatible-options :end-point "http://localhost:8080/v1/completions")
    (plist-put minuet-openai-fim-compatible-options :name "Llama.cpp")
    (plist-put minuet-openai-fim-compatible-options :api-key "TERM")
    (plist-put minuet-openai-fim-compatible-options :model "any")
    (minuet-set-nested-plist minuet-openai-fim-compatible-options nil :template :suffix)
    (minuet-set-optional-options
     minuet-openai-fim-compatible-options
     :prompt
     (defun minuet-llama-cpp-fim-qwen-prompt-function (ctx)
         (format "<|fim_prefix|>%s\n%s<|fim_suffix|>%s<|fim_middle|>"
                 (plist-get ctx :language-and-tab)
                 (plist-get ctx :before-cursor)
                 (plist-get ctx :after-cursor))
     :template)

    (minuet-set-optional-options minuet-openai-fim-compatible-options :max_tokens 256)))


;; Enable vertico
(use-package vertico
  :ensure t
  :init
  (vertico-mode))

; Enable rich annotations using the Marginalia package
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

;; Configure orderless for flexible completion styles
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Persist history over Emacs restarts
(use-package savehist
  :init
  (savehist-mode))

;; Optionally enable cycling for vertico-next/previous
(setq vertico-cycle t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(ace-window cape consult corfu-terminal emmet-mode marginalia
		multiple-cursors orderless typescript-mode vertico
		web-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package corfu
  :ensure t
  :custom
  (corfu-count 3)
  (corfu-auto t)                 ;; 自動跳出補全視窗
  (corfu-auto-delay 0.6)         ;; 0 秒延遲，反應最快
  (corfu-auto-prefix 1)          ;; 輸入 1 個字就開始提示
  (corfu-cycle t)                ;; 可以循環選單
  :init
  (global-corfu-mode))           ;; 全域開啟

(use-package corfu-terminal
  :ensure t
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(use-package cape
  :ensure t)

(use-package eglot
  :ensure nil)

;; 2. 設定 A 鍵 (手動 LSP)
(global-set-key (kbd "M-/") #'completion-at-point)

(setq-default completion-at-point-functions 
              '(cape-dabbrev cape-file cape-keyword))

(defun my/toggle-eglot ()
  "如果 eglot 沒開啟就執行 eglot，否則執行 eglot-shutdown。"
  (interactive)
  (if (bound-and-true-p eglot--managed-mode)
      (eglot-shutdown (eglot-current-server))
    (call-interactively 'eglot)))

;; keybind for toggle eglot
(require 'bind-key)
(bind-key* "C-c e" #'my/toggle-eglot)
(bind-key* "C-c C-e" #'my/toggle-eglot)
(bind-key* "C-c g" 'goto-line)
(bind-key* "C-c C-g" 'goto-line)
(bind-key* "C-c j" 'avy-goto-char-timer)
(bind-key* "C-c C-j" 'avy-goto-char-timer)
(bind-key* "C-c r" 'consult-ripgrep)
(bind-key* "C-c C-r" 'consult-ripgrep)
(bind-key* "C-c ;" 'comment-line)
(bind-key* "C-c ," 'emmet-expand-line)
(bind-key* "C-c C-v" 'set-mark-command)
(bind-key* "C-h" 'delete-backward-char)

(use-package emmet-mode
  :ensure t)
(use-package typescript-mode
  :ensure t)

(defun my/split-right ()
  "separate and move to right"
  (interactive)
  (split-window-right)
  (windmove-right))

(defun my/split-left ()
  "separate and move to left"
  (interactive)
  (split-window-right))

(defun my/split-up ()
  "separate and move to up"
  (interactive)
  (split-window-below))

(defun my/split-down ()
  "separate and move to down"
  (interactive)
  (split-window-below)
  (windmove-down))

(bind-key* "C-c C-w C-d" #'my/split-right)
(bind-key* "C-c C-w C-a" #'my/split-left)
(bind-key* "C-c C-w C-s" #'my/split-down)
(bind-key* "C-c C-w C-w" #'my/split-up)
(bind-key* "C-c C-w C-b" 'ace-window)
(bind-key* "C-c RET ." 'mc/mark-next-like-this)
(bind-key* "C-c RET RET" 'mc/skip-to-next-like-this)
(bind-key* "C-c C-k" 'point-to-register)
(bind-key* "C-C C-l" 'jump-to-register)
(bind-key* "C-c C-f" 'consult-fd)
;; ACE JUMP!
(use-package avy
  :ensure t
  :config
  (setq avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  )

(use-package consult
  :ensure t)

(use-package ace-window
  :ensure t)

(use-package multiple-cursors
  :ensure t)
EOF
}

_configureNvimInit(){
  cat << 'NvimInit' > ~/.config/nvim/init.lua
-- init.lua
--------------------------------------------------
-- 基礎外觀
--------------------------------------------------
vim.opt.tabstop	      = 2
vim.opt.shiftwidth    = 2
vim.opt.expandtab     = true
vim.opt.filetype      = 'on'        -- 其實 nvim 預設就開，留著相容
vim.opt.syntax        = 'on'        -- 等同 syntax on
vim.opt.cursorline    = true        -- set cursorline
vim.opt.number        = true        -- set number
vim.opt.mouse         = ''          -- 關閉 mouse（等同 set mouse=）
-- 高亮游標所在行
vim.opt.cursorline = true

-- 高亮游標所在列（垂直）
vim.opt.cursorcolumn = true

--------------------------------------------------
-- 高亮行尾空白
--------------------------------------------------
vim.api.nvim_set_hl(0, 'ExtraWhitespace', { ctermbg = 'red', bg = 'red' })
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'InsertLeave' }, {
  pattern = '*',
  command = 'match ExtraWhitespace /\\\s+$/',
})

--------------------------------------------------
-- 相對載入
--------------------------------------------------
local function source_vim_relatively(name)
  -- 載入 ~/.config/nvim/<name>.vim
  local path = vim.fn.stdpath('config') .. '/' .. name .. '.vim'
  vim.cmd('source ' .. path)
end

local function source_lua_relatively(name)
  -- 載入 ~/.config/nvim/<name>.vim
  local path = vim.fn.stdpath('config') .. '/' .. name .. '.lua'
  vim.cmd('source ' .. path)
end

--------------------------------------------------
-- 依序載入分割檔（.lua 副檔名）
--------------------------------------------------
source_lua_relatively('window')
source_vim_relatively('plugins')
source_lua_relatively('keybind')
source_lua_relatively('plugins-config/fzf')
source_lua_relatively('plugins-config/easymotion')
source_lua_relatively('plugins-config/commentary')
source_lua_relatively('plugins-config/lsp')
source_lua_relatively('plugins-config/cmp')
NvimInit
}

_configureNvimKeybind(){
  mkdir -p ~/.config/nvim
  cat << 'NvimKeybind' > ~/.config/nvim/keybind.lua
-- 快捷鍵設定

-- 上下左右、翻頁、首尾
local keymap = vim.keymap.set

-- <C-p> = 上箭頭
keymap({'n', 'i', 'v'}, '<C-p>', '<Up>')

-- <C-v> = PageDown
keymap({'n', 'i', 'v'}, '<C-v>', '<PageDown>')

-- <A-v> = PageUp（注意：Alt 組合在終端可能需額外設定）
keymap({'n', 'i', 'v'}, '<A-v>', '<PageUp>')

-- <C-n> = 下箭頭
keymap({'n', 'i', 'v'}, '<C-n>', '<Down>')

-- <C-b> = 左箭頭
keymap({'n', 'i', 'v'}, '<C-b>', '<Left>')

-- <C-f> = 右箭頭
keymap({'n', 'i', 'v'}, '<C-f>', '<Right>')

-- <C-a> = Home
keymap({'n', 'i', 'v'}, '<C-a>', '<Home>')

-- <C-e> = End
keymap({'n', 'i', 'v'}, '<C-e>', '<End>')

-- Insert 模式下 <C-d> = Delete
keymap('i', '<C-d>', '<Delete>')

-- Multi edit: <C-x><C-n> = cgn（normal 模式）
keymap('n', '<C-x><C-n>', 'cgn')

-- ESC（退出 insert/visual/normal 模式）
keymap({'n', 'i', 'v'}, '<C-\\\>', '<Esc>')
keymap({'n', 'i', 'v'}, '<C-g>', '<Esc>')

-- 模仿 emacs 的 <C-k>：刪除游標後到行尾的內容
vim.keymap.set('i', '<C-k>', '<C-o>D', { silent = true })

-- 禁用 <C-o> 的跳轉功能（設為 Nop）
keymap({'n', 'i', 'v'}, '<C-o>', '<Nop>')
NvimKeybind
}

_configureNvimWindow(){
  mkdir -p ~/.config/nvim
  cat << 'NvimWindow' > ~/.config/nvim/window.lua
-- 視窗導航
-- -- 註解
vim.keymap.set('n', '<C-c><C-w><Right>', ':vsplit<CR>', { silent = true  })
vim.keymap.set('n', '<C-c><C-w><Down>', ':split<CR>', { silent = true  })
vim.keymap.set('n', '<C-w><up>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-w><right>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-w><down>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-w><left>', '<C-w>h', { silent = true })
NvimWindow
}

_configureNvimPlugins(){
  mkdir -p ~/.config/nvim
  cat << 'NvimPlugins' > ~/.config/nvim/plugins.vim
call plug#begin()

nm <C-c>' <Plug>(emmet-expand-abbr)
im <C-c>' <Plug>(emmet-expand-abbr)

" List your plugins here
Plug 'easymotion/vim-easymotion'
Plug 'mattn/emmet-vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'folke/tokyonight.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'cohama/lexima.vim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
call plug#end()
NvimPlugins
}

_configureNvimPluginsConfig(){
  # __configureNvimLsp
  __configureNvimCmp
  __configureNvimCommentary
  __configureNvimEasymotion
  __configureNvimFzf
}

__configureNvimLsp(){
  cat << 'NvimLsp' > ~/.config/nvim/plugins-config/lsp.lua
-- Python
vim.lsp.enable('pyright')
-- Ruby
vim.lsp.enable('ruby_lsp')
-- JS, TS
vim.lsp.enable('ts_ls')
-- Rust
vim.lsp.enable('rust_analyzer')
-- Gleam
vim.lsp.enable('gleam')

vim.lsp.enable('clangd')
vim.diagnostic.config({
  virtual_text = true
})
NvimLsp
}

__configureNvimCmp(){
  cat << 'NvimCmp' > ~/.config/nvim/plugins-config/cmp.lua
-- Set up nvim-cmp.
local cmp = require'cmp'
cmp.setup({
completion = {
  autocomplete = false
},
window = {
  -- completion = cmp.config.window.bordered(),
  -- documentation = cmp.config.window.bordered(),
},
mapping = cmp.mapping.preset.insert({
  ['<C-o>'] = cmp.mapping.complete(),
  ['<C-n>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    else
      fallback()
    end
  end, { 'i', 'c' }),
  ['<C-p>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    else
      fallback()
    end
  end, { 'i', 'c' }),
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set "select" to "false" to only confirm explicitly selected items.
}),
sources = cmp.config.sources({
  { name = 'nvim_lsp' },
}, {
  { name = 'buffer' },
  { name = 'path' }
})
})

-- Use buffer source for "/" and "?" (if you enabled "native_menu", this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
mapping = cmp.mapping.preset.cmdline(),
sources = {
  { name = 'buffer' }
}
})

-- Use cmdline & path source for ':' (if you enabled "native_menu", this won't work anymore).
cmp.setup.cmdline(':', {
mapping = cmp.mapping.preset.cmdline(),
sources = cmp.config.sources({
  { name = 'path' }
}, {
  { name = 'cmdline' }
}),
matching = { disallow_symbol_nonprefix_matching = false }
})
NvimCmp
}

__configureNvimCommentary(){
  mkdir -p ~/.config/nvim/plugins-config
  cat << 'NvimCommentary' > ~/.config/nvim/plugins-config/commentary.lua
-- 註解
vim.keymap.set('n', '<C-c>;', ':Commentary<CR>', { silent = true })
vim.keymap.set('v', '<C-c>;', ':Commentary<CR>', { silent = true })
NvimCommentary
}

__configureNvimEasymotion(){
  mkdir -p ~/.config/nvim/plugins-config
  cat << 'NvimEasymotion' > ~/.config/nvim/plugins-config/easymotion.lua
-- 快速移動 cursor（EasyMotion）
vim.keymap.set('n', '<C-j>', '<Plug>(easymotion-s)', { silent = true })
vim.keymap.set('v', '<C-j>', '<Plug>(easymotion-s)', { silent = true })
vim.keymap.set('i', '<C-j>', '<ESC><Plug>(easymotion-s)', { silent = true })
NvimEasymotion
}

__configureNvimFzf(){
  mkdir -p ~/.config/nvim/plugins-config
  cat << 'NvimFzf' > ~/.config/nvim/plugins-config/fzf.lua
-- FZF 功能（使用 <Cmd> 避免模式切換）
vim.keymap.set('n', '<C-c><C-f>', '<Cmd>Files<CR>')
vim.keymap.set('n', '<C-c><C-b>', '<Cmd>Buffers<CR>')
vim.keymap.set('n', '<C-c><C-r>', '<Cmd>Rg<CR>')
vim.keymap.set('n', '<C-c>/', '<Cmd>BLines<CR>')
NvimFzf
}

postActionHint(){
    if [[ $DESKTOP_SESSION == xfce ]]
    then
	cat <<'EOF'
1. change resolution to fit your monitor size and distance
2. change the keyboard shortcut
  a. alacritty to Ctl-Alt-t
  b. xfce4-appfinder to Alt-Esc
  c. xfce4-appfinder --collapsed to Ctl-Esc
3. change touchpad behavior
  a. go to Mouse and Touchpad
    -> select touchpad from device dropdown
    -> uncheck "Adaptive pointer acceleration"
    -> check "Reverse scroll direction"
    -> go to Touchpad tab
    -> check "Tap touchpad to click"
EOF
    fi
    cat <<'EOF'
1. register your ssh key to github
  -> cat ~/.ssh/personal.pub | xclip -sel clip
  -> go to github
  -> click your avatar
  -> Settings
  -> SSH and GPG keys
  -> New SSH key
  -> give a title name, paste public key to the "Key" field
  -> Add SSH Key
  -> and make sure to use mygithub:xxx instead of git@github.com:xxx
EOF
}

installSystemPackages
downloadFonts
configureInputMethod
installStarship
installASDF
configureAlacritty
configureBash
configureSSHkey
configureGit
configurePodman
configureNeovim
configureEmacs
postActionHint
