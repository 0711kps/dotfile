(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

(setq make-backup-files nil)
(setq auto-save-default nil)
(global-display-line-numbers-mode t)
(setq scroll-step 1
      scroll-conservatively 10000)
(setq inhibit-startup-screen t)
(setq scroll-margin 3)


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
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be carefual.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package corfu
  :ensure t
  :custom
  (corfu-count 3)
  (corfu-auto t)                 ;; 自動跳出補全視窗
  (corfu-auto-delay 0.0)         ;; 0 秒延遲，反應最快
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
              '(cape-dabbrev cape-keyword cape-file))

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

(use-package ace-window
  :ensure t)

(use-package multiple-cursors
  :ensure t)
