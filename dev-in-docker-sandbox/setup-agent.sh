#!/bin/bash

# --- Color configuration ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Fedora-optimized Antigravity Agent environment setup...${NC}"

# --- Tool Selection ---
echo -e "${BLUE}Select tools to install in the sandbox:${NC}"

ask_yes_no() {
    local prompt=$1
    local default=$2
    local answer
    read -p "$prompt (y/n, default: $default): " answer
    answer=${answer:-$default}
    [[ "$answer" =~ ^[Yy]$ ]]
}

INSTALL_PYTHON=$(ask_yes_no "Install Python?" "y" && echo "true" || echo "false")
INSTALL_RUST=$(ask_yes_no "Install Rust?" "y" && echo "true" || echo "false")
INSTALL_NPM=$(ask_yes_no "Install npm (Node.js)?" "y" && echo "true" || echo "false")
INSTALL_JAVA=$(ask_yes_no "Install Java?" "y" && echo "true" || echo "false")

JAVA_VERSION=""
if [ "$INSTALL_JAVA" == "true" ]; then
    while true; do
        read -p "Which Java JDK version to install? (21 or 25): " JAVA_VERSION
        if [[ "$JAVA_VERSION" == "21" || "$JAVA_VERSION" == "25" ]]; then
            break
        else
            echo -e "${BLUE}Please enter 21 or 25.${NC}"
        fi
    done
fi

# 1. Create .antigravityignore
echo -e "Creating ${GREEN}.antigravityignore${NC}..."
cat << EOF > .antigravityignore
# --- Secrets and Sensitive Data ---
.env
.env.*
*.pem
*.key
.ssh/
secrets.json
credentials.json
secrets/

# --- System Paths and Logs ---
/etc/
/var/
/usr/
/bin/
~/.bashrc
~/.zshrc
~/.config/

# --- NodeJS / TypeScript ---
node_modules/
dist/
build/
.npm/

# --- Python ---
__pycache__/
.venv/
env/
venv/
*.pyc

# --- Java / Kotlin / Maven / Gradle ---
target/
build/
.gradle/
.m2/
bin/
*.class

# --- C++ / CMake ---
out/
debug/
release/
CMakeFiles/
CMakeCache.txt

# --- Logs and IDE ---
*.log
.git/
.idea/
.vscode/
.DS_Store

# --- Parent Directory Lock ---
../**/
EOF

# 2. Create Dockerfile.dev
echo -e "Creating ${GREEN}Dockerfile.dev${NC}..."
cat << EOF > Dockerfile.dev
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \\
    curl wget git build-essential software-properties-common \\
    unzip zip ca-certificates sudo \\
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash developer \\
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER developer
WORKDIR /home/developer
EOF

if [ "$INSTALL_JAVA" == "true" ]; then
    cat << EOF >> Dockerfile.dev

# --- Install SDKMAN! (Java $JAVA_VERSION, Maven, Gradle) ---
ENV SDKMAN_DIR=/home/developer/.sdkman
RUN curl -s "https://get.sdkman.io" | bash \\
    && bash -c "source \$SDKMAN_DIR/bin/sdkman-init.sh && \\
       sdk install java ${JAVA_VERSION}.0.2-tem && \\
       sdk default java ${JAVA_VERSION}.0.2-tem && \\
       sdk install maven && \\
       sdk install gradle"
EOF
fi

if [ "$INSTALL_NPM" == "true" ]; then
    cat << EOF >> Dockerfile.dev

# --- Install nvm (Node.js & npm) ---
ENV NVM_DIR=/home/developer/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \\
    && bash -c "source \$NVM_DIR/nvm.sh && \\
       nvm install 20 && \\
       nvm alias default 20 && \\
       npm install -g typescript ts-node"
EOF
fi

if [ "$INSTALL_PYTHON" == "true" ]; then
    cat << EOF >> Dockerfile.dev

