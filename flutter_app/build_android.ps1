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

# Build the Android app with all environment variables
Write-Host "Building with environment variables:"
$dartDefines | ForEach-Object { Write-Host $_ }

# Clean the build directory first
flutter clean

# Build release APK
flutter build apk --release $dartDefines

# Check if build was successful
if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    Write-Host "`nBuild successful! APK location: build/app/outputs/flutter-apk/app-release.apk"
} else {
    Write-Error "Build failed: APK not found"
    exit 1
} 