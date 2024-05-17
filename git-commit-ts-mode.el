
;;; git-commit-ts-mode.el --- A tree-sitter based major mode for editing Git commit messages in GNU Emacs.

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
  "Face used for comments. Example:

   some commit message

   # this is my comment
   └──────────────────┘

The underlined text will be highlighted using `git-commit-comment-face'."
  :group 'git-commit-faces)

(defface git-commit-title-face '((t :inherit font-lock-string-face))
  "Face used for commit titles. Example:

   feat(some-module): some commit message
                      └────────┬────────┘
                         commit title

or:

   some commit message without prefix
   └───────────────┬────────────────┘
             commit title

The underlined text will be highlighted using `git-commit-title-face'."
  :group 'git-commit-faces)

(defface git-commit-overflow-face '((t :inherit error))
  "Face used for overflowed (> 50) commit titles. Example:

                     50 characters
   ┌───────────────────────┴────────────────────────┐
   feat(some-module): lorem ipsum dolor sit amet, consectetur adipiscing elit
                                                     └───────────┬──────────┘
                                                      overflowed commit title

The underlined text will be highlighted using `git-commit-overflow-face'."
  :group 'git-commit-faces)

(defface git-commit-prefix-face '((t :inherit font-lock-function-name-face))
  "Face used for commit prefixes. Example:

   refactor(some-module): some commit message
   └──────────┬─────────┘
        commit prefix

or:

   refactor: some commit message
   └───┬───┘
       └── commit prefix

The underlined text will be highlighted using `git-commit-prefix-face'."
  :group 'git-commit-faces)

(defface git-commit-type-face '((t :inherit font-lock-keyword-face))
  "Face used for commit prefix types. Example:

   refactor(some-module): some commit message
   └──┬───┘
      └── commit prefix type

or:

   refactor: some commit message
   └──┬───┘
      └── commit prefix type

The underlined text will be highlighted using `git-commit-type-face'."
  :group 'git-commit-faces)

(defface git-commit-scope-face '((t :inherit font-lock-variable-name-face))
  "Face used for commit prefix scopes. Example:

   refactor(some-module): some commit message
            └────┬────┘
        commit prefix scope

The underlined text will be highlighted using `git-commit-scope-face'."
  :group 'git-commit-faces)

(defface git-commit-punctuation-delimiter-face '((t :inherit font-lock-punctuation-face))
  "Face used for common punctuation delimiters. Example:

   refactor(some-module): some commit message
           ^           ^^
           └───────────┴┴─ common punctuation delimiters

The underlined with caret text will be highlighted using
`git-commit-punctuation-delimiter-face'."
  :group 'git-commit-faces)

(defface git-commit-punctuation-special-face '((t :inherit font-lock-warning-face))
  "Face used for special punctuation delimiters. Example:

   refactor(some-module)!: some commit message
                        ^
                        └── special punctuation delimiter

The underlined with caret text will be highlighted using
`git-commit-punctuation-special-face'."
  :group 'git-commit-faces)

(defface git-commit-token-face '((t :inherit font-lock-builtin-face))
  "Face used for tokens. Example:

   refactor(some-module): some commit message

   Closes: ABC-12345
   └──┬──┘
      └── token

The underlined text will be highlighted using `git-commit-token-face'."
  :group 'git-commit-faces)

(defface git-commit-value-face '((t :inherit font-lock-variable-name-face))
  "Face used for values. Example:

   refactor(some-module): some commit message

   Closes: ABC-12345
           └───┬───┘
             value

The underlined text will be highlighted using `git-commit-value-face'."
  :group 'git-commit-faces)

(defface git-commit-breaking-change-token-face '((t :inherit font-lock-warning-face))
  "Face used for breaking change tokens. Example:

   refactor(some-module): some commit message

   BREAKING CHANGE: everything is broken
   └──────┬───────┘
          └── breaking change token

The underlined text will be highlighted using
`git-commit-breaking-change-token-face'."
  :group 'git-commit-faces)

(defface git-commit-breaking-change-value-face '((t :inherit font-lock-variable-name-face))
  "Face used for breaking change values. Example:

   refactor(some-module): some commit message

   BREAKING CHANGE: everything is broken
                    └────────┬─────────┘
                   breaking change value

The underlined text will be highlighted using
`git-commit-breaking-change-value-face'."
  :group 'git-commit-faces)

(defface git-commit-filepath-face '((t :inherit font-lock-variable-name-face))
  "Face used for filepath. Example:

   # Please enter the commit message for your changes. Lines starting
   # with '#' will be ignored, and an empty message aborts the commit.
   #
   # On branch main
   # Changes to be committed:
   #	renamed:    some-file -> other-file
                    └───┬───┘    └───┬────┘
                        └─────┬──────┘
                          filepath
   #

The underlined text will be highlighted using `git-commit-filepath-face'."
  :group 'git-commit-faces)

(defface git-commit-change-face '((t :inherit font-lock-builtin-face))
  "Face used for changes. Example:

   # Please enter the commit message for your changes. Lines starting
   # with '#' will be ignored, and an empty message aborts the commit.
   #
   # On branch main
   # Changes to be committed:
   #	renamed:    some-file -> other-file
        └──┬───┘
           └── change
   #

The underlined text will be highlighted using `git-commit-change-face'."
  :group 'git-commit-faces)

(defface git-commit-branch-face '((t :inherit font-lock-keyword-face))
  "Face used for branch names. Example:

   # Please enter the commit message for your changes. Lines starting
   # with '#' will be ignored, and an empty message aborts the commit.
   #
   # On branch my-branch
               └───┬───┘
                   └── branch name
   # Changes to be committed:
   #	renamed:    some-file -> other-file
   #

The underlined text will be highlighted using `git-commit-branch-face'."
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
      (token) @git-commit-breaking-change-token-face)
     (breaking_change
      (value) @git-commit-breaking-change-value-face)
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

;;; git-commit-ts-mode.el ends here
