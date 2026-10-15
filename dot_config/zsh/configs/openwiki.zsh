# openwiki: LangChain's repo-documentation CLI. Credentials, the personal wiki,
# connector data, conversation history and skills all live in one directory —
# mutable data, so XDG_DATA_HOME rather than ~/.config despite the var's name.
export OPENWIKI_CONFIG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/openwiki"
