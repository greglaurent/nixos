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
;; (setq doom-theme 'doom-one)
(setq doom-theme 'doom-sourcerer)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; .ron (Rusty Object Notation) otherwise opens in fundamental-mode, which
;; Doom's line-number hook (prog/text/conf only) never touches. ron-mode derives
;; from prog-mode, so it brings real RON highlighting AND the line numbers.
(use-package! ron-mode
  :mode "\\.ron\\'")

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
  :mode ("\\.typ\\'" . typst-ts-mode)
  ;; typst-ts-mode derives from prog-mode, which truncates rather than wraps, so
  ;; each prose paragraph shows as one huge line. visual-line-mode soft-wraps at
  ;; the window edge on word boundaries (built-in; the Doom :ui word-wrap module
  ;; is disabled). It's display-only — no newlines are inserted in the file.
  :hook (typst-ts-mode . visual-line-mode)
  :config
  ;; Preview opens the compiled PDF in an Emacs pdf-view buffer (via pdf-tools,
  ;; :tools (pdf +external)) instead of the browser. typst-ts-preview funcalls
  ;; this on the output path; default is `browse-url' -> xdg-open -> browser.
  ;; find-file-other-window keeps the source visible and reuses the buffer on
  ;; re-preview, and it pairs with `typst-pdf-revert-visible' below so the PDF
  ;; auto-updates on every save.
  (setq typst-ts-preview-function #'find-file-other-window))

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

;; Org/agenda location is defined in nix (modules/home/org.nix -> myOrgDir,
;; default <myDoomContentDir>/org, i.e. users/<name>/content/doom/org — the
;; authored-content half of the dots/content split) and exported as
;; $ORG_DIRECTORY. Prefer that env var; but a systemd/emacsclient daemon does not
;; always receive it, so the fallbacks ALSO resolve to content/doom/org — never a
;; dead path, and never a hardcoded user. Order: $ORG_DIRECTORY ->
;; $DOOM_CONTENT_DIR/org -> a path derived from the RUNTIME username, mirroring
;; how nix derives it (myFlakeRoot/users/<name>/content/doom). Change the real
;; location in nix, never here.
(setq org-directory
      (or (getenv "ORG_DIRECTORY")
          (expand-file-name
           "org"
           (or (getenv "DOOM_CONTENT_DIR")
               (expand-file-name
                (format "users/%s/content/doom" (user-login-name))
                "~/.config/nixos")))))
;; Agenda-file REGISTRY: org's *file-based* `org-agenda-files' — a plain text
;; file (one path per line) inside the org dir. It's seeded with org-directory
;; itself, so every .org there auto-includes; `C-c [' / `C-c ]' register or
;; unregister files FROM ANYWHERE by writing lines to THIS file — never
;; custom.el. Entries absent on a given machine are skipped, not errored.
(unless (file-directory-p org-directory)
  (ignore-errors (make-directory org-directory t)))
(setq org-agenda-files (expand-file-name ".agenda-files" org-directory))
(unless (file-exists-p org-agenda-files)
  (ignore-errors (with-temp-file org-agenda-files (insert org-directory "\n"))))
(setq org-agenda-skip-unavailable-files t)
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
;;
;; Two writable trees, per the dots/content standard:
;;   • +doom-source-dir  -> dots/doom    ($DOOM_CONFIG_DIR): the reproducible .el
;;     config (a build input). Editing it needs a rebuild.
;;   • +doom-content-dir -> content/doom ($DOOM_CONTENT_DIR): authored, tracked,
;;     NOT built — snippets, file-templates, abbrevs. Loaded live, no rebuild.
(defvar +doom-source-dir
  (file-name-as-directory
   (or (getenv "DOOM_CONFIG_DIR")
       (expand-file-name "~/.config/nixos/users/greg/dots/doom")))
  "Editable source of this Doom *config* — the reproducible .el, a writable git
checkout that home-manager tangles into the read-only store. From nix via
$DOOM_CONFIG_DIR (emacs.nix) so no path is hardcoded here.")

(defvar +doom-content-dir
  (file-name-as-directory
   (or (getenv "DOOM_CONTENT_DIR")
       (expand-file-name "~/.config/nixos/users/greg/content/doom")))
  "Authored, tracked-but-not-built Doom content (snippets, file-templates,
abbrevs). From nix via $DOOM_CONTENT_DIR (emacs.nix) so no path is hardcoded
here.")

(map! :leader
      :desc "Find file in Doom config (source)" "f p"
      (cmd! (doom-project-find-file +doom-source-dir))
      :desc "Browse Doom config (source)"       "f P"
      (cmd! (dired +doom-source-dir)))

;; ── nix-doom read-only DOOMDIR: route every writable-state target ────────────
;; nix-doom builds DOOMDIR into the read-only /nix/store, so anything that writes
;; back into it fails with "Read-only file system". Two kinds of writes, routed
;; by intent:
;;   • runtime state you don't curate (customize saves, themes) ->
;;     doom-data-dir: writable, persistent, machine-local.
;;   • content you AUTHOR (snippets, file-templates, abbrevs) -> content/doom
;;     (+doom-content-dir): a writable, tracked git checkout — version-controlled,
;;     loaded live, resolved by `nixos-rebuild switch'. NEVER ~/.local, never the
;;     store, never the reproducible dots/doom tree.
;; (load-path / doom-module-load-path / doom-user-dir itself are read-only
;; *resources*, correctly immutable.)

;; 1. customize saves: `M-x customize' "save for future sessions" writes here.
;;    (Agenda files do NOT use this — they live in $ORG_DIRECTORY/.agenda-files
;;    via org's file-based org-agenda-files; see the org section below.)
(setq custom-file (expand-file-name "custom.el" doom-data-dir))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; 2. yasnippet + file-templates. New snippets/templates author DIRECTLY into the
;;    flake source (writable checkout) — so `yas-new-snippet' lands in the repo,
;;    version-controlled, loaded live (no rebuild to use it; `git commit' to keep
;;    it). Doom's built-in snippets (doom-snippets-dir) and the 90 built-in
;;    file-templates (+file-templates-dir, read-only module) are left intact.
(setq +snippets-dir (expand-file-name "snippets/" +doom-content-dir))
(after! yasnippet
  ;; user file-templates live in the flake too; appended so +snippets-dir stays
  ;; the default target for `yas-new-snippet'.
  (add-to-list 'yas-snippet-dirs (expand-file-name "file-templates/" +doom-content-dir) :append))

;; 3. themes saved/customized from within Emacs.
(setq custom-theme-directory (expand-file-name "themes/" doom-data-dir))

;; 4. abbrevs — authored data like snippets, so `save-abbrevs' (on exit / `M-x
;;    write-abbrev-file') writes into the flake source (version-controlled), not
;;    ~/.local. Created on first save; `git commit' to keep it.
(setq abbrev-file-name (expand-file-name "abbrev_defs" +doom-content-dir))
(when (file-exists-p abbrev-file-name)
  (ignore-errors (quietly-read-abbrev-file abbrev-file-name)))

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
