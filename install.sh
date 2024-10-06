#!/bin/bash

APP_NAME="rune"
REPO_URL="https://github.com/rune-runtime/rune"
ASSET_BASE_URL="https://github.com/rune-runtime/rune/releases/download"
INSTALL_DIR="/opt/rune"

detect_architecture() {
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "arm64"
    else
        echo "x86_64"
    fi
}

detect_os() {
    case "$OSTYPE" in
        linux*)   echo "linux";;
        darwin*)  echo "macos";;
        *)        echo "unsupported";;
    esac
}

download_and_extract() {
    ARCH=$(detect_architecture)
    OS=$(detect_os)

    echo "Fetching the latest release tag from $REPO_URL..."
    LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$REPO_URL" | grep -v '\^{}' | tail -n1 | sed 's/.*\///')
    echo "Latest release tag: $LATEST_TAG"

    TARBALL_URL="$ASSET_BASE_URL/$LATEST_TAG/$APP_NAME-cli-$LATEST_TAG-$OS-$ARCH.tar.gz"
    
    TMP_DIR="/tmp/$APP_NAME-$LATEST_TAG"
    mkdir -p "$TMP_DIR"
    
    echo "Downloading tarball from $TARBALL_URL..."
    curl -L "$TARBALL_URL" -o "$TMP_DIR/$APP_NAME.tar.gz"

    echo "Extracting tarball..."
    tar -xzf "$TMP_DIR/$APP_NAME.tar.gz" -C "$TMP_DIR"
    rm -rf "$TMP_DIR/$APP_NAME.tar.gz"

    echo "Moving the binary to $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo mv "$TMP_DIR"/* "$INSTALL_DIR/"

    sudo mv "$INSTALL_DIR/$APP_NAME-cli" "$INSTALL_DIR/$APP_NAME" 
    sudo chmod +x "$INSTALL_DIR/$APP_NAME"

    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"

    echo "$APP_NAME installed successfully at $INSTALL_DIR"
}

add_install_dir_to_path() {
    SHELL_NAME=$(basename "$SHELL")

    echo "Detected shell: $SHELL_NAME"

    case "$SHELL_NAME" in
        bash)
            CONFIG_FILE="$HOME/.bashrc"
            ;;
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            ;;
        *)
            echo "Unsupported shell: $SHELL_NAME"
            echo "Please manually add $INSTALL_DIR to your PATH."
            return
            ;;
    esac

    if grep -qs "$INSTALL_DIR" "$CONFIG_FILE"; then
        echo "$INSTALL_DIR is already in your PATH."
    else
        echo "Adding $INSTALL_DIR to your PATH in $CONFIG_FILE..."
        echo "" >> "$CONFIG_FILE"
        echo "# Added by $APP_NAME installer on $(date)" >> "$CONFIG_FILE"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$CONFIG_FILE"
        echo "Please restart your terminal or run 'source $CONFIG_FILE' to apply the changes."
    fi
}

download_and_extract

add_install_dir_to_path

if command -v $APP_NAME &> /dev/null; then
    echo "$APP_NAME is successfully installed and ready to use."
else
    echo "Installation failed."
    exit 1
fi
