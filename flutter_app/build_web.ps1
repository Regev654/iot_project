# Read environment variables from .env file
$envContent = Get-Content .env
$dartDefines = @()

foreach ($line in $envContent) {
    if ($line -match '^([^=]+)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2].Replace('"', '\"').Replace("'", "\'")
        $dartDefines += "--dart-define=$key=`"$value`""
    }
}

# Clean Flutter
Write-Host "Cleaning Flutter..."
flutter clean

# Get dependencies
Write-Host "Getting dependencies..."
flutter pub get

# Clean the build directory
Remove-Item -Recurse -Force build/web -ErrorAction SilentlyContinue

# Build with environment variables
Write-Host "Building web app..."
flutter build web --release $dartDefines

# Verify the build
if (-not (Test-Path "build/web/main.dart.js")) {
    Write-Error "Build failed: main.dart.js not found"
    exit 1
}

# Set up deploy directory
$deployDir = "build/deploy"
Remove-Item -Recurse -Force $deployDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$deployDir/v1" -Force

# Copy build to deploy/v1
Copy-Item -Recurse -Force "build/web/*" "$deployDir/v1"

# Create index.html with redirect in deploy root
$redirectHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0;url=/v1/">
    <title>Redirecting...</title>
</head>
<body>
    <p>Redirecting to <a href="/v1/">/v1/</a>...</p>
</body>
</html>
"@
Set-Content -Path "$deployDir/index.html" -Value $redirectHtml

# Configure Firebase hosting target
Write-Host "Configuring Firebase hosting target..."
firebase target:apply hosting iot-beer-token iot-beer-token

# Deploy to Firebase
Write-Host "Deploying to Firebase..."
firebase deploy --only hosting:iot-beer-token --force --project iot-beer-token
