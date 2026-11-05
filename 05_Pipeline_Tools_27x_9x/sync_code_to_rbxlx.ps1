$ErrorActionPreference = "Stop"
$HandoffRoot = Split-Path -Parent $PSScriptRoot
$RobloxDir = Join-Path $HandoffRoot "04_Roblox"
$SrcRoot = Join-Path $RobloxDir "src"
$RbxlxPath = Join-Path $RobloxDir "SKYBREAK_Playable_v12_PremiumUI.rbxlx"

Write-Host "=== 1. DONG BO 3 THU MUC HANG MUC -> LOCAL BUILD (04_Roblox/src) ===" -ForegroundColor Cyan

$CatDirs = @(
    (Join-Path $RobloxDir "01_HangMuc1_Server_Combat_World"),
    (Join-Path $RobloxDir "02_HangMuc2_UI_Shop_Config"),
    (Join-Path $RobloxDir "03_HangMuc3_3D_VuKhi_Giap_VFX")
)

$synced = 0
foreach ($catDir in $CatDirs) {
    if (-not (Test-Path $catDir)) { continue }
    Get-ChildItem $catDir -Recurse -Filter "*.lua" | ForEach-Object {
        $catFile = $_
        $rel = $catFile.FullName.Substring($catDir.Length + 1)
        $srcFile = Join-Path $SrcRoot $rel
        $srcDir = Split-Path $srcFile -Parent
        if (-not (Test-Path $srcDir)) { New-Item -ItemType Directory -Path $srcDir -Force | Out-Null }
        $needCopy = $true
        if (Test-Path $srcFile) {
            $h1 = (Get-FileHash $catFile.FullName -Algorithm SHA256).Hash
            $h2 = (Get-FileHash $srcFile -Algorithm SHA256).Hash
            if ($h1 -eq $h2) { $needCopy = $false }
        }
        if ($needCopy) {
            Copy-Item $catFile.FullName -Destination $srcFile -Force
            $synced++
        }
    }
}
Write-Host "   [+] Da cap nhat $synced file moi tu 3 Hang Muc -> 04_Roblox/src." -ForegroundColor Green

if (-not (Test-Path $RbxlxPath)) {
    Write-Host "   [!] Chua thay file SKYBREAK_Playable_v12_PremiumUI.rbxlx trong 04_Roblox/." -ForegroundColor Yellow
    Write-Host "       Hay tai file .rbxlx tu Google Drive chung bo vao 04_Roblox/ (hoac dung plugin Rojo voi default.project.json)." -ForegroundColor Yellow
    exit 0
}

$BlenderPy = Get-ChildItem "C:\Program Files\Blender Foundation\Blender*\*\python\bin\python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$PyScript = Join-Path $PSScriptRoot "sync_solid3d_and_scripts_to_rbxlx.py"

if ($BlenderPy) {
    Write-Host "=== 2. BOM CODE VAO SKYBREAK_Playable_v12_PremiumUI.rbxlx ===" -ForegroundColor Cyan
    & $BlenderPy.FullName $PyScript
} else {
    Write-Host "=== 2. BOM CODE VAO SKYBREAK_Playable_v12_PremiumUI.rbxlx (POWERSHELL XML) ===" -ForegroundColor Cyan
    [xml]$xml = Get-Content -Path $RbxlxPath -Raw -Encoding UTF8
    $services = @("ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer")
    $count = 0
    foreach ($svc in $services) {
        $svcDir = Join-Path $SrcRoot $svc
        if (-not (Test-Path $svcDir)) { continue }
        Get-ChildItem $svcDir -Recurse -Filter "*.lua" | ForEach-Object {
            $fpath = $_
            $relParts = $fpath.FullName.Substring($SrcRoot.Length + 1).Split('\')
            $fname = $relParts[-1]
            if ($fname.EndsWith(".server.lua")) {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 11)
            } elseif ($fname.EndsWith(".client.lua")) {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 11)
            } else {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 4)
            }
            $curr = $xml.roblox
            foreach ($p in $relParts) {
                $found = $null
                foreach ($item in $curr.Item) {
                    $nm = ($item.Properties.string | Where-Object { $_.name -eq "Name" }).'#text'
                    if ($nm -eq $p) { $found = $item; break }
                }
                if (-not $found) { $curr = $null; break }
                $curr = $found
            }
            if ($curr) {
                $ps = $curr.Properties.ProtectedString | Where-Object { $_.name -eq "Source" }
                if ($ps) {
                    $ps.'#text' = [System.IO.File]::ReadAllText($fpath.FullName, [System.Text.Encoding]::UTF8).Replace("`r`n", "`n")
                    $count++
                }
            }
        }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $sw = New-Object System.IO.StreamWriter($RbxlxPath, $false, $utf8NoBom)
    $xml.Save($sw)
    $sw.Close()
    Write-Host "   [+] Da bom $count script Luau truc tiep vao SKYBREAK_Playable_v12_PremiumUI.rbxlx!" -ForegroundColor Green
}
Write-Host "=== 3. KIEM TRA BIEN CHUA KHAI BAO TRONG LUAU ===" -ForegroundColor Cyan
$LintScript = Join-Path $PSScriptRoot "lint_luau_globals.py"
$PyForLint = if ($BlenderPy) { $BlenderPy.FullName } else { "python" }
& $PyForLint $LintScript
if ($LASTEXITCODE -ne 0) { Write-Host "=== CO LOI LUAU, CHUA NEN VAO GAME ===" -ForegroundColor Red; exit 1 }
Write-Host "=== HOAN TAT! ===" -ForegroundColor Green