# --- Language: Python ---
USER root
RUN apt-get update && apt-get install -y \\
    python3 python3-pip python3-venv \\
    && rm -rf /var/lib/apt/lists/*
USER developer
EOF
fi

# --- Language: Go ---
cat << EOF >> Dockerfile.dev
USER root
COPY --from=golang:1.23-bookworm /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:\${PATH}"
USER developer
EOF

if [ "$INSTALL_RUST" == "true" ]; then
    cat << EOF >> Dockerfile.dev

# --- Language: Rust ---
USER developer
ENV RUSTUP_HOME=/home/developer/.rustup \\
    CARGO_HOME=/home/developer/.cargo \\
    PATH=/home/developer/.cargo/bin:\$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
EOF
fi

# Final Dockerfile.dev additions
cat << EOF >> Dockerfile.dev

# --- Final Environment Paths ---
$( [ "$INSTALL_JAVA" == "true" ] && echo "ENV PATH=\"/home/developer/.sdkman/candidates/java/current/bin:/home/developer/.sdkman/candidates/maven/current/bin:/home/developer/.sdkman/candidates/gradle/current/bin:\${PATH}\"" )
$( [ "$INSTALL_NPM" == "true" ] && echo "ENV PATH=\"/home/developer/.nvm/versions/node/v20.11.1/bin:\${PATH}\"" )

WORKDIR /workspace
ENV DEV_CONTAINER=true
CMD ["bash"]
EOF

# 3. Create docker-compose.yml (With SELinux :Z fix)
echo -e "Creating ${GREEN}docker-compose.yml${NC}..."
cat << EOF > docker-compose.yml
services:
  agent-sandbox:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: agent-dev-env
    volumes:
      # :Z is crucial for Fedora/SELinux compatibility
      - .:/workspace:Z
      - bash_history:/home/developer/.bash_history:Z
    working_dir: /workspace
    stdin_open: true
    tty: true
    deploy:
      resources:
        limits:
          memory: 4G

volumes:
  bash_history:
EOF

# 4. Create .devcontainer/devcontainer.json
echo -e "Creating ${GREEN}.devcontainer/devcontainer.json${NC}..."
mkdir -p .devcontainer
cat << EOF > .devcontainer/devcontainer.json
{
    "name": "Antigravity Secure Sandbox",
    "dockerComposeFile": "../docker-compose.yml",
    "service": "agent-sandbox",
    "workspaceFolder": "/workspace",
    "customizations": {
        "vscode": {
            "settings": {
                "terminal.integrated.defaultProfile.linux": "bash"
            },
            "extensions": [
                "ms-python.python",
                "vscjava.vscode-java-pack",
                "golang.go"
            ]
        }
    },
    "remoteUser": "developer"
}
EOF

# 5. Create USAGE_GUIDE.txt
echo -e "Creating ${GREEN}USAGE_GUIDE.txt${NC}..."
cat << EOF > USAGE_GUIDE.txt
# --- ANTIGRAVITY AGENT SANDBOX GUIDE (FEDORA OPTIMIZED) ---

1. AUTOMATIC CONNECTION (Recommended)
   - Open this folder in VS Code / Antigravity.
   - Click "Reopen in Container" when prompted.
   - The IDE will open /workspace with files visible (SELinux :Z enabled).

2. MANUAL START (If needed)
   - docker-compose up -d --build
   - Then use 'Attach to Running Container' -> 'agent-dev-env'.

3. HOW TO STOP
   - docker-compose down

4. INSTALLED TOOLS
$( [ "$INSTALL_JAVA" == "true" ] && echo "   - JAVA ($JAVA_VERSION)" )
$( [ "$INSTALL_NPM" == "true" ] && echo "   - NODE (20)" )
$( [ "$INSTALL_PYTHON" == "true" ] && echo "   - PYTHON" )
$( [ "$INSTALL_RUST" == "true" ] && echo "   - RUST" )
   - GO
EOF

echo -e "${GREEN}Done!${NC} Your Fedora-optimized environment is ready."
