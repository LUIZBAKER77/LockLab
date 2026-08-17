# =========================
# LockLab - versão estável
# =========================

$LAB_USER   = "DOMINIO\aluno"
$TOOLS_PATH = "C:\LabTools"
$HOME_URL   = "https://portal.exemplo.edu.br"

$ErrorActionPreference = "Stop"

# Verificar admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "Execute como administrador"
    pause; exit
}

# Criar pasta
if (!(Test-Path $TOOLS_PATH)) {
    New-Item -ItemType Directory -Path $TOOLS_PATH -Force | Out-Null
}

# =========================
# 1. POLÍTICAS DE NAVEGADOR
# =========================

Write-Host "Configurando navegadores..."

$chrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
New-Item -Path $chrome -Force | Out-Null

Set-ItemProperty $chrome "IncognitoModeAvailability" 2 -Type DWord
Set-ItemProperty $chrome "SavingBrowserHistoryDisabled" 1 -Type DWord
Set-ItemProperty $chrome "SigninAllowed" 0 -Type DWord
Set-ItemProperty $chrome "SyncDisabled" 1 -Type DWord

$edge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $edge -Force | Out-Null

Set-ItemProperty $edge "InPrivateModeAvailability" 2 -Type DWord
Set-ItemProperty $edge "SavingBrowserHistoryDisabled" 1 -Type DWord
Set-ItemProperty $edge "BrowserSignin" 0 -Type DWord
Set-ItemProperty $edge "SyncDisabled" 1 -Type DWord

# =========================
# 2. ATALHOS COM URL E FLAG
# A URL e passada como argumento direto pois o Chrome ignora
# politicas de startup quando o modo anonimo e forcado via registro
# =========================

Write-Host "Criando atalhos com homepage..."

$wsh = New-Object -ComObject WScript.Shell

$chromExe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
if (!(Test-Path $chromExe)) { $chromExe = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }

$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (!(Test-Path $edgeExe)) { $edgeExe = "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe" }

if (Test-Path $chromExe) {
    $lnk = $wsh.CreateShortcut("$TOOLS_PATH\Google Chrome.lnk")
    $lnk.TargetPath   = $chromExe
    $lnk.Arguments    = "--incognito `"$HOME_URL`""
    $lnk.IconLocation = "$chromExe,0"
    $lnk.Save()
    Write-Host "  [OK] Atalho Chrome criado"
}

if (Test-Path $edgeExe) {
    $lnk = $wsh.CreateShortcut("$TOOLS_PATH\Microsoft Edge.lnk")
    $lnk.TargetPath   = $edgeExe
    $lnk.Arguments    = "--inprivate `"$HOME_URL`""
    $lnk.IconLocation = "$edgeExe,0"
    $lnk.Save()
    Write-Host "  [OK] Atalho Edge criado"
}

# Substituir atalhos na barra de tarefas do aluno (se o perfil ja existir)
$labProfile = "C:\Users\aluno"
$taskbarDir = "$labProfile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

if (Test-Path $taskbarDir) {
    if (Test-Path $chromExe) {
        Copy-Item "$TOOLS_PATH\Google Chrome.lnk" "$taskbarDir\Google Chrome.lnk" -Force
        Write-Host "  [OK] Atalho Chrome atualizado na barra de tarefas"
    }
    if (Test-Path $edgeExe) {
        Copy-Item "$TOOLS_PATH\Microsoft Edge.lnk" "$taskbarDir\Microsoft Edge.lnk" -Force
        Write-Host "  [OK] Atalho Edge atualizado na barra de tarefas"
    }
} else {
    Write-Host "  [INFO] Perfil aluno ainda nao tem barra configurada - sera atualizado no logon"
}

