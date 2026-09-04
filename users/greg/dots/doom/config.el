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
(setq doom-font (font-spec :family "JetBrains Mono" :size 14)
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
  (setq org-noter-notes-search-path (list (expand-file-name "noter" org-directory))
        ;; Split the CURRENT frame instead of popping a new OS window (default is t).
        org-noter-always-create-frame nil))

;; A `C-c'-space partner for `M-x' (both reach `execute-extended-command', the run-any-
;; command-by-name launcher) — for when Alt+x is awkward. `M-x' still works everywhere.
(map! "C-c x" #'execute-extended-command)

;; ── marginalia capture (§4a: per-source folder → parent node + atomic children) ──
;; Reading model: from the PDF, create the SOURCE PARENT once (C-c n — title from your
;; selection, so highlight the doc title first). The parent gets its OWN folder under
;; `marginalia-notes-dir' (roam/marginalia/), an :ID:, and a ROBUST reference to the paper;
;; it's where long-form
;; notes live and it's the context every child reads. Then each highlight becomes an
;; ATOMIC CHILD node (C-c i / M-i) saved in that folder, all metadata auto-stamped
;; (:ID:, parent id, page, quote block, id-link back to the parent) so you write ONLY the
;; note body. C-c I harvests every existing pdf-annot highlight into children at once.
;;
;; The paper is NEVER co-located with the notes and NO path is ever baked into a note. A
;; book is the "one" — identified INTRINSICALLY by its content hash (`:MARGINALIA_DOC_ID:'),
;; the ONLY reference a note holds; the notes are the "many" that point at that identity.
;; WHERE the book lives is a separate, derived concern: books may sit in any number of
;; unrelated folders — there is no single library root. A rebuildable index (like
;; `org-id-locations') maps hash → current path, recorded at capture and refreshed on open;
;; if a book has moved, `marginalia-open-source' rescans `marginalia-library-dirs' (a LIST
;; of search roots, possibly empty) by hash, and failing that asks you to locate it once.
;; No linking/AI yet. (org-pdftools/org-noter-pdftools NOT loaded — the `listp' crash.)

(defgroup marginalia-notes nil
  "Personal PDF→org note capture (distinct from the `marginalia' completion package)."
  :group 'org)

(defcustom marginalia-library-dirs
  (let ((v (getenv "MARGINALIA_LIBRARY_DIRS")))
    (and v (split-string v ":" t)))
  "Directories to search — by content hash — for a source document whose cached location
has gone stale (a book was moved or renamed, or you are on another machine).
A LIST: your books may live in any number of unrelated folders; none has to be a single
flat root, and this may be empty (you are then asked to locate a moved book once).  Capture
records a book's exact path, so opening a book that has not moved never needs this.
Seeded from $MARGINALIA_LIBRARY_DIRS (colon-separated), which nix sets from the
`myMarginaliaLibrary' option — so the library path is defined once, in the nix config,
never hardcoded here."
  :type '(repeat directory) :group 'marginalia-notes)

(defcustom marginalia-notes-dir nil
  "Directory holding marginalia's per-source folders and its location index.
Must live UNDER `org-roam-directory' so org-roam indexes the notes.  When nil (default),
resolves to a `marginalia/' subfolder of `org-roam-directory' — namespaced so source
folders don't intermingle with hand-written roam notes."
  :type '(choice (const :tag "roam/marginalia (default)" nil) directory)
  :group 'marginalia-notes)

(defun marginalia--notes-dir ()
  "The resolved marginalia notes directory (see `marginalia-notes-dir')."
  (or marginalia-notes-dir (expand-file-name "marginalia" org-roam-directory)))

(defvar marginalia--doc-locations nil
  "Alist (HASH . ABSOLUTE-PATH): the rebuildable index from a book's content id to where it
currently lives.  A derived cache — like `org-id-locations', never canonical; delete it and
it rebuilds from `marginalia-library-dirs'.")

(defun marginalia--slug (s)
  "A filesystem-safe slug from string S."
  (string-trim (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase (string-trim s)))
               "-+" "-+"))

(defun marginalia--gist (s &optional n)
  "First N (default 12) words of S as a one-line human label."
  (string-join (seq-take (split-string (string-trim s)) (or n 12)) " "))

(defun marginalia--pdf-selection ()
  "The current PDF text selection as a trimmed string, or nil."
  (let* ((text (condition-case nil (pdf-view-active-region-text) (error nil)))
         (s (and text (string-trim (string-join text " ")))))
    (and s (not (string-empty-p s)) s)))

(defun marginalia--doc-hash (file)
  "Content identity (sha1 of the raw bytes) of FILE."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (secure-hash 'sha1 (current-buffer))))

(defun marginalia--scan-for-hash (dir hash)
  "First file under DIR whose content hash equals HASH, else nil."
  (and (file-directory-p dir)
       (seq-find (lambda (f) (equal (marginalia--doc-hash f) hash))
                 (directory-files-recursively dir "\\.\\(?:pdf\\|epub\\)\\'"))))

;; ── book identity → location index (derived, rebuildable; mirrors `org-id-locations') ──
(defun marginalia--doc-locations-file ()
  (expand-file-name ".marginalia-doc-locations.eld" (marginalia--notes-dir)))

(defun marginalia--doc-locations-load ()
  (let ((f (marginalia--doc-locations-file)))
    (when (and (null marginalia--doc-locations) (file-exists-p f))
      (with-temp-buffer
        (insert-file-contents f)
        (setq marginalia--doc-locations (ignore-errors (read (current-buffer))))))
    marginalia--doc-locations))

(defun marginalia--doc-record (hash path)
  "Record HASH → PATH (absolute) in the location index and persist it. Return the path."
  (marginalia--doc-locations-load)
  (setf (alist-get hash marginalia--doc-locations nil nil #'equal) (expand-file-name path))
  (with-temp-file (marginalia--doc-locations-file)
    (prin1 marginalia--doc-locations (current-buffer)))
  (expand-file-name path))

(defun marginalia--doc-locate (hash)
  "Absolute path of the book with content HASH, or nil.
Consults the cached index; if its path is stale, rescans `marginalia-library-dirs' (any
number of unrelated roots) by hash and re-records.  Never assumes a single library root."
  (when hash
    (marginalia--doc-locations-load)
    (let ((cached (alist-get hash marginalia--doc-locations nil nil #'equal)))
      (if (and cached (file-exists-p cached)) cached
        (let ((found (seq-some (lambda (d) (marginalia--scan-for-hash (expand-file-name d) hash))
                               marginalia-library-dirs)))
          (and found (marginalia--doc-record hash found)))))))

(defun marginalia--doc-prompt (hash)
  "Ask where the book with content HASH now lives; verify its contents and record it."
  (let ((f (read-file-name "Locate source document: " nil nil t)))
    (when (and f (file-exists-p f) (not (file-directory-p f))
               (or (equal (marginalia--doc-hash f) hash)
                   (y-or-n-p "That file's contents don't match this note's source — use it anyway? ")))
      (marginalia--doc-record hash f))))

(defun marginalia--file-prop (file prop)
  "Value of the top-level :PROP: in org FILE, or nil."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward (format "^:%s:[ \t]+\\(.+?\\)[ \t]*$" (regexp-quote prop)) nil t)
      (match-string 1))))

(defun marginalia--file-keyword (file kw)
  "Value of the #+KW: line in org FILE, or nil."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward (format "^#\\+%s:[ \t]+\\(.+?\\)[ \t]*$" (regexp-quote kw)) nil t)
      (match-string 1))))

