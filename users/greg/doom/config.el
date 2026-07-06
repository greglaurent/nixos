;;; package --- Summary: config.el
;;;
;;; Commentary:
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; Pin fonts explicitly. Without this, Emacs scans the entire (14k+) installed
;; font set on the first frame -- that was most of the slow first launch.
;; Families verified present via fc-list.
(setq doom-font (font-spec :family "Fira Code" :size 14)
      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 14))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;;; Code:

;; typst -- do NOT install the tree-sitter grammar at startup. The old code ran
;; `treesit-install-language-grammar` on every launch, which git-clones and
;; C-compiles the grammar whenever this Emacs doesn't already see it -> minutes
;; of startup. If typst highlighting is needed, provide the grammar via Nix
;; (tree-sitter-grammars.tree-sitter-typst) on treesit-extra-load-path instead.
(use-package! typst-ts-mode
  :mode ("\\.typ\\'" . typst-ts-mode))

(defun typst-pdf-revert-visible ()
  "After saving a .typ file, revert every visible pdf-view buffer."
  (when (and buffer-file-name
             (string-match-p "\\.typ\\'" buffer-file-name))
    (run-at-time
     0.4 nil
     (lambda ()
       (dolist (win (window-list))
         (let ((buf (window-buffer win)))
           (when (buffer-local-value 'buffer-file-name buf)
             (with-current-buffer buf
               (when (derived-mode-p 'pdf-view-mode)
                 (with-selected-window win
                   (pdf-view-revert-buffer nil t)
                   (pdf-view-redisplay t)))))))))))

(add-hook 'after-save-hook #'typst-pdf-revert-visible)
(remove-hook 'pdf-view-mode-hook #'auto-revert-mode)

;; nov
(use-package! nov
  :mode ("\\.epub\\'" . nov-mode))

;; org lives in $XDG_DOCUMENTS_DIR/org (currently ~/Media/Documents/org).
;; Derived from the env var (exported by Home Manager) so it follows the XDG
;; dir and never breaks on a future move.
(setq org-directory
      (expand-file-name "org" (or (getenv "XDG_DOCUMENTS_DIR") "~/Media/Documents")))
(use-package! org-noter
  :config
  (setq org-noter-notes-search-path (list (expand-file-name "noter" org-directory))))

;; +corfu +cape
;; Auto-complete on the FIRST char. Doom sets prefix=2 inside `corfu-auto', so
;; override after THAT feature (not `corfu') or it wins.
(after! corfu-auto
  (setq corfu-auto t
        corfu-auto-delay 0.15
        corfu-auto-prefix 1))

;; THE fix for janky LSP completion (rust/nix/all langs): eglot hands corfu a
;; CACHED completion set and corfu won't re-request from the server as you type,
;; so completion is inconsistent/slow/absent. cape's cache-buster forces a fresh
;; LSP query on each keystroke. Refs: eglot discussion #1127, corfu wiki.
(after! eglot
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster))

;; (Removed the manual `prog-mode-hook'/`text-mode-hook' -> corfu-mode enables:
;;  redundant with Doom's global-corfu-mode, which is the recommended approach.)

;; On Nix, doom-user-dir (DOOMDIR) is a READ-ONLY /nix/store copy, so the stock
;; `SPC f p' / `SPC f P' (find/browse private config) open an uneditable path.
;; Point them at the real editable source that home-manager tangles into the
;; store. Edit here, then `home-manager switch' to apply.
(defvar +doom-source-dir (expand-file-name "~/.config/nixos/users/greg/doom/")
  "Editable source of this Doom config (copied into the store by home-manager).")

(map! :leader
      :desc "Find file in Doom config (source)" "f p"
      (cmd! (doom-project-find-file +doom-source-dir))
      :desc "Browse Doom config (source)"       "f P"
      (cmd! (dired +doom-source-dir)))

;; nix-doom-emacs-unstraightened builds Doom into a read-only /nix/store profile.
;; The elisp syntax checker validates a file by byte-compiling it in a subprocess;
;; for our own config files that macroexpands `doom!'/`map!', which re-runs Doom's
;; module loader and dies with a spurious "Error in a Doom module ... (exit 255)"
;; shown right on the buffer (it is NOT a real build/startup error — Doom loads
;; clean). These files only load inside a fully-built Doom, so turn the elisp
;; checkers off for files under the editable source (or the store copy); real
;; elisp projects elsewhere keep their checkers.
(add-hook! 'emacs-lisp-mode-hook
  (defun +greg/disable-checkers-in-doom-config-h ()
    (when (and buffer-file-name
               (or (file-in-directory-p buffer-file-name +doom-source-dir)
                   (file-in-directory-p buffer-file-name doom-user-dir)))
      (setq-local flycheck-disabled-checkers
                  (append '(emacs-lisp emacs-lisp-checkdoc)
                          (bound-and-true-p flycheck-disabled-checkers)))
      (remove-hook 'flymake-diagnostic-functions #'elisp-flymake-byte-compile t)
      (remove-hook 'flymake-diagnostic-functions #'elisp-flymake-checkdoc t))))

;; Use nixd as the Nix LSP (installed via packages.nix) instead of Doom's default.
(after! nix-mode
  (set-eglot-client! 'nix-mode '("nixd")))

;; nixd gives diagnostics out of the box but returns NO completions until it's
;; told which nixpkgs to evaluate. Point it at this flake's nixpkgs so
;; `pkgs.<name>`, `lib.<name>`, etc. complete. (options.* would add
;; home-manager/NixOS option completion; add later if wanted.)
(after! eglot
  (setq-default eglot-workspace-configuration
                '(:nixd
                  (:nixpkgs
                   (:expr "import (builtins.getFlake \"/home/greg/.config/nixos\").inputs.nixpkgs { }")
                   :formatting (:command ["nixfmt"])))))

;; Languages Doom has no dedicated +lsp module for. Register their eglot
;; servers (installed via packages.nix) and turn eglot on in those buffers.
;; (nix/rust/cc/python/js/lua/sh already get eglot from their Doom modules.)
(after! eglot
  (add-to-list 'eglot-server-programs '(typst-ts-mode . ("tinymist")))
  (add-to-list 'eglot-server-programs '(markdown-mode . ("marksman" "server")))
  (add-to-list 'eglot-server-programs
               '((conf-toml-mode toml-ts-mode) . ("taplo" "lsp" "stdio")))
  (add-to-list 'eglot-server-programs '(sql-mode . ("sqls"))))

(dolist (h '(typst-ts-mode-hook
             markdown-mode-hook
             conf-toml-mode-hook
             sql-mode-hook))
  (add-hook h #'eglot-ensure))

;; empv: drive mpv from Emacs (lighter than vlc). mpv + yt-dlp come from Nix;
;; empv talks to mpv over its IPC socket directly (no socat needed). Drop mpv's
;; default `--no-video' so it's a real video player, not audio-only.
(use-package! empv
  :config
  (setq empv-mpv-args (remove "--no-video" empv-mpv-args))
  (map! :leader
        (:prefix ("o" . "open")
         (:prefix ("v" . "mpv (empv)")
          :desc "Play file"        "v"   #'empv-play-file
          :desc "Play video"       "V"   #'empv-play-video
          :desc "Play directory"   "d"   #'empv-play-directory
          :desc "Media at point"   "."   #'empv-play-media-at-point
          :desc "YouTube"          "y"   #'empv-youtube
          :desc "Pause/resume"     "SPC" #'empv-toggle
          :desc "Playlist"         "p"   #'empv-playlist-select
          :desc "Next"             "n"   #'empv-playlist-next
          :desc "Previous"         "N"   #'empv-playlist-prev
          :desc "Seek"             "s"   #'empv-seek
          :desc "Volume"           "u"   #'empv-set-volume
          :desc "Quit mpv"         "q"   #'empv-exit))))

;;; config.el ends here
