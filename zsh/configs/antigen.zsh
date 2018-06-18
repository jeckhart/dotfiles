
source /usr/local/share/antigen/antigen.zsh
antigen use oh-my-zsh

if [ "$OSTYPE"="darwin15.0" ]; then
  antigen bundle osx
  antigen bundle brew
fi

antigen bundles <<EOBUNDLES
  git
  git-extras
  pip
  colored-man-pages
  gnu-utils
  history
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
  nojhan/liquidprompt
  kubectl
EOBUNDLES

antigen theme gentoo

antigen apply

