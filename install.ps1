$APP_NAME = "rune"
$REPO_URL = "https://github.com/rune-runtime/rune"
$ASSET_BASE_URL = "https://github.com/rune-runtime/rune/releases/download"
$INSTALL_DIR = "$env:ProgramFiles\rune"

function Download-And-Extract {

    Write-Host "Fetching the latest release tag from $REPO_URL..."
    $LATEST_TAG = (git ls-remote --tags --sort="v:refname" $REPO_URL | Select-String -Pattern "refs/tags/" | ForEach-Object { $_.ToString().Split('/')[-1] } | Select-Object -Last 1)
    Write-Host "Latest release tag: $LATEST_TAG"

    $TARBALL_URL = "$ASSET_BASE_URL/$LATEST_TAG/$APP_NAME-cli-$LATEST_TAG-windows-x86_64.tar.gz"
    $TMP_DIR = "$env:TEMP\$APP_NAME-$LATEST_TAG"
    
    New-Item -Path $TMP_DIR -ItemType Directory -Force

    Write-Host "Downloading tarball from $TARBALL_URL..."
    Invoke-WebRequest -Uri $TARBALL_URL -OutFile "$TMP_DIR\$APP_NAME.tar.gz"

    Write-Host "Extracting tarball..."
    tar -xzf "$TMP_DIR\$APP_NAME.tar.gz" -C $TMP_DIR
    Remove-Item -Path "$TMP_DIR\$APP_NAME.tar.gz" -Force

    Write-Host "Moving the binary to $INSTALL_DIR..."
    if (-Not (Test-Path $INSTALL_DIR)) {
        New-Item -Path $INSTALL_DIR -ItemType Directory -Force
    }
    Move-Item -Path "$TMP_DIR\*" -Destination $INSTALL_DIR

    $EXE_PATH = Join-Path -Path $INSTALL_DIR -ChildPath "$APP_NAME.exe"
    if (Test-Path $EXE_PATH) {
        Write-Host "$APP_NAME installed successfully at $INSTALL_DIR"
    } else {
        Write-Host "Installation failed."
    }

    Write-Host "Cleaning up temporary files..."
    Remove-Item -Path $TMP_DIR -Recurse -Force
}

function Add-InstallDir-To-Path {
    $envPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($envPath -notcontains $INSTALL_DIR) {
        Write-Host "Adding $INSTALL_DIR to the User PATH..."
        [System.Environment]::SetEnvironmentVariable("PATH", "$envPath;$INSTALL_DIR", "User")
        Write-Host "$INSTALL_DIR added to PATH. Please restart your terminal for the changes to take effect."
    } else {
        Write-Host "$INSTALL_DIR is already in the PATH."
    }
}

Download-And-Extract
Add-InstallDir-To-Path