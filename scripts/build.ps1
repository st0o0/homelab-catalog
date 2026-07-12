#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Merge individual template files into a single Portainer v2 catalog.
.DESCRIPTION
    Validates all JSON files under templates/ and merges them into templates.json.
#>

[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$templatesDir = Join-Path $repoRoot 'templates'
$outputFile = Join-Path $repoRoot 'templates.json'

if (-not (Test-Path $templatesDir)) {
    Write-Error "templates/ directory not found at $templatesDir"
    exit 1
}

$errors = [System.Collections.Generic.List[string]]::new()
$templates = [System.Collections.Generic.List[object]]::new()
$requiredFields = @('type', 'title')

$files = Get-ChildItem -Path $templatesDir -Filter '*.json' -Recurse | Sort-Object FullName

if ($files.Count -eq 0) {
    Write-Error 'No template files found under templates/'
    exit 1
}

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($repoRoot.Length + 1)

    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding utf8
        $template = $content | ConvertFrom-Json -AsHashtable
    }
    catch {
        $errors.Add("${relativePath}: invalid JSON - $_")
        continue
    }

    foreach ($field in $requiredFields) {
        if (-not $template.ContainsKey($field)) {
            $errors.Add("${relativePath}: missing required field '$field'")
        }
    }

    $type = $template['type']
    if ($type -notin @(1, 3)) {
        $errors.Add("${relativePath}: invalid type '$type', must be 1 or 3")
    }

    if ($type -eq 1 -and -not $template.ContainsKey('image')) {
        $errors.Add("${relativePath}: type 1 requires 'image' field")
    }

    if ($type -eq 3) {
        $repo = $template['repository']
        if (-not $repo -or -not $repo['url'] -or -not $repo['stackfile']) {
            $errors.Add("${relativePath}: type 3 requires repository.url and repository.stackfile")
        }
    }

    foreach ($envVar in $template['env']) {
        if (-not $envVar['name']) {
            $errors.Add("${relativePath}: env entry missing 'name'")
        }
    }

    foreach ($vol in $template['volumes']) {
        if (-not $vol['bind'] -or -not $vol['container']) {
            $errors.Add("${relativePath}: volume entry missing 'bind' or 'container'")
        }
    }

    $templates.Add($template)
}

if ($errors.Count -gt 0) {
    Write-Host "`nValidation failed:`n" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  x $err" -ForegroundColor Red
    }
    exit 1
}

# Check for duplicate titles
$titles = $templates | ForEach-Object { $_['title'] }
$dupes = $titles | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dupes) {
    Write-Host "`nDuplicate titles found:" -ForegroundColor Red
    foreach ($d in $dupes) {
        Write-Host "  x $($d.Name) (appears $($d.Count) times)" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`nValidated $($templates.Count) templates" -ForegroundColor Green

# Category summary
$categories = @{}
foreach ($t in $templates) {
    foreach ($cat in $t['categories']) {
        $categories[$cat] = ($categories[$cat] ?? 0) + 1
    }
}
foreach ($cat in ($categories.Keys | Sort-Object)) {
    Write-Host "  $cat`: $($categories[$cat])"
}

if ($ValidateOnly) {
    exit 0
}

# Build merged catalog
$catalog = [ordered]@{
    version   = '2'
    templates = [array]$templates
}

$json = $catalog | ConvertTo-Json -Depth 10 -EscapeHandling Default
$json | Out-File -FilePath $outputFile -Encoding utf8NoBOM -NoNewline
Add-Content -Path $outputFile -Value '' -NoNewline:$false -Encoding utf8NoBOM

Write-Host "`nBuilt $((Resolve-Path $outputFile -Relative)) with $($templates.Count) templates" -ForegroundColor Green
