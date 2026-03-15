param(
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [int]$VersionCode,
    [string]$BuildTask = "assembleDebug",
    [switch]$SkipBuild,
    [switch]$SkipPush,
    [string]$Branch = "main",
    [switch]$CreateRelease,
    [string]$Repo = "Mayeggx/Pstankiroid",
    [string]$ReleaseAssetPath
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\use-e-drive-android-env.ps1"

$projectRoot = Split-Path $PSScriptRoot -Parent
$gradleFile = Join-Path $projectRoot "app\build.gradle.kts"
$apkPath = Join-Path $projectRoot "app\build\outputs\apk\debug\app-debug.apk"
$releaseDir = Join-Path $projectRoot "release"
$tagName = "v$VersionName"

function Get-GitHubHeaders {
    $cred = @"
protocol=https
host=github.com

"@ | git credential fill

    $tokenLine = $cred | Select-String '^password=' | Select-Object -First 1
    if (-not $tokenLine) {
        throw "Failed to resolve GitHub token from git credential helper."
    }

    $token = $tokenLine.ToString().Split('=', 2)[1]
    return @{
        Authorization = "Bearer $token"
        Accept = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
}

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

function Get-ArtifactName {
    param(
        [string]$Version
    )

    return "Pstankidroid-v$Version.apk"
}

Push-Location $projectRoot
try {
    $statusBefore = (& git status --short)
    if ($statusBefore) {
        throw "Git worktree is not clean. Commit or stash existing changes before running release.ps1."
    }

    $gitUserName = (& git config user.name).Trim()
    $gitUserEmail = (& git config user.email).Trim()
    if ([string]::IsNullOrWhiteSpace($gitUserName) -or [string]::IsNullOrWhiteSpace($gitUserEmail)) {
        throw "Git user.name/user.email is not configured for this repository."
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

    $artifactName = Get-ArtifactName -Version $VersionName
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
    $releaseAsset = Join-Path $releaseDir $artifactName
    Copy-Item -Force $apkPath $releaseAsset
    Write-Output "ReleaseAsset=$releaseAsset"

    $existingTag = (& git tag --list $tagName)
    if ($existingTag) {
        throw "Tag already exists: $tagName"
    }

    & git add $gradleFile
    if ($LASTEXITCODE -ne 0) { throw "git add failed." }
    & git commit -m "Release $tagName"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed." }
    & git tag -a $tagName -m "Release $tagName"
    if ($LASTEXITCODE -ne 0) { throw "git tag failed." }

    if (-not $SkipPush) {
        & git push origin $Branch
        if ($LASTEXITCODE -ne 0) { throw "git push branch failed." }
        & git push origin $tagName
        if ($LASTEXITCODE -ne 0) { throw "git push tag failed." }
    }

    Write-Output "Release prep complete."
    Write-Output "Tag=$tagName"

    if ($CreateRelease) {
        $assetPath = if ($ReleaseAssetPath) { $ReleaseAssetPath } else { $releaseAsset }
        if (-not (Test-Path $assetPath)) {
            throw "Release asset not found: $assetPath"
        }

        $headers = Get-GitHubHeaders
        $releaseBody =
            @{
                tag_name = $tagName
                target_commitish = $Branch
                name = $tagName
                body = "Pstankidroid $VersionName`n`nAssets:`n- $(Split-Path $assetPath -Leaf)"
                draft = $false
                prerelease = $false
            } | ConvertTo-Json

        $release =
            Invoke-RestMethod `
                -Method Post `
                -Headers $headers `
                -Uri "https://api.github.com/repos/$Repo/releases" `
                -Body $releaseBody `
                -ContentType "application/json"

        $uploadUrl = ($release.upload_url -replace '\{\?name,label\}', '') + "?name=$([System.Uri]::EscapeDataString((Split-Path $assetPath -Leaf)))"
        Invoke-RestMethod `
            -Method Post `
            -Headers @{
                Authorization = $headers.Authorization
                Accept = $headers.Accept
                "Content-Type" = "application/vnd.android.package-archive"
            } `
            -Uri $uploadUrl `
            -InFile $assetPath | Out-Null

        Write-Output "ReleaseUrl=$($release.html_url)"
        Write-Output "UploadedAsset=$(Split-Path $assetPath -Leaf)"
    } else {
        Write-Output "Next: create a GitHub Release based on $tagName and upload only the APK as a manual asset if needed."
        Write-Output "Note: GitHub will still auto-generate source archives (zip/tar.gz); those cannot be removed."
    }
} finally {
    Pop-Location
}