(defun marginalia--set-file-prop (file prop value)
  "Set the top-level :PROP: to VALUE in org FILE (in its first property drawer)."
  (with-current-buffer (find-file-noselect file)
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward (format "^:%s:.*$" (regexp-quote prop)) nil t)
          (replace-match (format ":%s: %s" prop value) t t)
        (when (re-search-forward "^:PROPERTIES:$" nil t)
          (end-of-line) (insert (format "\n:%s: %s" prop value)))))
    (save-buffer)))

(defun marginalia--refingerprint (pdf pfile)
  "After PDF's bytes changed (a highlight was baked in), update parent PFILE's
`:MARGINALIA_DOC_ID:' and the location index so hash-based resolution still matches the
current file. No-op if the hash is unchanged."
  (let ((old (marginalia--file-prop pfile "MARGINALIA_DOC_ID"))
        (new (marginalia--doc-hash pdf)))
    (unless (equal old new)
      (marginalia--set-file-prop pfile "MARGINALIA_DOC_ID" new)
      (marginalia--doc-locations-load)
      (when old
        (setq marginalia--doc-locations (assoc-delete-all old marginalia--doc-locations)))
      (marginalia--doc-record new pdf))))

(defvar-local marginalia--parent nil
  "Plist (:id :file :dir :title) of this PDF's source parent, set by `marginalia-source-here'.")

(defun marginalia--show-reading-layout (pfile)
  "Lay the current window out as PDF | parent-note (PFILE); cursor stays in the PDF."
  (delete-other-windows)
  (set-window-buffer (split-window-right) (find-file-noselect pfile)))

(defun marginalia--open-parent (pfile)
  "Set PFILE as the source context and lay out the PDF | parent reading workspace."
  (marginalia--show-reading-layout pfile)
  (setq marginalia--parent
        (list :id (marginalia--file-prop pfile "ID") :file pfile
              :dir (file-name-directory pfile)
              :title (or (marginalia--file-keyword pfile "title") (file-name-base pfile)))))

(defun marginalia--parent-for-pdf (pdf)
  "The existing parent note whose `:MARGINALIA_DOC_ID:' matches PDF's content hash, or nil.
Scans each per-source folder under `marginalia-notes-dir' for its `<slug>/<slug>.org'."
  (let ((dir (marginalia--notes-dir)))
    (and (file-directory-p dir)
         (let ((hash (marginalia--doc-hash pdf)))
           (seq-some
            (lambda (sub)
              (let ((pf (expand-file-name
                         (concat (file-name-nondirectory (directory-file-name sub)) ".org") sub)))
                (and (file-exists-p pf)
                     (equal (marginalia--file-prop pf "MARGINALIA_DOC_ID") hash)
                     pf)))
            (seq-filter #'file-directory-p (directory-files dir t "\\`[^.]")))))))

(defun marginalia-source-here ()
  "Open the reading workspace for the PDF in this buffer.
If a SOURCE PARENT already exists for this book it is opened (found by content hash, then by
title-slug) — no title needed. Otherwise a new parent is created: title = the current
selection (highlight the document title first) else a prompt; it gets its own folder under
`marginalia-notes-dir', an :ID:, and the book's identity `:MARGINALIA_DOC_ID:'. Either way,
lays out PDF | parent and sets the capture context."
  (interactive)
  (unless (derived-mode-p 'pdf-view-mode)
    (user-error "Run this from the PDF buffer"))
  (require 'org-roam)
  (require 'org-id)
  (let* ((pdf      (buffer-file-name))
         (existing (marginalia--parent-for-pdf pdf)))
    (if existing
        (progn (marginalia--open-parent existing)
               (message "Source: %s" (plist-get marginalia--parent :title)))
      (let* ((title (or (marginalia--pdf-selection) (read-string "Source title: ")))
             (_ (when (string-empty-p (string-trim title)) (user-error "Empty title")))
             (slug (marginalia--slug title))
             (dir  (expand-file-name slug (marginalia--notes-dir)))
             (file (expand-file-name (concat slug ".org") dir)))
        (if (file-exists-p file)                    ; title-slug match (e.g. hash drifted)
            (progn (marginalia--open-parent file)
                   (message "Source: %s" (plist-get marginalia--parent :title)))
          (make-directory dir t)
          (let ((id (org-id-uuid)) (hash (marginalia--doc-hash pdf)))
            (with-temp-file file
              (insert (format (concat ":PROPERTIES:\n:ID:       %s\n:MARGINALIA_DOC_ID: %s\n:END:\n"
                                      "#+title: %s\n\n* Notes\n\n")
                              id hash title)))
            (marginalia--doc-record hash pdf)
            (org-roam-db-update-file file)
            (marginalia--open-parent file)
            (message "Source: %s  (children → %s/)" title (file-name-nondirectory dir))))))))

(defun marginalia--new-child (quote page &optional open)
  "Create an atomic CHILD note for QUOTE at PAGE in the current parent's folder.
Return (ID . FILE). With OPEN non-nil, visit it (other window) at the body.  The child
carries NO paper path — only the parent id + page; the paper is reached via the parent
with `marginalia-open-source'."
  (unless marginalia--parent
    (user-error "No source parent yet — create it first with `marginalia-source-here' (C-c n)"))
  (require 'org-roam)
  (require 'org-id)
  (let* ((dir   (plist-get marginalia--parent :dir))
         (pid   (plist-get marginalia--parent :id))
         (id    (org-id-uuid))
         (stamp (format-time-string "%Y%m%dT%H%M%S"))
         (file  (expand-file-name (format "%s-%s.org" stamp (substring id 0 8)) dir))
         (title (marginalia--gist quote)))
    (with-temp-file file
      (insert (format (concat ":PROPERTIES:\n:ID:       %s\n:MARGINALIA_SOURCE: id:%s\n"
                              ":MARGINALIA_PAGE: %d\n:END:\n#+title: %s\n\n"
                              "#+begin_quote\n%s\n#+end_quote\n[[id:%s][source: p.%d]]\n\n")
                      id pid page title quote pid page)))
    (org-roam-db-update-file file)
    (when open
      (find-file-other-window file)
      (goto-char (point-max)))
    (cons id file)))

(defun marginalia-open-source ()
  "From a marginalia note (parent or child), open its source document at the note's page.
Finds the book by its content id via the location index; if it has moved, rescans
`marginalia-library-dirs', and failing that asks you to locate it once (re-recording it).
Sets the capture context so you can keep adding children."
  (interactive)
  (unless (buffer-file-name) (user-error "Not visiting a file"))
  (let* ((dir   (file-name-directory (buffer-file-name)))
         (pfile (expand-file-name
                 (concat (file-name-nondirectory (directory-file-name dir)) ".org") dir)))
    (unless (file-exists-p pfile)
      (user-error "No source parent in this folder — not a marginalia note?"))
    (let* ((hash (marginalia--file-prop pfile "MARGINALIA_DOC_ID"))
           (abs  (or (marginalia--doc-locate hash) (marginalia--doc-prompt hash)))
           (page (let ((p (marginalia--file-prop (buffer-file-name) "MARGINALIA_PAGE")))
                   (and p (string-to-number p)))))
      (unless abs
        (user-error "Source not found — set `marginalia-library-dirs' or locate the file"))
      (find-file abs)
      (when page (ignore-errors (pdf-view-goto-page page)))
      (marginalia--show-reading-layout pfile)         ; PDF | parent reading workspace
      (setq marginalia--parent
            (list :id (marginalia--file-prop pfile "ID") :file pfile :dir dir
                  :title (or (marginalia--file-keyword pfile "title") (file-name-base pfile))))
      (message "Opened source%s" (if page (format " at p.%d" page) "")))))

(defun marginalia--do-capture (open)
  "Selection → atomic CHILD note + a baked, note-linked highlight; re-fingerprint the book.
With OPEN non-nil, visit the note in a bottom split to annotate; otherwise just flag it and
stay in the PDF."
  (unless (derived-mode-p 'pdf-view-mode)
    (user-error "Run this from the PDF buffer"))
  (unless marginalia--parent
    (user-error "No source context — open the source (C-c n / `marginalia-open-source') first"))
  (require 'pdf-annot)
  (let ((region (ignore-errors (pdf-view-active-region)))  ; (PAGE . edges), grab before text read
        (quote  (marginalia--pdf-selection)))
    (unless quote
      (user-error "No PDF text selected — drag across the text first"))
    (let* ((page  (pdf-view-current-page))
           (pfile (plist-get marginalia--parent :file))
           (res   (marginalia--new-child quote page))       ; (ID . FILE); don't open here
           (id    (car res))
           (file  (cdr res))
           (marked nil))
      (when region
        (condition-case err
            (progn
              (pdf-annot-add-highlight-markup-annotation
               region nil `((contents . ,(marginalia--gist quote)) (label . ,id)))
              (save-buffer)                                  ; persist the highlight into the PDF
              (marginalia--refingerprint (buffer-file-name) pfile)  ; bytes changed → re-id
              (setq marked t))
          (error (message "marginalia: highlight not saved (%s) — note kept"
                          (error-message-string err)))))
      (if open
          (progn                                            ; annotate now, in a bottom split
            (select-window (display-buffer (find-file-noselect file)
                                           '(display-buffer-at-bottom (window-height . 0.3))))
            (goto-char (point-max))
            (message "Captured child (p.%d)%s" page (if marked "" " — no highlight")))
        (message "Flagged (p.%d)%s" page (if marked "" " — no highlight"))))))

(defun marginalia-capture-pdf ()
  "Capture the selection as a child note + highlight, and open the note to annotate."
  (interactive) (marginalia--do-capture t))

(defun marginalia-highlight-pdf ()
  "Highlight the selection: create the child note + highlight + save, but DON'T open it.
For marking a passage to annotate later — you stay in the PDF and keep reading."
  (interactive) (marginalia--do-capture nil))

(defun marginalia--pdf-annot-text (a)
  "Highlighted text of markup annotation object A."
  (let ((page  (pdf-annot-get a 'page))
        (edges (or (pdf-annot-get a 'markup-edges)
                   (list (pdf-annot-get a 'edges)))))
    (string-trim (mapconcat (lambda (e) (pdf-info-gettext page e)) edges " "))))

(defun marginalia--annot-noted-p (a)
  "Non-nil if annotation A already links to an existing marginalia note (via its `label')."
  (let ((label (pdf-annot-get a 'label)))
    (and label (not (string-empty-p label)) (marginalia--note-file-for-id label))))

(defun marginalia-capture-pdf-annotations (&optional all-pages)
  "Turn EXISTING pdf highlight annotations into atomic CHILD notes, SKIPPING any that
already have a marginalia note. Each newly-noted highlight is linked to its note (its
`label' set to the note id) so re-running never duplicates and clicking it opens the note.
Current page by default; with a prefix arg (C-u), the whole document."
  (interactive "P")
  (unless (derived-mode-p 'pdf-view-mode)
    (user-error "Run this from the PDF buffer"))
  (unless marginalia--parent
    (user-error "No source context — open the source (C-c n / `marginalia-open-source') first"))
  (require 'pdf-annot)
  (let* ((page   (pdf-view-current-page))
         (annots (pdf-annot-getannots (unless all-pages page)
                                      '(highlight underline squiggly strike-out)))
         (n 0) (skipped 0))
    (unless annots
      (user-error "No highlight annotations on %s"
                  (if all-pages "this document" (format "page %d" page))))
    (dolist (a annots)
      (if (marginalia--annot-noted-p a)
          (setq skipped (1+ skipped))
        (let ((text (marginalia--pdf-annot-text a)))
          (unless (string-empty-p text)
            (let ((id (car (marginalia--new-child text (pdf-annot-get a 'page)))))
              (pdf-annot-put a 'label id)                    ; link highlight → note
              (when (string-empty-p (or (pdf-annot-get a 'contents) ""))
                (pdf-annot-put a 'contents (marginalia--gist text)))  ; readable tooltip
              (setq n (1+ n)))))))
    (when (> n 0)
      (save-buffer)                                          ; persist the new labels/contents
      (marginalia--refingerprint (buffer-file-name) (plist-get marginalia--parent :file)))
    (message "Harvested %d note(s)%s" n
             (if (> skipped 0) (format ", skipped %d already-noted" skipped) ""))))

(defun marginalia--children-on-page (dir page)
  "Child note files in DIR captured from PAGE (matched on their :MARGINALIA_PAGE:)."
  (let ((p (number-to-string page)))
    (seq-filter (lambda (f) (equal (marginalia--file-prop f "MARGINALIA_PAGE") p))
                (directory-files dir t "\\.org\\'"))))

(defun marginalia-notes-for-page ()
  "Show the child note(s) captured from the current PDF page in a bottom split.
Uses the source context set by `marginalia-source-here'/`marginalia-open-source'. If several
notes came from the page, pick one (each is titled by the first words of its quote, so the
picker doubles as choosing which highlight). The PDF keeps focus."
  (interactive)
  (unless (derived-mode-p 'pdf-view-mode)
    (user-error "Run this from the PDF"))
  (unless marginalia--parent
    (user-error "No source context — open the source (C-c n, or `marginalia-open-source') first"))
  (let* ((page  (pdf-view-current-page))
         (files (marginalia--children-on-page (plist-get marginalia--parent :dir) page)))
    (unless files
      (user-error "No notes captured from page %d" page))
    (let ((file (if (cdr files)
                    (let ((alist (mapcar (lambda (f)
                                           (cons (or (marginalia--file-keyword f "title")
                                                     (file-name-base f))
                                                 f))
                                         files)))
                      (cdr (assoc (completing-read (format "Note (p.%d): " page) alist nil t)
                                  alist)))
                  (car files))))
      (display-buffer (find-file-noselect file)
                      '(display-buffer-at-bottom (window-height . 0.3))))))

;; ── deletion coupling: highlights and notes don't orphan each other ──────────────
;; A highlight's `contents' holds its child note's :ID:. Deleting a NOTE
;; (`marginalia-delete-note') removes its highlight too (the highlight is disposable).
;; Deleting a HIGHLIGHT in pdf-view offers to delete its note (default no — a note holds
;; your explication + graph links, so never silently). Both paths re-fingerprint.
(defvar marginalia--deleting nil
  "Bound to t while marginalia performs a coordinated note+highlight delete, to keep the
pdf-annot deletion hook from re-prompting for the same note.")

(defun marginalia--note-file-for-id (id)
  "The note file whose top-level :ID: is ID — the current source folder first, then roam."
  (or (and marginalia--parent
           (let ((dir (plist-get marginalia--parent :dir)))
             (and (file-directory-p dir)
                  (seq-find (lambda (f) (equal (marginalia--file-prop f "ID") id))
                            (directory-files dir t "\\.org\\'")))))
      (ignore-errors
        (require 'org-roam)
        (let ((n (org-roam-node-from-id id))) (and n (org-roam-node-file n))))))

(defun marginalia--delete-note-file (file)
  "Delete note FILE: kill its buffer, remove it, deregister it from org-roam."
  (when (and file (file-exists-p file))
    (let ((buf (find-buffer-visiting file))) (when buf (kill-buffer buf)))
    (delete-file file)
    (ignore-errors (require 'org-roam) (org-roam-db-clear-file file))
    (message "marginalia: deleted note %s" (file-name-nondirectory file))))

(defun marginalia--on-annots-modified (closure)
  "`pdf-annot-modified-functions' handler: when a marginalia-linked highlight is deleted,
offer to delete its note too. Skipped during marginalia's own coordinated delete."
  (unless marginalia--deleting
    (dolist (a (funcall closure :deleted))
      (let* ((id   (ignore-errors (pdf-annot-get a 'label)))
             (note (and id (not (string-empty-p id)) (marginalia--note-file-for-id id))))
        (when (and note
                   (y-or-n-p "marginalia: highlight deleted — also delete its linked note? "))
          (marginalia--delete-note-file note))))))

(defun marginalia--enable-annot-hook ()
  (add-hook 'pdf-annot-modified-functions #'marginalia--on-annots-modified nil t))
(add-hook 'pdf-view-mode-hook #'marginalia--enable-annot-hook)

(defun marginalia--activate-handler (a)
  "Clicking a marginalia highlight opens its linked note in a bottom split.
The note id lives in the annotation's `label'; `contents' holds a readable gist for the
tooltip. Returns non-nil (handled) so pdf-tools' default edit-contents behaviour is
skipped for our highlights; nil for any other annotation so it behaves normally."
  (let* ((id   (ignore-errors (pdf-annot-get a 'label)))
         (file (and id (not (string-empty-p id)) (marginalia--note-file-for-id id))))
    (when file
      (select-window (display-buffer (find-file-noselect file)
                                     '(display-buffer-at-bottom (window-height . 0.3))))
      t)))
(add-hook 'pdf-annot-activate-handler-functions #'marginalia--activate-handler)

(defun marginalia-delete-note ()
  "Delete THIS marginalia child note and remove its highlight from the source PDF.
Run from the child note's buffer; refuses on a source parent (deleting a whole source is
not this command's job). Re-fingerprints the book after removing the highlight."
  (interactive)
  (unless (buffer-file-name) (user-error "Not visiting a file"))
  (let ((id  (marginalia--file-prop (buffer-file-name) "ID"))
        (src (marginalia--file-prop (buffer-file-name) "MARGINALIA_SOURCE")))
    (unless src
      (user-error "Not a child note (no :MARGINALIA_SOURCE:) — refusing"))
    (unless (y-or-n-p "Delete this note and its highlight? ") (user-error "Aborted"))
    (let* ((note  (buffer-file-name))
           (dir   (file-name-directory note))
           (pfile (expand-file-name
                   (concat (file-name-nondirectory (directory-file-name dir)) ".org") dir))
           (pdf   (marginalia--doc-locate (marginalia--file-prop pfile "MARGINALIA_DOC_ID"))))
      (when (and pdf (file-exists-p pdf))
        (require 'pdf-annot)
        (with-current-buffer (find-file-noselect pdf)
          (let ((hits (seq-filter (lambda (a) (equal (pdf-annot-get a 'label) id))
                                  (pdf-annot-getannots))))
            (when hits
              (let ((marginalia--deleting t))
                (dolist (a hits) (pdf-annot-delete a))
                (save-buffer))
              (marginalia--refingerprint pdf pfile)))))
      (marginalia--delete-note-file note))))

;; All marginalia lives under a `C-c m' (marginalia) prefix. PDF-side commands (capture)
;; in pdf-view-mode; note-side commands (open source, delete) in org-mode. `M-i' is kept as
;; a single-chord alias for capture (the key you reach for).
(map! :after pdf-tools
      :map pdf-view-mode-map
      :prefix ("C-c m" . "marginalia")
      "s" #'marginalia-source-here                 ; open/create the SOURCE parent (title = selection)
      "c" #'marginalia-capture-pdf                 ; capture: note + highlight, open it to annotate
      "h" #'marginalia-highlight-pdf               ; highlight: note + mark, DON'T open (keep reading)
      "a" #'marginalia-capture-pdf-annotations     ; harvest existing highlight annotations → notes
      "p" #'marginalia-notes-for-page)             ; this page's note(s) → bottom split
(map! :after pdf-tools :map pdf-view-mode-map
      "M-i" #'marginalia-capture-pdf)              ; single-chord capture alias

;; Note-side (parent/child buffers are org): open the source PDF (resolved by content hash —
;; the note stores no path), or delete this note + its highlight.
(map! :after org
      :map org-mode-map
      :prefix ("C-c m" . "marginalia")
      "o" #'marginalia-open-source                 ; open the source PDF at the note's page
      "d" #'marginalia-delete-note)                ; delete this note AND its highlight

;; ── cascade export (Org → typographic CSS/Typst/LaTeX/EPUB via the `cascade' CLI) ──
;; `cascade' comes from home.packages (its own flake, wrapping typst/tectonic/pandoc; it
;; uses your ambient emacs — which carries ox-typst — for Org export). Each command exports
;; the CURRENT .org buffer to one backend, into a
;; `cascade-dist/' folder beside the file, in a compilation buffer so errors/timeouts show.
;; marginalia can reuse `cascade-export--run' to render a note/parent.
(defun cascade-export--run (target)
  "Export the current .org buffer through cascade to TARGET (html/typst/latex/epub)."
  (unless (and (buffer-file-name) (string-suffix-p ".org" (buffer-file-name) t))
    (user-error "Not visiting a .org file"))
  (unless (executable-find "cascade")
    (user-error "`cascade' not on PATH — rebuild after adding the cascade flake input"))
  (save-buffer)
  (let* ((file (buffer-file-name))
         (out  (expand-file-name "cascade-dist" (file-name-directory file)))
         (default-directory (file-name-directory file))
         (compilation-buffer-name-function (lambda (&rest _) "*cascade export*")))
    (compile (format "cascade export %s --target %s --out %s"
                     (shell-quote-argument file) target (shell-quote-argument out)))))

(defun cascade-export-html ()
  "Export this Org buffer to styled HTML via cascade."
  (interactive) (cascade-export--run "html"))
(defun cascade-export-typst ()
  "Export this Org buffer to a Typst PDF via cascade."
  (interactive) (cascade-export--run "typst"))
(defun cascade-export-latex ()
  "Export this Org buffer to a LaTeX PDF via cascade."
  (interactive) (cascade-export--run "latex"))
(defun cascade-export-epub ()
  "Export this Org buffer to EPUB via cascade."
  (interactive) (cascade-export--run "epub"))

(defun cascade-build-here ()
  "Emit cascade's raw assets for the CURRENT file's medium into its directory, for
hand-authoring (as opposed to Org `export').  `.html'/`.htm' → cascade.css (link it and
scope content with class=\"cascade\"); `.tex' → cascade.sty (`\\usepackage{cascade}'); `.typ'
→ no files needed — offers to insert the `@local/cascade' import (the package is already
installed via typst.nix)."
  (interactive)
  (unless (buffer-file-name) (user-error "Not visiting a file"))
  (let ((ext (downcase (or (file-name-extension (buffer-file-name)) "")))
        (dir (file-name-directory (buffer-file-name))))
    (pcase ext
      ("typ"
       (if (y-or-n-p "Typst uses the @local/cascade package — insert the import at point? ")
           (insert "#import \"@local/cascade:0.1.0\": cascade\n#show: cascade\n")
         (message "In your .typ:  #import \"@local/cascade:0.1.0\": cascade   +   #show: cascade")))
      ((or "html" "htm" "tex")
       (unless (executable-find "cascade")
         (user-error "`cascade' not on PATH — rebuild first"))
       (let ((target (if (equal ext "tex") "latex" "css"))
             (default-directory dir)
             (compilation-buffer-name-function (lambda (&rest _) "*cascade build*")))
         (compile (format "cascade build --target %s --out ." target))))
      (_ (user-error "No cascade target for .%s (want html / tex / typ)" ext)))))

;; cascade under `C-c c' (first letter of the tool, paralleling `C-c m' for marginalia).
;; Global — the exports need an Org buffer (they check), while `b' (build assets to author
;; with) works in .html/.tex/.typ buffers.
(map! :prefix ("C-c c" . "cascade")
      "h" #'cascade-export-html
      "t" #'cascade-export-typst
      "l" #'cascade-export-latex
      "p" #'cascade-export-epub
      "b" #'cascade-build-here)

;; ── Org appearance ───────────────────────────────────────────────────────────
;; org-modern (minad — same lineage as the vertico/corfu stack here): pill-styled
;; TODO keywords/tags, modern bullets, tables, timestamps and #+begin/end blocks.
;; Supersedes the older org-bullets/org-superstar/org-fancy-priorities trio.
;; `global-org-modern-mode' styles BOTH org buffers and the agenda.
(after! org
  (setq org-hide-emphasis-markers t  ; org-appear re-reveals these on demand
        org-pretty-entities t        ; \alpha &c. render as their glyphs
        org-startup-indented t       ; org-indent on — org-modern-indent needs it
        org-modern-star 'replace)
  (global-org-modern-mode))

;; org-modern-indent: correct block styling under org-indent. Added at hook depth
;; 90 so it runs AFTER org-indent has set up its own indentation.
(use-package! org-modern-indent
  :after org
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

;; org-appear: hidden emphasis markers keep prose clean, but the *, /, ~, = markup
;; (and links) reveal themselves when the cursor enters the word, staying editable.
(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t))

;; org-super-agenda: group the agenda into labeled sections instead of one flat
;; list. Minimal starter grouping — tune `org-super-agenda-groups' to taste.
(use-package! org-super-agenda
  :after org-agenda
  :config
  (setq org-super-agenda-groups
        '((:name "Today"     :time-grid t :scheduled today)
          (:name "Overdue"   :deadline past)
          (:name "Due soon"  :deadline future)
          (:name "Important" :priority "A")))
  (org-super-agenda-mode))

;; Font ligatures in org-mode. Doom's :ui ligatures registers its 134-ligature
;; set ONLY for `prog-mode' (see +ligatures-alist); org-mode derives from
;; text-mode, so `global-ligature-mode' turns ligature-mode ON in org buffers but
;; nothing is registered for them and no ligature ever composes. Register the
;; prog-mode set for org-mode too. (Verified: this flips org-mode from no entry
;; in `ligature-composition-table' to a full one.)
(after! ligature
  (ligature-set-ligatures 'org-mode (alist-get 'prog-mode +ligatures-alist)))

;; ── Org export backends ──────────────────────────────────────────────────────
;; ox-pandoc  → export Org through pandoc (docx/epub/…); needs the `pandoc'
;;              binary (packages.nix).
;; ox-typst   → export Org to Typst markup / PDF; uses the `typst' binary
;;              (packages.nix).
;; Each registers its backend in the `SPC m e' / `C-c C-e' export dispatch on
;; load; `:after org' loads them when the first org buffer opens.
(use-package! ox-pandoc :after org)
(use-package! ox-typst  :after org)

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
