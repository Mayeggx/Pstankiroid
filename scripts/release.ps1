$ErrorActionPreference = "Stop"

param(
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [int]$VersionCode,
    [string]$BuildTask = "assembleDebug",
    [switch]$SkipBuild,
    [switch]$SkipPush,
    [string]$Branch = "main"
)

. "$PSScriptRoot\use-e-drive-android-env.ps1"

$projectRoot = Split-Path $PSScriptRoot -Parent
$gradleFile = Join-Path $projectRoot "app\build.gradle.kts"
$apkPath = Join-Path $projectRoot "app\build\outputs\apk\debug\app-debug.apk"
$tagName = "v$VersionName"

function Read-VersionInfo {
    param([string]$Content)

    $versionNameMatch = [regex]::Match($Content, 'versionName\s*=\s*"([^"]+)"')
    $versionCodeMatch = [regex]::Match($Content, 'versionCode\s*=\s*(\d+)')

    if (-not $versionNameMatch.Success -or -not $versionCodeMatch.Success) {
        throw "Failed to read versionName/versionCode from $gradleFile"
    }

    return [pscustomobject]@{
        VersionName = $versionNameMatch.Groups[1].Value
        VersionCode = [int]$versionCodeMatch.Groups[1].Value
    }
}

Push-Location $projectRoot
try {
    $statusBefore = (& git status --short)
    if ($statusBefore) {
        throw "Git worktree is not clean. Commit or stash existing changes before running release.ps1."
    }

    $content = Get-Content $gradleFile -Raw
    $current = Read-VersionInfo -Content $content

    if (-not $PSBoundParameters.ContainsKey("VersionCode")) {
        $VersionCode = $current.VersionCode + 1
    }

    $updated = $content
    $updated = [regex]::Replace($updated, 'versionName\s*=\s*"([^"]+)"', "versionName = `"$VersionName`"", 1)
    $updated = [regex]::Replace($updated, 'versionCode\s*=\s*(\d+)', "versionCode = $VersionCode", 1)

    if ($updated -ne $content) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Resolve-Path $gradleFile), $updated, $utf8NoBom)
    }

    $after = Read-VersionInfo -Content (Get-Content $gradleFile -Raw)
    if ($after.VersionName -ne $VersionName -or $after.VersionCode -ne $VersionCode) {
        throw "Version update verification failed."
    }

    Write-Output "VersionName=$($after.VersionName)"
    Write-Output "VersionCode=$($after.VersionCode)"

    if (-not $SkipBuild) {
        Write-Output "Building APK with task $BuildTask ..."
        & .\gradlew.bat clean $BuildTask --console=plain --no-daemon
        if (-not (Test-Path $apkPath)) {
            throw "Build finished but APK was not found: $apkPath"
        }
        Write-Output "APK=$apkPath"
    }

    $existingTag = (& git tag --list $tagName)
    if ($existingTag) {
        throw "Tag already exists: $tagName"
    }

    & git add $gradleFile
    & git commit -m "Release $tagName"
    & git tag -a $tagName -m "Release $tagName"

    if (-not $SkipPush) {
        & git push origin $Branch
        & git push origin $tagName
    }

    Write-Output "Release prep complete."
    Write-Output "Tag=$tagName"
    Write-Output "Next: create a GitHub Release based on $tagName and upload only the APK as a manual asset if needed."
    Write-Output "Note: GitHub will still auto-generate source archives (zip/tar.gz); those cannot be removed."
} finally {
    Pop-Location
}
