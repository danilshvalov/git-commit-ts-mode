(require 'treesit)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-child "treesit.c")

(defgroup git-commit nil
  "Git commit commands."
  :group 'extensions)

(defgroup git-commit-faces nil
  "Faces used by git commit."
  :group 'git-commit)

(defface git-commit-comment-face '((t :inherit font-lock-comment-face))
  "Face used for comments."
  :group 'git-commit-faces)

(defface git-commit-title-face '((t :inherit font-lock-string-face))
  "Face used for titles."
  :group 'git-commit-faces)

(defface git-commit-overflow-face '((t :inherit error))
  "Face used for titles."
  :group 'git-commit-faces)

(defface git-commit-prefix-face '((t :inherit font-lock-function-name-face))
  "Face used for prefixes."
  :group 'git-commit-faces)

(defface git-commit-type-face '((t :inherit font-lock-keyword-face))
  "Face used for types."
  :group 'git-commit-faces)

(defface git-commit-scope-face '((t :inherit font-lock-variable-name-face))
  "Face used for scope."
  :group 'git-commit-faces)

(defface git-commit-punctuation-delimiter-face '((t :inherit font-lock-punctuation-face))
  "Face used for punctuations."
  :group 'git-commit-faces)

(defface git-commit-punctuation-special-face '((t :inherit font-lock-warning-face))
  "Face used for punctuations."
  :group 'git-commit-faces)

(defface git-commit-token-face '((t :inherit font-lock-builtin-face))
  "Face used for tokens."
  :group 'git-commit-faces)

(defface git-commit-value-face '((t :inherit font-lock-variable-name-face))
  "Face used for values."
  :group 'git-commit-faces)

(defface git-commit-filepath-face '((t :inherit font-lock-variable-name-face))
  "Face used for filepath."
  :group 'git-commit-faces)

(defface git-commit-change-face '((t :inherit font-lock-builtin-face))
  "Face used for change."
  :group 'git-commit-faces)

(defface git-commit-branch-face '((t :inherit font-lock-keyword-face))
  "Face used for branch name."
  :group 'git-commit-faces)

(defvar git-commit--treesit-font-lock-settings
  (treesit-font-lock-rules
   :feature 'comment
   :language 'gitcommit
   '((comment) @git-commit-comment-face
     (generated_comment) @git-commit-comment-face
     (scissor) @git-commit-comment-face)

   :feature 'title
   :language 'gitcommit
   '((subject) @git-commit-title-face)

   :feature 'overflow
   :language 'gitcommit
   :override t
   '((subject
      (overflow) @git-commit-overflow-face))

   :feature 'prefix
   :language 'gitcommit
   :override t
   '((subject
      (subject_prefix) @git-commit-prefix-face))

   :feature 'prefix
   :language 'gitcommit
   :override t
   '((prefix
      (type) @git-commit-type-face)
     (prefix
      (scope) @git-commit-scope-face))

   :feature 'punctuation
   :language 'gitcommit
   :override t
   '((prefix
      ["(" ")" ":"] @git-commit-punctuation-delimiter-face)
     (prefix
      "!" @git-commit-punctuation-special-face)
     (arrow) @git-commit-punctuation-delimiter-face)

   :feature 'filepath
   :language 'gitcommit
   :override t
   '((filepath) @git-commit-filepath-face)

   :feature 'branch
   :language 'gitcommit
   :override t
   '((branch) @git-commit-branch-face)

   :feature 'change
   :language 'gitcommit
   :override t
   '((change) @git-commit-change-face)

   :feature 'token
   :language 'gitcommit
   :override t
   '((trailer
      (token) @git-commit-token-face)
     (trailer
      (value) @git-commit-value-face)
     (breaking_change
      (token) @git-commit-token-face)
     (breaking_change
      (value) @git-commit-value-face)
     (generated_comment
      (title) @git-commit-token-face)
     (generated_comment
      (value) @git-commit-value-face)))
  "Tree-sitter font-lock settings for `git-commit-ts-mode'.")

;;;###autoload
(define-derived-mode git-commit-ts-mode prog-mode "Git commit"
  (when (treesit-ready-p 'gitcommit)
    (treesit-parser-create 'gitcommit)
    (setq-local treesit-font-lock-settings git-commit--treesit-font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment title)
                  (token overflow)
                  (prefix branch change filepath)
                  (punctuation)))
    (treesit-major-mode-setup)
    (add-to-list 'auto-mode-alist '("\\.COMMIT_EDITMSG\\'" . git-commit-ts-mode))))

(provide 'git-commit-ts-mode)
