# main taps - these are already theorically provided by strap
tap 'homebrew/core'
tap 'homebrew/bundle'
tap 'homebrew/services'
tap 'caskroom/cask'

# additional taps
tap 'thoughtbot/formulae'      # Required for gitsh and rcm
tap 'caskroom/fonts'
tap 'neovim/neovim'            # Neovim is a vim reimplentation. It's coming along but probably not a daily driver yet

# Early requirements
brew 'openssl'                    # Install a recent version of openssl as other homebrew apps will depend on this.

# Dotfiles
brew 'asdf'                       # Extendable version manager with support for Ruby, Node.js, Erlang & more
brew 'rcm'                        # Help manage your dotfiles

# Unix
brew 'ctags'                      # Used to index source files to make searching easier
brew 'git'                        # Git from Homebrew is newer than the version installed from macOS
brew 'gitsh'                      # An interactive shell for git
cask 'gitup'                      # Update multiple git repositories at once
brew 'gnu-tar'                    # Linux style tar command
brew 'lz4'                        # Support lz4 compressed artifacts
brew 'mas'                        # Command line client for mac app store. Used to automate installation of some apps
brew 'mosh'                       # Remote terminal application
brew 'reattach-to-user-namespace' # Reattach process (e.g., tmux) to background
brew 'ripgrep'                    # Search tool like grep and The Silver Searcher
brew 'the_silver_searcher'        # Faster than grep
brew 'tmux'                       # Keep a command-line open between terminal sessions (like 'screen')

# Command line tools
brew 'curlish'                    # Curl wrapper that adds oauth 2.0
brew 'fortune'                    # Dependency of Atom package fortune-background-tips
brew 'jq'                         # A command line client for dealing with json
brew 'todo-txt'                   # A command line todo app
brew 'watch'                      # Executes a program periodically, showing output fullscreen
brew 'watchman'                   # Watch for file changes
brew 'wget'                       # Command like http client (use curl when possible)
brew 'zsh'                        # A better command line interpretter. Like bash (and mostly bash compatible)

# GitHub and GitLab
tap 'zaquestion/tap'
brew 'hub'                        # hub is a command-line wrapper for git that makes you better at GitHub.
brew 'lab'                        # lab is a command-line wrapper for git that makes you better at GitLab.

# dev things and package managers
brew 'antigen'                    # Package manager and plugin manager for zsh
brew 'cmake'                      # Build tool for Makefiles
cask 'docker'                     # Container runtime
# brew 'docker-machine-driver-xhyve' # Docker Machine driver for xhyve
brew 'grpc'                       # The grpc command line client. GRPC is a modern RPC framework that we will use for services. It also brings in protobuf plugins for various languages we use.
brew 'imagemagick'                # Swiss army knife of image manipulation. However, it's a beast and should probably move into a docker container
brew 'libyaml'                    # should come after openssl
# brew 'nativefier'                 # Wrap web apps
# brew 'scons'                      # Build tool for scons files
brew 'wireshark'                  # Graphical network analyzer and capture tool
brew 'zeromq'                     # Native libs for zeromq bindings in various languages

# Machine learning tools
# brew 'libtensorflow'              # C interface for Google's OS library for Machine Intelligence
# brew 'opencv'                     # Open source computer vision library

# iOS dev tools
brew 'carthage'                   # Decentralized dependency manager for Cocoa
brew 'cocoapods'                  # Dependency manager for Cocoa projects

# Javascript/Typescript
brew 'nodenv'                     # Manage multiple versions of node
brew 'yarn'                       # An npm alternative that is stable (some of this was folded back into npm as of npm v5)
brew 'bower'                      # A frontend dependency manager

# Ruby
brew 'rbenv'                      # Manage multiple versions of ruby
brew 'ruby-build'                 # 

# Java/Scala/JVM
brew 'gradle'                     # Built tool and dependecy manager for Java (and other langs). Used for the Android app. Additionally, some tools we use are written in Java (Jenkins) so it's helpful when testing new versions or plugins.
brew 'jenv'                       # Manage multiple java environments
cask 'java' unless system "/usr/libexec/java_home --failfast"
brew 'maven'                      # Another java build tool. Used to build some libraries and tools
brew 'sbt'                        # Scala built tool

# Python
brew 'pipenv'                     # Manage multiple versions of through the use of a Pipfile
brew 'pyenv-virtualenvwrapper'    # Wrap virtualenv scripts to make then easy to use

# PHP
brew 'php@7.0'                    # For a recent version of php. This needs to be updated to 7.2

# Go
tap 'go-delve/delve'
brew 'delve'                      # Debugger for go programming language
brew 'go'                         # Many of our tools and plugins are written in go (k8s, gitlab CI, terraform, etc)

# DevOps
brew 'ansible'                    # Used to automate several devops systems
brew 'awscli'                     # AWS command line client
brew 'packer'                     # Create concise vm images for a variety of platforms. Very useful to create repeatable AWS EC2 AMI's.
brew 'terraform'                  # Manage our AWS infrastructure through code
brew 'kops'                       # Kubernetes provisioner for cloud environments
brew 'kubernetes-helm'            # Command line client for helm, a tool to simplify deploying infra on top of k8s
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
cask 'gpg-suite'
cask 'keybase' unless system "[[ -e /Applications/Keybase.app || -e /usr/local/bin/keybase ]]"                 # Command-line encryption tool
# cask 'viscosity'               # openvpn client

# Editors & IDEs
cask 'atom'                    # A solid multipurpose editor. Great for JS/TS projects
brew 'neovim'                  # Neovim is a vim reimplentation. It's coming along but probably not a daily driver yet
# brew 'vim'
# cask 'sublime-text'
cask 'visual-studio-code'      # Another solid multipurpose editor. Similar to Atom. Sometimes better at JavaScript and TypeScript
cask 'iterm2' unless system "[[ -e /Applications/iTerm.app ]]" # Better than the built in terminal program

# other apps
cask 'slack' unless system "[[ -e /Applications/Slack.app ]]"
# cask 'hipchat'
cask 'skype' unless system "[[ -e /Applications/Skype.app ]]"
# cask 'firefox'
cask 'licecap'
# cask 'grammarly'

# Fonts
cask 'font-menlo-for-powerline'
cask 'font-source-code-pro-for-powerline'
