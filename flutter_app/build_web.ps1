# Read environment variables from .env file
$envContent = Get-Content .env
$dartDefines = @()

foreach ($line in $envContent) {
    if ($line -match '^([^=]+)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2].Replace('"', '\"').Replace("'", "\'")  # Escape quotes
        $dartDefines += "--dart-define=$key=`"$value`""
    }
}

# Build the web app with all environment variables
Write-Host "Building with environment variables:"
$dartDefines | ForEach-Object { Write-Host $_ }

# Clean the build directory first
Remove-Item -Recurse -Force build/web -ErrorAction SilentlyContinue

# Build with all environment variables
flutter build web --release $dartDefines

# Verify the build
if (-not (Test-Path "build/web/main.dart.js")) {
    Write-Error "Build failed: main.dart.js not found"
    exit 1
}

# Create poc directory and move files
$pocDir = "build/web/poc"
New-Item -ItemType Directory -Force -Path $pocDir
Get-ChildItem -Path "build/web" -Exclude "poc" | Move-Item -Destination $pocDir

# Create index.html in root to redirect to poc
$redirectHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0;url=/poc/">
    <title>Redirecting...</title>
</head>
<body>
    <p>Redirecting to <a href="/poc/">/poc/</a>...</p>
</body>
</html>
"@
Set-Content -Path "build/web/index.html" -Value $redirectHtml

# Deploy to Firebase
firebase deploy --only hosting:iot-beer-token 