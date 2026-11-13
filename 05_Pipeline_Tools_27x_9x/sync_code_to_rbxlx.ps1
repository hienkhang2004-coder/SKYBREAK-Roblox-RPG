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

# Mirror canonical shared duplicates inside 04_Roblox/src
$MirrorPairs = @(
    @("ReplicatedStorage\DelegatedV5Renderer.lua", "ReplicatedStorage\Shared\DelegatedV5Renderer.lua"),
    @("ReplicatedStorage\SkybreakShared\Config\WorldConfig.lua", "ReplicatedStorage\SkybreakShared\WorldConfig.lua"),
    @("ReplicatedStorage\SkybreakShared\Types\UIState.lua", "ReplicatedStorage\SkybreakShared\UIState.lua")
)
foreach ($pair in $MirrorPairs) {
    $leftPath = Join-Path $SrcRoot $pair[0]
    $rightPath = Join-Path $SrcRoot $pair[1]
    if (Test-Path $leftPath) {
        $rightDir = Split-Path $rightPath -Parent
        if (-not (Test-Path $rightDir)) { New-Item -ItemType Directory -Path $rightDir -Force | Out-Null }
        Copy-Item $leftPath -Destination $rightPath -Force
    }
}

if (-not (Test-Path $RbxlxPath)) {
    Write-Host "   [!] Chua thay file SKYBREAK_Playable_v12_PremiumUI.rbxlx trong 04_Roblox/." -ForegroundColor Yellow
    Write-Host "       Hay tai file .rbxlx tu Google Drive chung bo vao 04_Roblox/ (hoac dung plugin Rojo voi default.project.json)." -ForegroundColor Yellow
    exit 0
}

$BlenderPy = Get-ChildItem "C:\Program Files\Blender Foundation\Blender*\*\python\bin\python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$SysPy = Get-Command python -ErrorAction SilentlyContinue
$PyExe = if ($BlenderPy) { $BlenderPy.FullName } elseif ($SysPy) { $SysPy.Source } else { $null }
$PyScript = Join-Path $PSScriptRoot "sync_solid3d_and_scripts_to_rbxlx.py"

if ($PyExe) {
    Write-Host "=== 2. BOM CODE VAO SKYBREAK_Playable_v12_PremiumUI.rbxlx ===" -ForegroundColor Cyan
    & $PyExe $PyScript
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
            $codeText = [System.IO.File]::ReadAllText($fpath.FullName, [System.Text.Encoding]::UTF8).Replace("`r`n", "`n")
            $byteLen = [System.Text.Encoding]::UTF8.GetByteCount($codeText)
            if ($byteLen -ge 199000) {
                throw "HARD BYTE LIMIT EXCEEDED ($byteLen >= 199000): $($fpath.FullName)"
            }
            $relParts = $fpath.FullName.Substring($SrcRoot.Length + 1).Split('\')
            $fname = $relParts[-1]
            $leafClass = "ModuleScript"
            if ($fname.EndsWith(".server.lua")) {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 11)
                $leafClass = "Script"
            } elseif ($fname.EndsWith(".client.lua")) {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 11)
                $leafClass = "LocalScript"
            } else {
                $relParts[-1] = $fname.Substring(0, $fname.Length - 4)
            }
            $curr = $xml.roblox
            for ($idx = 0; $idx -lt $relParts.Length; $idx++) {
                $p = $relParts[$idx]
                $isLeaf = ($idx -eq ($relParts.Length - 1))
                $found = $null
                foreach ($item in $curr.Item) {
                    $nm = ($item.Properties.string | Where-Object { $_.name -eq "Name" }).'#text'
                    if ($nm -eq $p -and (-not $isLeaf -or $item.class -eq $leafClass)) { $found = $item; break }
                }
                if (-not $found) {
                    if ($idx -eq 0) { $curr = $null; break }
                    $targetCls = if ($isLeaf) { $leafClass } else { "Folder" }
                    $found = $xml.CreateElement("Item")
                    $found.SetAttribute("class", $targetCls)
                    $found.SetAttribute("referent", "RBX" + [guid]::NewGuid().ToString("N").ToUpper())
                    $propsEl = $xml.CreateElement("Properties")
                    $nameEl = $xml.CreateElement("string")
                    $nameEl.SetAttribute("name", "Name")
                    $nameEl.InnerText = $p
                    $propsEl.AppendChild($nameEl) | Out-Null
                    if ($isLeaf) {
                        $srcEl = $xml.CreateElement("ProtectedString")
                        $srcEl.SetAttribute("name", "Source")
                        $propsEl.AppendChild($srcEl) | Out-Null
                    }
                    $found.AppendChild($propsEl) | Out-Null
                    $curr.AppendChild($found) | Out-Null
                }
                $curr = $found
            }
            if ($curr) {
                $ps = $curr.Properties.ProtectedString | Where-Object { $_.name -eq "Source" }
                if (-not $ps) {
                    $ps = $xml.CreateElement("ProtectedString")
                    $ps.SetAttribute("name", "Source")
                    $curr.Properties.AppendChild($ps) | Out-Null
                }
                $ps.'#text' = $codeText
                $count++
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
$PyForLint = if ($PyExe) { $PyExe } else { "python" }
& $PyForLint $LintScript
if ($LASTEXITCODE -ne 0) { Write-Host "=== CO LOI LUAU, CHUA NEN VAO GAME ===" -ForegroundColor Red; exit 1 }
Write-Host "=== HOAN TAT! ===" -ForegroundColor Green
