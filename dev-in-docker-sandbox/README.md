# 🐳 dev-in-docker-sandbox

A high-performance, isolated development environment tailored for Fedora and optimized for the Antigravity Agent. Create reproducible sandboxes for multiple languages with a single command.

## 🎯 Purpose

The sandbox ensures that your development activities remain isolated from your host system, providing:

- **Consistency**: The same environment every time.
- **Safety**: No cluttering of host system paths or configuration.
- **Performance**: Optimized for Fedora with SELinux compatibility (`:Z` flags).

## 🚀 Getting Started

### 1. Initialization

Place `setup-agent.sh` in your project folder and run:

```bash
chmod +x setup-agent.sh
./setup-agent.sh
```

### 2. Starting the Sandbox

You have two ways to start the environment:

**A. Automatic (Recommended)**

1.  Open the project folder in VS Code / Antigravity.
2.  When the pop-up appears ("Folder contains a Dev Container configuration"), click **Reopen in Container**.
3.  The IDE will build the image and connect automatically to `/workspace`.

**B. Manual Start**

1.  Run the following command in your terminal:
    ```bash
    docker-compose up -d --build
    ```
2.  In VS Code, press `F1` and select **Dev Containers: Attach to Running Container**.
3.  Choose **agent-dev-env**.
4.  **Important**: Once attached, go to **File > Open Folder** and enter `/workspace` to see your project files.

## 🛠️ Interactive Setup

The `setup-agent.sh` script is fully interactive. You will be prompted to:

1.  **Select Tools**: Choose to install **Python**, **Rust**, **npm (Node.js)**, or **Java**.
2.  **Choose Java Version**: If Java is selected, choose between JDK **21** or **25**.
3.  **Automatic Configuration**: The script handles `.antigravityignore`, `Dockerfile.dev`, `docker-compose.yml`, and `.devcontainer` setup.

## 📦 Available Tools

Depending on your selection, these tools are available:

- **Languages**: Python, Rust, Node.js (v20), Java (SDKMAN managed), Go (1.23).
- **Managers**: pip, cargo, npm, maven, gradle.

## 📂 Project Structure

- `Dockerfile.dev`: Custom container definition.
- `docker-compose.yml`: Orchestration for the sandbox.
- `.devcontainer/`: VS Code integration config.
- `USAGE_GUIDE.txt`: Quick-reference guide.

## 🛠️ Managing Versions

The environment uses SDKMAN! and nvm for flexible version management:

- **Java**: `sdk use java 25-tem` or `sdk use java 21.0.2-tem`
- **Node.js**: `nvm use 20` or `nvm install <version>`

## ⏹️ Stopping the Environment

To stop and remove containers (Clean shutdown):

```bash
docker-compose down
```

To just stop (Keep containers for faster start):

```bash
docker-compose stop
```

## 🔍 Troubleshooting (Fedora/SELinux)

If `/workspace` appears empty:

- Ensure the `:Z` flag is present in `docker-compose.yml` (added by the script by default).
- If the "Dev Containers" extension fails in non-Microsoft VS Code versions, consider installing the official VS Code RPM from Microsoft's repository.

## 🔒 Security Note

The agent is physically restricted to the `/workspace` directory. It cannot access your host's home directory, root filesystem, or other projects unless explicitly mounted.
