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

# Deploy to Firebase
firebase deploy --only hosting:iot-beer-token 