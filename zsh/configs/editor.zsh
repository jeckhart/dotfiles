VISUAL=vim
if type nvim > /dev/null 2>&1; then
  VISUAL=nvim
fi
EDITOR=$VISUAL
export VISUAL EDITOR
