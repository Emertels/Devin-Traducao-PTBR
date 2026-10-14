$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8
try { $Host.UI.RawUI.WindowTitle = 'Restaurador PT-BR - Devin AI - Emerson Teles' } catch {}

function Read-OpenChoice([string]$Prompt) {
    Write-Host $Prompt -NoNewline
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.KeyChar -match '^[sS]$') { Write-Host 'S'; return $true }
        if ($key.KeyChar -match '^[nN]$' -or $key.Key -in @([ConsoleKey]::Enter, [ConsoleKey]::Escape)) { Write-Host $key.KeyChar; return $false }
    }
}
function Reset-DevinCaches {
    $cacheRoot = Join-Path $env:APPDATA 'Devin'
    $suffix = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($name in @('Cache', 'Code Cache', 'GPUCache', 'DawnGraphiteCache', 'DawnWebGPUCache')) {
        $source = Join-Path $cacheRoot $name
        $destination = Join-Path $cacheRoot ($name + '.before-ptbr-' + $suffix)
        if (Test-Path -LiteralPath $source) {
            $counter = 1
            while (Test-Path -LiteralPath $destination) {
                $destination = Join-Path $cacheRoot ($name + '.before-ptbr-' + $suffix + '-' + $counter)
                $counter++
            }
            Move-Item -LiteralPath $source -Destination $destination
        }
    }
}
function Test-DevinAlreadyRestored([string]$Install, [string]$Argv, [string]$ArgvBackup, [string]$ProductJson, [string]$ProductBackup, [string]$BackupDir, [string]$InstalledExtensions) {
    if ($InstalledExtensions -match '(?im)^emersonteles\.devin-language-pack-pt-br@') { return $false }
    if (-not (Test-Path -LiteralPath $Argv) -or -not (Test-Path -LiteralPath $ArgvBackup)) { return $false }
    if ((Get-FileHash -LiteralPath $Argv -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $ArgvBackup -Algorithm SHA256).Hash) { return $false }
    if ((Test-Path -LiteralPath $ProductBackup) -and (Get-FileHash -LiteralPath $ProductJson -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $ProductBackup -Algorithm SHA256).Hash) { return $false }

    $embeddedBackup = Join-Path $BackupDir 'embedded-ui'
    if (Test-Path -LiteralPath $embeddedBackup) {
        foreach ($original in (Get-ChildItem -LiteralPath $embeddedBackup -File -Recurse)) {
            $relativeFile = $original.FullName.Substring($embeddedBackup.Length).TrimStart('\')
            $current = Join-Path $Install $relativeFile
            if (-not (Test-Path -LiteralPath $current)) { return $false }
            if ((Get-FileHash -LiteralPath $current -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $original.FullName -Algorithm SHA256).Hash) { return $false }
        }
    }
    return $true
}
function Find-Devin {
    . (Join-Path $PSScriptRoot 'Find-Installations.ps1')
    $candidates = @()
    $process = Get-Process -Name Devin -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($process -and $process.Path) { $candidates += Split-Path -Parent $process.Path }
    $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Devin'); $candidates += (Join-Path $env:ProgramFiles 'Devin')
    foreach ($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) { try { Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Devin' -and $_.InstallLocation } | ForEach-Object { $candidates += $_.InstallLocation } } catch {} }
    # Primeiro valida caminhos conhecidos; só faz busca profunda quando nenhum deles serve.
    $quickValid = @($candidates | Where-Object {
        $candidatePath = ([string]$_).Trim().Trim('"')
        (Test-Path -LiteralPath (Join-Path $candidatePath 'Devin.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $candidatePath 'resources\app\package.json') -PathType Leaf)
    } | Select-Object -Unique)
    if ($quickValid.Count -gt 0) {
        $candidates = $quickValid
    } else {
        Write-Host "    Nenhum caminho conhecido validado; iniciando busca em todas as unidades..." -ForegroundColor DarkGray
        $candidates += @(Find-ExecutableDirectoriesOnAllDrives -ExecutableName 'Devin.exe' -ProductLabel 'Devin AI' -ValidationRelativePath 'resources\app\package.json')
    }
    $candidates = @($candidates | Where-Object { $_ } | Select-Object -Unique)
    $valid = @(); $seenPaths = @{}
    foreach ($candidate in ($candidates | Where-Object { $_ })) { try { $normalized=[IO.Path]::GetFullPath(([string]$candidate).Trim().Trim('"')); $resolved=(Resolve-Path -LiteralPath $normalized -ErrorAction Stop).Path.TrimEnd('\'); if (-not $seenPaths.ContainsKey($resolved) -and (Test-Path -LiteralPath (Join-Path $resolved 'resources\app\package.json') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $resolved 'Devin.exe') -PathType Leaf)) { $seenPaths[$resolved]=$true; $valid+=$resolved } } catch {} }
    if ($valid.Count -eq 1) { return $valid[0] }
    if ($valid.Count -gt 1) { Write-Host '[i] Mais de uma instalação do Devin foi encontrada:' -ForegroundColor Yellow; for ($i=0; $i -lt $valid.Count; $i++) { Write-Host "[$($i+1)] $($valid[$i])" -ForegroundColor Cyan }; do { $choice=Read-Host 'Digite o número da instalação a restaurar'; $selection=0 } while (-not [int]::TryParse($choice,[ref]$selection) -or $selection -lt 1 -or $selection -gt $valid.Count); return $valid[$selection-1] }
    return $null
}
try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '        RESTAURAR DEVIN AO IDIOMA ORIGINAL' -ForegroundColor Cyan
    Write-Host '             Pacote PT-BR: Emerson Teles' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    $install = Find-Devin
    while (-not $install) { $path = (Read-Host 'Não encontrei o Devin automaticamente. Cole a pasta da instalação (Enter para sair)').Trim().Trim('"'); if ([string]::IsNullOrWhiteSpace($path)) { throw 'O Devin pode não estar instalado. Nenhum arquivo foi alterado.' }; if ((Test-Path -LiteralPath (Join-Path $path 'resources\app\package.json') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $path 'Devin.exe') -PathType Leaf)) { $install=$path } else { Write-Host 'Instalação não reconhecida: confira a pasta informada.' -ForegroundColor Yellow } }
    $manifestPath = Join-Path $install 'resources\app\package.json'
    if (-not (Test-Path $manifestPath)) { throw 'Não encontrei Devin em %LOCALAPPDATA%\Programs\Devin.' }
    $engineVersion = [string](Get-Content $manifestPath -Raw | ConvertFrom-Json).version
    $productJson = Get-Content (Join-Path $install 'resources\app\product.json') -Raw | ConvertFrom-Json
    $version = if ($productJson.windsurfVersion) { [string]$productJson.windsurfVersion } else { $engineVersion }
    $cli = Join-Path $install 'bin\devin-desktop.cmd'
    $exe = Join-Path $install 'Devin.exe'
    $argv = Join-Path $env:USERPROFILE '.devin\argv.json'
    $backupDir = Join-Path (Join-Path $install '_backups') $version
    $backup = Join-Path $backupDir 'argv.json'
    $productJsonPath = Join-Path $install 'resources\app\product.json'
    $productJsonBackup = Join-Path $backupDir 'product.json'
    if (-not (Test-Path $backup)) { throw "Backup original da versão $version não encontrado em $backup. Nenhum arquivo foi alterado. Dica: reinstale o Devin por cima com o instalador oficial para restaurar os arquivos do programa; depois, se quiser usar a tradução novamente, execute Instalar-Traducao.bat." }
    $list = & $cli --extensions-dir (Join-Path $env:USERPROFILE '.devin\extensions') --list-extensions --show-versions 2>$null | Out-String
    if (Test-DevinAlreadyRestored $install $argv $backup $productJsonPath $productJsonBackup $backupDir $list) {
        Write-Host "O Devin $version já está no idioma original. Nenhuma restauração foi necessária." -ForegroundColor Green
        if (Read-OpenChoice 'Deseja abrir o Devin AI? [S = sim | N/Enter/Esc = sair]: ') { Start-Process -FilePath $exe }
        exit 0
    }
    $running = @(Get-Process -Name Devin -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })
    foreach ($p in $running) { try { [void]$p.CloseMainWindow() } catch {} }
    $until = (Get-Date).AddSeconds(15)
    do { Start-Sleep -Milliseconds 400; $left = @(Get-Process -Name Devin -ErrorAction SilentlyContinue) } while ($left.Count -and (Get-Date) -lt $until)
    if ($left.Count) { throw 'O Devin ainda está rodando em segundo plano. Feche todas as janelas e processos do Devin e execute o restaurador novamente.' }
    if ($list -match '(?im)^emersonteles\.devin-language-pack-pt-br@') {
        & $cli --extensions-dir (Join-Path $env:USERPROFILE '.devin\extensions') --uninstall-extension emersonteles.devin-language-pack-pt-br
        if ($LASTEXITCODE -ne 0) { throw "Não foi possível remover o pacote PT-BR (código $LASTEXITCODE)." }
    }
    $embeddedBackup = Join-Path $backupDir 'embedded-ui'
    if (Test-Path -LiteralPath $embeddedBackup) {
        Get-ChildItem -LiteralPath $embeddedBackup -File -Recurse | ForEach-Object {
            $relativeFile = $_.FullName.Substring($embeddedBackup.Length).TrimStart('\')
            $destination = Join-Path $install $relativeFile
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
        }
    }
    if (Test-Path -LiteralPath $productJsonBackup) { Copy-Item -LiteralPath $productJsonBackup -Destination $productJsonPath -Force }
    Copy-Item -LiteralPath $backup -Destination $argv -Force
    Reset-DevinCaches
    Write-Host "A configuração original do Devin $version foi restaurada." -ForegroundColor Green
    if (Read-OpenChoice 'Deseja abrir o Devin AI? [S = sim | N/Enter/Esc = sair]: ') { Start-Process -FilePath $exe }
    exit 0
} catch {
    Write-Host "`n[ERRO] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Pressione uma tecla para fechar.' -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
    exit 1
}



