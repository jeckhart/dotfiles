# awesome cd movements from zshkit. The directory stack (AUTO_PUSHD et al.) gives
# within-session back-tracking; `d` lists it and `1`-`9` jump by index (aliases.zsh).
# (zoxide is the complementary cross-session frecency jumper.)
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=20

# Enable extended globbing
setopt extendedglob

# Allow [ or ] whereever you want
unsetopt nomatch
