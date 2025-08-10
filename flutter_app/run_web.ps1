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

# Run Flutter with environment variables
Write-Host "Running with environment variables:"
$dartDefines | ForEach-Object { Write-Host $_ }

# Clean the build directory first
Remove-Item -Recurse -Force build/web -ErrorAction SilentlyContinue

# Run with all environment variables (no --web-renderer)
flutter run -d chrome $dartDefines 