# Criar atalhos no Desktop do aluno (como admin, antes de bloquear)
$labDesktop = "$labProfile\Desktop"
if (Test-Path $labDesktop) {
    if (Test-Path $chromExe) {
        Copy-Item "$TOOLS_PATH\Google Chrome.lnk" "$labDesktop\Google Chrome.lnk" -Force
        Write-Host "  [OK] Atalho Chrome criado no Desktop"
    }
    if (Test-Path $edgeExe) {
        Copy-Item "$TOOLS_PATH\Microsoft Edge.lnk" "$labDesktop\Microsoft Edge.lnk" -Force
        Write-Host "  [OK] Atalho Edge criado no Desktop"
    }

    # =========================
    # BLOQUEAR DESKTOP - apenas admin pode adicionar ou remover atalhos
    # Nega CreateFiles e Delete para o aluno na pasta Desktop
    # =========================
    Write-Host "Bloqueando Desktop para $LAB_USER..."

    $acl = Get-Acl $labDesktop

    # Desativar heranca e manter permissoes atuais
    $acl.SetAccessRuleProtection($true, $true)

    # Negar criacao de arquivos/pastas e exclusao para o aluno
    $deny = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $LAB_USER,
        [System.Security.AccessControl.FileSystemRights]"CreateFiles,CreateDirectories,Delete,DeleteSubdirectoriesAndFiles,WriteData,AppendData",
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit",
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Deny
    )
    $acl.AddAccessRule($deny)
    Set-Acl -Path $labDesktop -AclObject $acl
    Write-Host "  [OK] Desktop bloqueado - alunos nao podem adicionar ou remover atalhos"
} else {
    Write-Host "  [INFO] Desktop do aluno nao encontrado - sera configurado no proximo logon via tarefa"
}

# =========================
# 2. SCRIPT DE LIMPEZA
# =========================

$cleanup = @'
$TOOLS_PATH = "C:\LabTools"
$HOME_URL   = "https://portal.exemplo.edu.br"

$chromExe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
if (!(Test-Path $chromExe)) { $chromExe = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }

$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (!(Test-Path $edgeExe)) { $edgeExe = "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe" }

# Recriar atalhos do zero com URL embutida (garante que sempre terao a URL correta)
$wsh = New-Object -ComObject WScript.Shell

if (Test-Path $chromExe) {
    $lnk = $wsh.CreateShortcut("$TOOLS_PATH\Google Chrome.lnk")
    $lnk.TargetPath   = $chromExe
    $lnk.Arguments    = "--incognito `"$HOME_URL`""
    $lnk.IconLocation = "$chromExe,0"
    $lnk.Save()
}

if (Test-Path $edgeExe) {
    $lnk = $wsh.CreateShortcut("$TOOLS_PATH\Microsoft Edge.lnk")
    $lnk.TargetPath   = $edgeExe
    $lnk.Arguments    = "--inprivate `"$HOME_URL`""
    $lnk.IconLocation = "$edgeExe,0"
    $lnk.Save()
}

# Copiar atalhos atualizados para a barra de tarefas
$taskbarDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
if (!(Test-Path $taskbarDir)) { New-Item -ItemType Directory -Path $taskbarDir -Force | Out-Null }

if (Test-Path "$TOOLS_PATH\Google Chrome.lnk") {
    Copy-Item "$TOOLS_PATH\Google Chrome.lnk" "$taskbarDir\Google Chrome.lnk" -Force
}
if (Test-Path "$TOOLS_PATH\Microsoft Edge.lnk") {
    Copy-Item "$TOOLS_PATH\Microsoft Edge.lnk" "$taskbarDir\Microsoft Edge.lnk" -Force
}

# Limpar historico e cache
$chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$edge   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

Remove-Item "$chrome\Default\History*" -Force -ErrorAction SilentlyContinue
Remove-Item "$chrome\Default\Cookies*" -Force -ErrorAction SilentlyContinue
Remove-Item "$edge\Default\History*"   -Force -ErrorAction SilentlyContinue
Remove-Item "$edge\Default\Cookies*"   -Force -ErrorAction SilentlyContinue

Remove-Item "$chrome\Default\Cache" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$edge\Default\Cache"   -Recurse -Force -ErrorAction SilentlyContinue


'@

$cleanup | Out-File "$TOOLS_PATH\cleanup.ps1" -Encoding UTF8 -Force

# =========================
# 3. TAREFA AGENDADA
# =========================

Write-Host "Criando tarefa..."

$taskName = "LabCleanup"

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$TOOLS_PATH\cleanup.ps1`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

$principal = New-ScheduledTaskPrincipal -UserId $LAB_USER -LogonType Interactive

Register-ScheduledTask `
  -TaskName $taskName `
  -Action $action `
  -Trigger $trigger `
  -Principal $principal `
  -Force

Write-Host "Concluído."
pause
