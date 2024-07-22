;;; git-commit-ts-mode.el --- Tree-sitter support for Git commit messages -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Daniil Shvalov

;; Author: Daniil Shvalov <daniil.shvalov@gmail.com>
;; Version: 1.0
;; Package-Requires: ((emacs "29.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: tree-sitter, git, faces
;; Homepage: https://github.com/danilshvalov/git-commit-ts-mode

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A tree-sitter based major mode for editing Git commit messages in GNU Emacs

;;; Code:
(require 'treesit)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-child "treesit.c")

(defgroup git-commit-ts nil
  "Git commit commands."
  :group 'extensions)

(defgroup git-commit-ts-faces nil
  "Faces used by git commit."
  :group 'git-commit-ts)

(defcustom git-commit-ts-max-message-size 72
  "The maximum allowed commit message size. If the specified limit is exceeded,
the rest of the message will be highlighted using
`git-commit-ts-overflow-face'."
  :type 'integer
  :safe 'integerp
  :group 'git-commit-ts)

(defface git-commit-ts-comment-face '((t :inherit font-lock-comment-face))
  "Face used for comments. Example:

   some commit message

   # this is my comment
   └──────────────────┘

The underlined text will be highlighted using `git-commit-ts-comment-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-title-face '((t :inherit font-lock-string-face))
  "Face used for commit titles. Example:

   feat(some-module): some commit message
                      └────────┬────────┘
                         commit title

or:

   some commit message without prefix
   └───────────────┬────────────────┘
             commit title

The underlined text will be highlighted using `git-commit-ts-title-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-overflow-face '((t :inherit error))
  "Face used for overflowed (> 50) commit titles. Example:

                     50 characters
   ┌───────────────────────┴────────────────────────┐
   feat(some-module): lorem ipsum dolor sit amet, consectetur adipiscing elit
                                                     └───────────┬──────────┘
                                                      overflowed commit title

The underlined text will be highlighted using `git-commit-ts-overflow-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-prefix-face '((t :inherit font-lock-function-name-face))
  "Face used for commit prefixes. Example:

   refactor(some-module): some commit message
   └──────────┬─────────┘
        commit prefix

or:

   refactor: some commit message
   └───┬───┘
       └── commit prefix

The underlined text will be highlighted using `git-commit-ts-prefix-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-type-face '((t :inherit font-lock-keyword-face))
  "Face used for commit prefix types. Example:

   refactor(some-module): some commit message
   └──┬───┘
      └── commit prefix type

or:

   refactor: some commit message
   └──┬───┘
      └── commit prefix type

The underlined text will be highlighted using `git-commit-ts-type-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-scope-face '((t :inherit font-lock-variable-name-face))
  "Face used for commit prefix scopes. Example:

   refactor(some-module): some commit message
            └────┬────┘
        commit prefix scope

The underlined text will be highlighted using `git-commit-ts-scope-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-punctuation-delimiter-face '((t :inherit font-lock-punctuation-face))
  "Face used for common punctuation delimiters. Example:

   refactor(some-module): some commit message
           ^           ^^
           └───────────┴┴─ common punctuation delimiters

The underlined with caret text will be highlighted using
`git-commit-ts-punctuation-delimiter-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-punctuation-special-face '((t :inherit font-lock-warning-face))
  "Face used for special punctuation delimiters. Example:

   refactor(some-module)!: some commit message
                        ^
                        └── special punctuation delimiter

The underlined with caret text will be highlighted using
`git-commit-ts-punctuation-special-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-token-face '((t :inherit font-lock-builtin-face))
  "Face used for tokens. Example:

   refactor(some-module): some commit message

   Closes: ABC-12345
   └──┬──┘
      └── token

The underlined text will be highlighted using `git-commit-ts-token-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-value-face '((t :inherit font-lock-variable-name-face))
  "Face used for values. Example:

   refactor(some-module): some commit message

   Closes: ABC-12345
           └───┬───┘
             value

The underlined text will be highlighted using `git-commit-ts-value-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-breaking-change-token-face '((t :inherit font-lock-warning-face))
  "Face used for breaking change tokens. Example:

   refactor(some-module): some commit message

   BREAKING CHANGE: everything is broken
   └──────┬───────┘
          └── breaking change token

The underlined text will be highlighted using
`git-commit-ts-breaking-change-token-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-breaking-change-value-face '((t :inherit font-lock-variable-name-face))
  "Face used for breaking change values. Example:

   refactor(some-module): some commit message

   BREAKING CHANGE: everything is broken
                    └────────┬─────────┘
                   breaking change value

The underlined text will be highlighted using
`git-commit-ts-breaking-change-value-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-filepath-face '((t :inherit font-lock-variable-name-face))
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

The underlined text will be highlighted using `git-commit-ts-filepath-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-change-face '((t :inherit font-lock-builtin-face))
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

The underlined text will be highlighted using `git-commit-ts-change-face'."
  :group 'git-commit-ts-faces)

(defface git-commit-ts-branch-face '((t :inherit font-lock-keyword-face))
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

The underlined text will be highlighted using `git-commit-ts-branch-face'."
  :group 'git-commit-ts-faces)

(defun git-commit-ts--fontify-title (node _ _ _ &rest _)
  (let* ((start (treesit-node-start node))
         (end (treesit-node-end node))
         (length (- end start))
         (separator (+ start git-commit-ts-max-message-size 1)))
    (if (<= length git-commit-ts-max-message-size)
        (treesit-fontify-with-override start end 'git-commit-ts-title-face nil)
      (treesit-fontify-with-override start separator 'git-commit-ts-title-face nil)
      (treesit-fontify-with-override separator end 'git-commit-ts-overflow-face t))))

(defvar git-commit-ts-font-lock-settings
  (treesit-font-lock-rules
   :feature 'comment
   :language 'gitcommit
   '((comment) @git-commit-ts-comment-face
     (generated_comment) @git-commit-ts-comment-face
     (scissor) @git-commit-ts-comment-face)

   :feature 'title
   :language 'gitcommit
   '((subject) @git-commit-ts--fontify-title)

   :feature 'prefix
   :language 'gitcommit
   :override t
   '((subject
      (subject_prefix) @git-commit-ts-prefix-face))

   :feature 'prefix
   :language 'gitcommit
   :override t
   '((prefix
      (type) @git-commit-ts-type-face)
     (prefix
      (scope) @git-commit-ts-scope-face))

   :feature 'punctuation
   :language 'gitcommit
   :override t
   '((prefix
      ["(" ")" ":"] @git-commit-ts-punctuation-delimiter-face)
     (prefix
      "!" @git-commit-ts-punctuation-special-face)
     (arrow) @git-commit-ts-punctuation-delimiter-face)

   :feature 'filepath
   :language 'gitcommit
   :override t
   '((filepath) @git-commit-ts-filepath-face)

   :feature 'branch
   :language 'gitcommit
   :override t
   '((branch) @git-commit-ts-branch-face)

   :feature 'change
   :language 'gitcommit
   :override t
   '((change) @git-commit-ts-change-face)

   :feature 'token
   :language 'gitcommit
   :override t
   '((trailer
      (token) @git-commit-ts-token-face)
     (trailer
      (value) @git-commit-ts-value-face)
     (breaking_change
      (token) @git-commit-ts-breaking-change-token-face)
     (breaking_change
      (value) @git-commit-ts-breaking-change-value-face)
     (generated_comment
      (title) @git-commit-ts-token-face)
     (generated_comment
      (value) @git-commit-ts-value-face)))
  "Tree-sitter font-lock settings for `git-commit-ts-mode'.")

;;;###autoload
(define-derived-mode git-commit-ts-mode prog-mode "Git commit"
  (when (treesit-ready-p 'gitcommit)
    (treesit-parser-create 'gitcommit)
    (setq-local treesit-font-lock-settings git-commit-ts-font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment title)
                  (token overflow)
                  (prefix branch change filepath)
                  (punctuation)))
    (treesit-major-mode-setup)
    (add-to-list 'auto-mode-alist '("\\.COMMIT_EDITMSG\\'" . git-commit-ts-mode))))

(provide 'git-commit-ts-mode)

;;; git-commit-ts-mode.el ends here
