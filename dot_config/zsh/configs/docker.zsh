# Redirect Docker's config dir to XDG_CONFIG_HOME. Docker has no native XDG
# support — DOCKER_CONFIG is the only lever it exposes.
export DOCKER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/docker"
