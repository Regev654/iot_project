# Read environment variables from .env file
$envContent = Get-Content .env
$dartDefines = @()

# Verify required environment variables
$requiredVars = @(
    "FIREBASE_API_KEY",
    "FIREBASE_AUTH_DOMAIN",
    "FIREBASE_PROJECT_ID",
    "FIREBASE_STORAGE_BUCKET",
    "FIREBASE_MESSAGING_SENDER_ID",
    "FIREBASE_APP_ID",
    "FIREBASE_DATABASE_URL"
)

$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not ($envContent -match "^$var=")) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Error "Missing required environment variables in .env file:"
    $missingVars | ForEach-Object { Write-Error "- $_" }
    exit 1
}

# Build dart defines
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
Write-Host "Building web app with environment variables:"
$dartDefines | ForEach-Object { Write-Host $_ }

# Build with all environment variables
Write-Host "Building web app..."
flutter build web --release $dartDefines

# Verify the build
if (-not (Test-Path "build/web/main.dart.js")) {
    Write-Error "Build failed: main.dart.js not found"
    exit 1
}

# Deploy to Firebase
Write-Host "Deploying to Firebase..."
firebase deploy --only hosting:iot-beer-token-98fce --force --project iot-beer-token
