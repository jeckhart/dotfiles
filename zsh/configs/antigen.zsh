
source /usr/local/share/antigen/antigen.zsh
antigen use oh-my-zsh

if [ "$OSTYPE"="darwin15.0" ]; then
  antigen bundle osx
  antigen bundle brew
fi

antigen bundles <<EOBUNDLES
  fzf
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
  matthieusb/zsh-sdkman
EOBUNDLES

antigen theme gentoo

antigen apply

