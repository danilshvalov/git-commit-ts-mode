# git-commit-ts-mode

A tree-sitter based major mode for editing Git commit messages in GNU Emacs.

![git-commit-ts-mode](https://github.com/danilshvalov/git-commit-ts-mode/assets/57654917/b5292190-651d-4794-abe1-6ac9702142ec)

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
  :elpaca (git-commit-ts-mode :host github
                              :repo "danilshvalov/git-commit-ts-mode")
  :mode "\\COMMIT_EDITMSG\\'")
```

### Magit integration

To use `git-commit-ts-mode` in the commit buffer, you need to change the value
of the `git-commit-major-mode` variable, for example, as follows:

```elisp
(setq git-commit-major-mode 'git-commit-ts-mode)
```
