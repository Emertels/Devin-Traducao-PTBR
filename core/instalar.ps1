$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$OutputEncoding = $utf8
try { $Host.UI.RawUI.WindowTitle = 'Instalador PT-BR - Devin AI - Emerson Teles' } catch {}

function Read-OpenChoice([string]$Prompt) {
    Write-Host $Prompt -NoNewline
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.KeyChar -match '^[sS]$') { Write-Host 'S'; return $true }
        if ($key.KeyChar -match '^[nN]$' -or $key.Key -in @([ConsoleKey]::Enter, [ConsoleKey]::Escape)) { Write-Host $key.KeyChar; return $false }
    }
}

function Find-Devin {
    . (Join-Path $PSScriptRoot 'Find-Installations.ps1')
    $candidates = @()
    $process = Get-Process -Name Devin -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($process -and $process.Path) { $candidates += Split-Path -Parent $process.Path }
    $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Devin')
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Devin') }
    foreach ($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
        try { Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Devin' -and $_.InstallLocation } | ForEach-Object { $candidates += $_.InstallLocation } } catch {}
    }
    $quickValid = @($candidates | Where-Object {
        $candidatePath = ([string]$_).Trim().Trim('"')
        (Test-Path -LiteralPath (Join-Path $candidatePath 'Devin.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $candidatePath 'resources\app\package.json') -PathType Leaf)
    } | Select-Object -Unique)
    if ($quickValid.Count -gt 0) {
        $candidates = $quickValid
    } else {
        Write-Host '    Nenhum caminho conhecido validado; iniciando busca precisa nas unidades...' -ForegroundColor DarkGray
        $candidates += @(Find-ExecutableDirectoriesOnAllDrives -ExecutableName 'Devin.exe' -ProductLabel 'Devin AI' -ValidationRelativePath 'resources\app\package.json')
    }
    $valid = @()
    $seenPaths = @{}
    foreach ($candidate in ($candidates | Where-Object { $_ })) {
        try {
            $normalized = [IO.Path]::GetFullPath(([string]$candidate).Trim().Trim('"'))
            $resolved = (Resolve-Path -LiteralPath $normalized -ErrorAction Stop).Path.TrimEnd('\')
            if (-not $seenPaths.ContainsKey($resolved) -and (Test-Path -LiteralPath (Join-Path $resolved 'resources\app\package.json') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $resolved 'Devin.exe') -PathType Leaf)) {
                $seenPaths[$resolved] = $true
                $valid += $resolved
            }
        } catch {}
    }
    if ($valid.Count -eq 1) { return $valid[0] }
    if ($valid.Count -gt 1) {
        Write-Host '[i] Mais de uma instalação válida do Devin foi encontrada:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $valid.Count; $i++) { Write-Host "[$($i + 1)] $($valid[$i])" -ForegroundColor Cyan }
        do { $choice = Read-Host 'Digite o número da instalação'; $selection = 0 } while (-not [int]::TryParse($choice, [ref]$selection) -or $selection -lt 1 -or $selection -gt $valid.Count)
        return $valid[$selection - 1]
    }
    return $null
}

function Set-JsoncLocale([string]$Path, [string]$Locale) {
    $text = [IO.File]::ReadAllText($Path)
    $pattern = '(?m)^\s*"locale"\s*:\s*"[^"]*"\s*,?\s*(?:\r?\n)?'
    $text = [regex]::Replace($text, $pattern, '')
    $close = $text.LastIndexOf('}')
    if ($close -lt 0) { throw "argv.json inválido: $Path" }
    $before = $text.Substring(0, $close).TrimEnd()
    if ($before -notmatch ',\s*$') { $before += ',' }
    $text = $before + "`r`n`t`"locale`": `"$Locale`"`r`n" + $text.Substring($close)
    [IO.File]::WriteAllText($Path, $text, $utf8)
}

function Get-OriginalArgv([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    return [regex]::Replace($text, '(?m)^\s*"locale"\s*:\s*"[^"]*"\s*,?\s*(?:\r?\n)?', '')
}

function Stop-DevinWindows {
    $main = @(Get-Process -Name Devin -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })
    foreach ($p in $main) { try { [void]$p.CloseMainWindow() } catch {} }
    $until = (Get-Date).AddSeconds(15)
    do { Start-Sleep -Milliseconds 400; $left = @(Get-Process -Name Devin -ErrorAction SilentlyContinue) } while ($left.Count -and (Get-Date) -lt $until)
    if ($left.Count) { throw 'O Devin ainda está rodando em segundo plano. Feche todas as janelas e processos do Devin e execute o instalador novamente.' }
}

function Reset-DevinCaches {
    $cacheRoot = Join-Path $env:APPDATA 'Devin'
    $suffix = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($name in @('Cache', 'Code Cache', 'GPUCache', 'DawnGraphiteCache', 'DawnWebGPUCache')) {
        $source = Join-Path $cacheRoot $name
        $destination = Join-Path $cacheRoot ($name + '.before-ptbr-' + $suffix)
        if (Test-Path -LiteralPath $source) {
            $counter = 1
            while (Test-Path -LiteralPath $destination) { $destination = Join-Path $cacheRoot ($name + '.before-ptbr-' + $suffix + '-' + $counter); $counter++ }
            Move-Item -LiteralPath $source -Destination $destination
        }
    }
}

function Get-DevinFileChecksum([string]$Path) {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToBase64String($sha256.ComputeHash([IO.File]::ReadAllBytes($Path))).TrimEnd('=') }
    finally { $sha256.Dispose() }
}

function Update-DevinIntegrityChecksums([string]$Install) {
    $productPath = Join-Path $Install 'resources\app\product.json'
    $raw = [IO.File]::ReadAllText($productPath)
    $product = ConvertFrom-Json -InputObject $raw
    $checksumFiles = @{
        'resources\app\out\vs\workbench\workbench.desktop.main.js' = 'vs/workbench/workbench.desktop.main.js'
        'resources\app\out\vs\workbench\windsurf-chat-client\index.js' = 'vs/workbench/windsurf-chat-client/index.js'
        'resources\app\out\vs\sessions\sessions.desktop.main.js' = 'vs/sessions/sessions.desktop.main.js'
    }
    foreach ($relativeFile in $checksumFiles.Keys) {
        $file = Join-Path $Install $relativeFile
        $key = $checksumFiles[$relativeFile]
        $entry = $product.checksums.PSObject.Properties[$key]
        if (-not (Test-Path -LiteralPath $file) -or -not $entry) { continue }
        $oldPair = '"' + $key + '": "' + [string]$entry.Value + '"'
        $newHash = Get-DevinFileChecksum $file
        $newPair = '"' + $key + '": "' + $newHash + '"'
        if (-not $raw.Contains($oldPair)) { throw "Não foi possível atualizar o checksum de $key." }
        $raw = $raw.Replace($oldPair, $newPair)
    }
    [IO.File]::WriteAllText($productPath, $raw, [System.Text.UTF8Encoding]::new($false))
}

function Patch-DevinEmbeddedUi([string]$Install, [string]$BackupDir, [string]$Root) {
    $translationsPath = Join-Path $Root 'translations\embedded-ui.json'
    $translations = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($translationsPath))
    $replacerPath = Join-Path $Root 'tools\EmbeddedUiLiteralReplacer.cs'
    if (-not (Test-Path -LiteralPath $replacerPath)) { throw 'O otimizador de textos internos está ausente.' }
    if (-not ('DevinEmbeddedUiLiteralReplacer' -as [type])) { Add-Type -Path $replacerPath | Out-Null }
    $literalMap = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::Ordinal)
    foreach ($entry in $translations.PSObject.Properties) {
        $source = [string]$entry.Name
        $localized = [string]$entry.Value
        foreach ($quote in @('"', "'")) {
            $sourceLiteral = $quote + $source.Replace('\', '\\').Replace($quote, '\' + $quote) + $quote
            $localizedLiteral = $quote + $localized.Replace('\', '\\').Replace($quote, '\' + $quote) + $quote
            $literalMap[$sourceLiteral] = $localizedLiteral
            $literalMap[$localizedLiteral] = $localizedLiteral
        }
    }
    $literalMap['"Send (\u23CE)"'] = '"Enviar (\u23CE)"'
    $literalMap['"Enviar (\u23CE)"'] = '"Enviar (\u23CE)"'
    $relativeFiles = @('resources\app\out\vs\workbench\workbench.desktop.main.js', 'resources\app\out\vs\workbench\windsurf-chat-client\index.js', 'resources\app\out\vs\sessions\sessions.desktop.main.js', 'resources\app\node_modules\@exa\chat-client\index.js')
    $changed = New-Object System.Collections.ArrayList
    $matchCount = 0
    $fileNumber = 0
    foreach ($relativeFile in $relativeFiles) {
        $fileNumber++
        $path = Join-Path $Install $relativeFile
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $fileInfo = Get-Item -LiteralPath $path
        Write-Host "  [$fileNumber/$($relativeFiles.Count)] Traduzindo textos internos: $(Split-Path -Leaf $relativeFile) ($([math]::Round($fileInfo.Length / 1MB, 1)) MB)..." -ForegroundColor DarkGray
        $original = [IO.File]::ReadAllText($path)
        $replaceResult = [DevinEmbeddedUiLiteralReplacer]::Replace($original, $literalMap)
        $matchCount += $replaceResult.MatchCount
        if ($replaceResult.MatchCount -eq 0) { continue }
        $updated = [regex]::Replace($replaceResult.Text, '(?<=`)Start recording(?=\$\{)', 'Iniciar gravação')
        $updated = [regex]::Replace($updated, '(?<=`)Stop recording(?=\$\{)', 'Parar gravação')
        $updated = $updated.Replace('"Test Recording"', '"Gravação de teste"')
        if ($updated -cne $original) { [void]$changed.Add([pscustomobject]@{ Path = $path; RelativePath = $relativeFile; Contents = $updated }) }
    }
    if ($matchCount -eq 0) { throw 'Não encontrei os textos internos do Devin para traduzir nesta versão.' }
    foreach ($item in $changed) {
        $backupPath = Join-Path (Join-Path $BackupDir 'embedded-ui') $item.RelativePath
        if (-not (Test-Path -LiteralPath $backupPath)) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
            Copy-Item -LiteralPath $item.Path -Destination $backupPath
        }
        [IO.File]::WriteAllText($item.Path, $item.Contents, [System.Text.UTF8Encoding]::new($false))
    }
    Update-DevinIntegrityChecksums $Install
    return $changed.Count
}

function Restore-DevinPatchBackups([string]$Install, [string]$BackupDir) {
    $embeddedBackup = Join-Path $BackupDir 'embedded-ui'
    if (Test-Path -LiteralPath $embeddedBackup) {
        Get-ChildItem -LiteralPath $embeddedBackup -File -Recurse | ForEach-Object {
            $relativeFile = $_.FullName.Substring($embeddedBackup.Length).TrimStart('\')
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Install $relativeFile) -Force
        }
    }
    $productBackup = Join-Path $BackupDir 'product.json'
    if (Test-Path -LiteralPath $productBackup) { Copy-Item -LiteralPath $productBackup -Destination (Join-Path $Install 'resources\app\product.json') -Force }
}

$workDir = $null
$stage = 'inicialização'
$embeddedPatchStarted = $false
$install = $null
$backupDir = $null
$cli = $null
$extensionsDir = $null
$argv = $null
$langPackInstalled = $false
$localeChanged = $false
try {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '        TRADUÇÃO DEVIN PARA PORTUGUÊS DO BRASIL' -ForegroundColor Green
    Write-Host '             Tradução PT-BR: Emerson Teles' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    $root = Split-Path -Parent $PSScriptRoot
    $baseVsix = Join-Path $root 'assets\Devin-PTBR.vsix'
    $builder = Join-Path $root 'tools\build-language-pack.cjs'
    if (-not (Test-Path -LiteralPath $baseVsix -PathType Leaf) -or -not (Test-Path -LiteralPath $builder -PathType Leaf)) { throw 'Pacote-base PT-BR ou empacotador ausente na pasta assets/tools.' }
    $install = Find-Devin
    while (-not $install) {
        $path = (Read-Host 'Não encontrei o Devin instalado. Cole a pasta da instalação (Enter para sair)').Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($path)) { throw 'O Devin AI não foi encontrado. Nenhum arquivo foi alterado.' }
        if ((Test-Path -LiteralPath (Join-Path $path 'resources\app\package.json') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $path 'Devin.exe') -PathType Leaf)) { $install = (Resolve-Path -LiteralPath $path).Path }
        else { Write-Host 'Instalação não reconhecida: confira a pasta informada.' -ForegroundColor Yellow }
    }
    $appRoot = Join-Path $install 'resources\app'
    $appJson = Get-Content -LiteralPath (Join-Path $appRoot 'package.json') -Raw | ConvertFrom-Json
    $engineVersion = [string]$appJson.version
    $productPath = Join-Path $appRoot 'product.json'
    $productJson = Get-Content -LiteralPath $productPath -Raw | ConvertFrom-Json
    $version = if ($productJson.windsurfVersion) { [string]$productJson.windsurfVersion } else { $engineVersion }
    $cli = Join-Path $install 'bin\devin-desktop.cmd'
    $exe = Join-Path $install 'Devin.exe'
    if (-not (Test-Path -LiteralPath $cli -PathType Leaf)) { throw 'CLI do Devin não encontrada nesta instalação.' }
    $profile = Join-Path $env:USERPROFILE '.devin'
    $extensionsDir = Join-Path $profile 'extensions'
    $dataRoot = Join-Path $env:APPDATA 'Devin'
    $argv = Join-Path $profile 'argv.json'
    if (-not (Test-Path -LiteralPath $argv -PathType Leaf)) { throw "Arquivo de configuração não encontrado: $argv" }
    $backupDir = Join-Path (Join-Path $install '_backups') $version
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $argvBackup = Join-Path $backupDir 'argv.json'
    if (-not (Test-Path -LiteralPath $argvBackup)) { [IO.File]::WriteAllText($argvBackup, (Get-OriginalArgv $argv), $utf8) }
    $productBackup = Join-Path $backupDir 'product.json'
    if (-not (Test-Path -LiteralPath $productBackup)) { Copy-Item -LiteralPath $productPath -Destination $productBackup }
    $langpacks = Join-Path $dataRoot 'languagepacks.json'
    $langpackBackup = Join-Path $backupDir 'languagepacks.json'
    if ((Test-Path -LiteralPath $langpacks) -and -not (Test-Path -LiteralPath $langpackBackup)) { Copy-Item -LiteralPath $langpacks -Destination $langpackBackup }
    $list = & $cli --extensions-dir $extensionsDir --list-extensions --show-versions 2>$null | Out-String
    $expectedExtension = '(?im)emersonteles\.devin-language-pack-pt-br@' + [regex]::Escape($engineVersion)
    if ($list -match $expectedExtension -and (Select-String -LiteralPath $argv -Pattern '"locale"\s*:\s*"pt-br"' -Quiet)) {
        Write-Host "A versão $version já está traduzida para PT-BR." -ForegroundColor Green
        $stage = 'atualização das traduções internas e dos checksums'
        Stop-DevinWindows
        $embeddedPatchStarted = $true
        $changedFiles = Patch-DevinEmbeddedUi $install $backupDir $root
        if ($changedFiles -gt 0) { Reset-DevinCaches; Write-Host 'Os textos internos foram atualizados.' -ForegroundColor Green }
        else { Write-Host 'Os textos internos já estão atualizados.' -ForegroundColor Green }
    } else {
        Write-Host "Devin $version detectado. Preparando a instalação..." -ForegroundColor White
        $workDir = Join-Path $env:TEMP "Devin-PTBR-$engineVersion-$PID"
        $sourceDir = Join-Path $workDir 'source'
        $buildDir = Join-Path $workDir 'built'
        New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
        $baseZip = Join-Path $workDir 'base.zip'
        Copy-Item -LiteralPath $baseVsix -Destination $baseZip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($baseZip, $sourceDir)
        $outDir = Join-Path $appRoot 'out'
        foreach ($name in @('nls.metadata.json', 'nls.keys.json', 'nls.messages.json')) {
            $metadataFile = Join-Path $outDir $name
            if (-not (Test-Path -LiteralPath $metadataFile -PathType Leaf)) { throw "Arquivo de metadados do idioma não encontrado: $metadataFile" }
        }
        $env:DEVIN_APP_VERSION = $engineVersion
        $env:DEVIN_NLS_METADATA = Join-Path $outDir 'nls.metadata.json'
        $env:DEVIN_NLS_KEYS = Join-Path $outDir 'nls.keys.json'
        $env:DEVIN_NLS_MESSAGES = Join-Path $outDir 'nls.messages.json'
        $node = Get-Command node -ErrorAction SilentlyContinue
        if (-not $node) { throw 'Node.js é necessário para adaptar o pacote à versão instalada do Devin.' }
        Write-Host 'Gerando pacote PT-BR compatível...' -ForegroundColor DarkGray
        $stage = 'geração do pacote de idioma'
        & $node.Source $builder $sourceDir $buildDir
        if ($LASTEXITCODE -ne 0) { throw 'Não foi possível gerar o pacote compatível com esta versão do Devin.' }
        $builtZip = Join-Path $workDir 'Devin-PTBR.zip'
        $vsix = Join-Path $workDir 'Devin-PTBR.vsix'
        [System.IO.Compression.ZipFile]::CreateFromDirectory($buildDir, $builtZip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        Move-Item -LiteralPath $builtZip -Destination $vsix
        Write-Host 'Fechando o Devin antes de aplicar as alterações...' -ForegroundColor DarkGray
        $stage = 'encerramento do Devin'
        Stop-DevinWindows
        Write-Host 'Instalando o pacote de idioma...' -ForegroundColor DarkGray
        $stage = 'instalação do pacote de idioma'
        & $cli --extensions-dir $extensionsDir --install-extension $vsix --force
        if ($LASTEXITCODE -ne 0) { throw "O Devin recusou o pacote de idioma (código $LASTEXITCODE)." }
        $langPackInstalled = $true
        if (-not (Test-Path -LiteralPath $langpacks)) { New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null; [IO.File]::WriteAllText($langpacks, '{}', $utf8) }
        Write-Host 'Configurando o idioma...' -ForegroundColor DarkGray
        $stage = 'configuração do idioma'
        $localeChanged = $true
        Set-JsoncLocale $argv 'pt-br'
        $stage = 'tradução dos textos internos e atualização dos checksums'
        $embeddedPatchStarted = $true
        $changedFiles = Patch-DevinEmbeddedUi $install $backupDir $root
        Write-Host 'Atualizando os caches do Devin...' -ForegroundColor DarkGray
        $stage = 'atualização dos caches'
        Reset-DevinCaches
        Write-Host 'Confirmando a instalação do pacote...' -ForegroundColor DarkGray
        $stage = 'confirmação do pacote de idioma'
        $registered = $false
        for ($attempt = 0; $attempt -lt 5; $attempt++) {
            $packs = & $cli --extensions-dir $extensionsDir --list-extensions --show-versions 2>$null | Out-String
            if ($packs -match $expectedExtension) { $registered = $true; break }
            Start-Sleep -Milliseconds 500
        }
        if (-not $registered) { throw 'A extensão de idioma não apareceu na lista de extensões após a instalação.' }
        Write-Host 'Pacote PT-BR instalado e idioma configurado.' -ForegroundColor Green
        if ($changedFiles -eq 0) { Write-Host 'Os textos internos já estavam traduzidos.' -ForegroundColor DarkGray }
    }
    if ($workDir -and (Test-Path -LiteralPath $workDir)) { Remove-Item -LiteralPath $workDir -Recurse -Force }
    Remove-Item Env:\DEVIN_APP_VERSION, Env:\DEVIN_NLS_METADATA, Env:\DEVIN_NLS_KEYS, Env:\DEVIN_NLS_MESSAGES -ErrorAction SilentlyContinue
    if (Read-OpenChoice 'Deseja abrir o Devin AI? [S = sim | N/Enter/Esc = sair]: ') { Start-Process -FilePath $exe -ArgumentList '--locale=pt-br' }
    exit 0
} catch {
    if ($langPackInstalled -and $cli -and $extensionsDir) { try { & $cli --extensions-dir $extensionsDir --uninstall-extension emersonteles.devin-language-pack-pt-br *> $null } catch {} }
    if ($embeddedPatchStarted -and $install -and $backupDir) { try { Restore-DevinPatchBackups $install $backupDir } catch {} }
    if ($localeChanged -and $argv -and $backupDir -and (Test-Path -LiteralPath (Join-Path $backupDir 'argv.json'))) { try { Copy-Item -LiteralPath (Join-Path $backupDir 'argv.json') -Destination $argv -Force } catch {} }
    if ($workDir -and (Test-Path -LiteralPath $workDir)) { Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue }
    Remove-Item Env:\DEVIN_APP_VERSION, Env:\DEVIN_NLS_METADATA, Env:\DEVIN_NLS_KEYS, Env:\DEVIN_NLS_MESSAGES -ErrorAction SilentlyContinue
    Write-Host "Falha durante: $stage." -ForegroundColor DarkGray
    Write-Host "`n[ERRO] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'O instalador manterá esta janela aberta para você ler o erro.' -ForegroundColor DarkGray
    exit 1
}
