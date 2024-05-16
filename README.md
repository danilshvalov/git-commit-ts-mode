# git-commit-ts-mode

A tree-sitter based major mode for editing Git commit messages in GNU Emacs.

## Quick start

### Grammar installation

Evaluate the Lisp code below:

```elisp
(add-to-list 'treesit-language-source-alist
             '(gitcommit . ("https://github.com/gbprod/tree-sitter-gitcommit")))
```

Running `M-x treesit-install-language-grammar [RET] gitcommit` will compile and
install the latest [tree-sitter-gitcommit](https://github.com/gbprod/tree-sitter-gitcommit).

### Package installation

If you use [elpaca](https://github.com/progfolio/elpaca) and [use-package](https://github.com/jwiegley/use-package) to manage packages in Emacs, use the following
code to install `git-commit-ts-mode`:

```elisp
(use-package git-commit-ts-mode
  :elpaca (git-commit-ts-mode :repo "~/projects/git-commit-ts-mode")
  :mode "\\COMMIT_EDITMSG\\'")
```
