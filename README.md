# git-commit-ts-mode

A tree-sitter based major mode for editing Git commit messages in GNU Emacs.

## Quick start

Evaluate the Lisp code below:

```elisp
(add-to-list 'treesit-language-source-alist
             '(gitcommit . ("https://github.com/gbprod/tree-sitter-gitcommit")))
```

Running `M-x treesit-install-language-grammar [RET] gitcommit` will compile and
install the latest [tree-sitter-gitcommit](https://github.com/gbprod/tree-sitter-gitcommit).
