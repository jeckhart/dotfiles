# main taps - these are already theorically provided by strap
tap 'homebrew/bundle'
tap 'homebrew/services'

# additional taps
tap 'thoughtbot/formulae'         # Required for gitsh
# tap 'homebrew/cask-fonts'

# Early requirements
brew 'openssl'                    # Install a recent version of openssl as other homebrew apps will depend on this.

# Dotfiles
brew 'asdf'                       # Extendable version manager with support for Ruby, Node.js, Erlang & more
brew 'rcm'                        # Help manage your dotfiles
brew 'socat'                      # Used primarily in WSL to link/share ssh-agent from windows

# Unix
# brew 'git'                        # Git from Homebrew is newer than the version installed from macOS
# brew 'gitsh' if OS.mac?           # An interactive shell for git
# cask 'gitup'                      # Update multiple git repositories at once
# brew 'gnu-tar'                    # Linux style tar command
# brew 'lz4'                        # Support lz4 compressed artifacts
# brew 'mas' if OS.mac?             # Command line client for mac app store. Used to automate installation of some apps
# brew 'mosh'                       # Remote terminal application
# brew 'reattach-to-user-namespace' if OS.mac? # Reattach process (e.g., tmux) to background
# brew 'the_silver_searcher'        # Faster than grep
brew 'ctags'                      # Used to index source files to make searching easier
brew 'ripgrep'                    # Search tool like grep and The Silver Searcher
brew 'tmux'                       # Keep a command-line open between terminal sessions (like 'screen')

# Command line tools
# brew 'fortune'                    # Dependency of Atom package fortune-background-tips
# brew 'todo-txt'                   # A command line todo app
# brew 'watchman'                   # Watch for file changes
brew 'fzf'                        # Commandline line fuzzy finder
brew 'jq'                         # A command line client for dealing with json
brew 'watch'                      # Executes a program periodically, showing output fullscreen
brew 'wget'                       # Command like http client (use curl when possible)
brew 'bat'                        # cat with wings

# VCS
# Note: there is also a version that works with GitLab in cask 'zaquestion/tap'
# brew 'hub'                        # hub is a command-line wrapper for git that makes you better at GitHub.
brew 'pre-commit'                 # Add pre-commit hooks to enable cleaner CI runs

# dev things and package managers
# brew 'bazel' if OS.mac?           # Googles build tool. Works well with monorepos
# cask 'docker' unless system "[ -e /Applications/Docker.app ]" # Container runtime
# brew 'grpc' if OS.mac?            # The grpc command line client. GRPC is a modern RPC framework that we will use for services. It also brings in protobuf plugins for various languages we use.
# brew 'imagemagick'                # Swiss army knife of image manipulation. However, it's a beast and should probably move into a docker container
# brew 'nativefier'                 # Wrap web apps
# brew 'scons'                      # Build tool for scons files
# brew 'wireshark'                  # Graphical network analyzer and capture tool
# brew 'zeromq'                     # Native libs for zeromq bindings in various languages
brew 'antigen'                    # Package manager and plugin manager for zsh
brew 'cmake'                      # Build tool for Makefiles
brew 'direnv'                     # Read env config from files in your dir
brew 'libyaml'                    # should come after openssl

# Machine learning tools
# brew 'libtensorflow'              # C interface for Google's OS library for Machine Intelligence
# brew 'opencv'                     # Open source computer vision library

# iOS dev tools
# brew 'carthage' if OS.mac?        # Decentralized dependency manager for Cocoa
# brew 'cocoapods'                  # Dependency manager for Cocoa projects

# Javascript/Typescript
brew 'nodenv'                     # Manage multiple versions of node
brew 'pnpm'                       # An npm alternative that is fast

# Ruby
# brew 'rbenv'                      # Manage multiple versions of ruby
# brew 'ruby-build'                 # 

# Java/Scala/JVM
# cask 'java' unless system "/usr/libexec/java_home --failfast" # Moved to asdf
brew 'gradle'                     # Built tool and dependecy manager for Java (and other langs). Used for the Android app. Additionally, some tools we use are written in Java (Jenkins) so it's helpful when testing new versions or plugins.
brew 'maven'                      # Another java build tool. Used to build some libraries and tools
# brew 'sbt'                        # Scala built tool

# Python
# brew 'pyenv-virtualenvwrapper'    # Wrap virtualenv scripts to make then easy to use
brew 'pipenv'                     # Manage multiple versions of through the use of a Pipfile
brew 'poetry'                     # Python package management tool
brew 'pyenv'                      # Install multiple versions of python
brew 'pyenv-virtualenv'           # Support multiple workspaces with different versions of python

# Go
# tap 'go-delve/delve'
# brew 'delve'                      # Debugger for go programming language
brew 'go'                         # Many of our tools and plugins are written in go (k8s, gitlab CI, terraform, etc)

# Rust
brew 'rust'
brew 'cargo-deny'
brew 'cargo-generate'
brew 'cargo-make'
brew 'cargo-nextest'

# DevOps
# brew 'packer'                     # Create concise vm images for a variety of platforms. Very useful to create repeatable AWS EC2 AMI's.
# brew 'terraform'                  # Manage our AWS/GCE/K8S/etc infrastructure through code
brew 'awscli' unless system "[ -e /usr/local/bin/aws ]" # AWS command line client
brew 'opentofu'                  # Manage our AWS/GCE/K8S/etc infrastructure through code
brew 'kops'                       # Kubernetes provisioner for cloud environments
brew 'testssl'                    # Test various compliance issues with SSL endpoints


# Databases
# cask 'postgres'
# cask 'mysql'

# Database GUI
# cask 'postico'
# cask 'querious'
# cask 'sequel-pro'

# Security
# cask 'cloak'                   # like google wifi vpn
# cask 'keybase' unless system "[ -e /Applications/Keybase.app ] || [ -e /usr/local/bin/keybase ]"                 # Command-line encryption tool
# cask 'viscosity'               # openvpn client
cask 'gpg-suite'

# Editors & IDEs
# cask 'visual-studio-code' unless "[ -e /Applications/Visual\ Studio\ Code.app ]" # At this point the defacto multipurpose editor.
brew 'neovim'                  # Neovim is a vim reimplentation. It's stable enough to replace vim
cask 'iterm2' unless system "[ -e /Applications/iTerm.app ]" # Better than the built in terminal program

# other apps
# cask 'slack' unless system "[ -e /Applications/Slack.app ]"
# cask 'firefox'
# cask 'licecap'
# cask 'grammarly'

# Fonts
cask 'font-menlo-for-powerline'
cask 'font-meslo-lg-nerd-font'

