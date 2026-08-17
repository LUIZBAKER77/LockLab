# =========================
# ANTIDOTO - RESTAURAR SISTEMA
# =========================

$ErrorActionPreference = "SilentlyContinue"

$LAB_USER   = "DOMINIO\aluno"
$TOOLS_PATH = "C:\LabTools"

Write-Host "Iniciando limpeza..."

# =========================
# 1. REMOVER POLÍTICAS
# =========================

Write-Host "Removendo políticas..."

Remove-Item "HKLM:\SOFTWARE\Policies\Google\Chrome" -Recurse -Force
Remove-Item "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -Force

# =========================
# 2. REMOVER TAREFA AGENDADA
# =========================

Write-Host "Removendo tarefa agendada..."

Unregister-ScheduledTask -TaskName "LabCleanup" -Confirm:$false

# =========================
# 3. RESTAURAR PERMISSÕES DO DESKTOP
# =========================

$labDesktop = "C:\Users\aluno\Desktop"

if (Test-Path $labDesktop) {
    Write-Host "Restaurando permissões do Desktop..."

    $acl = Get-Acl $labDesktop

    # Reativar herança padrão
    $acl.SetAccessRuleProtection($false, $true)

    # Remover regras de negação
    $acl.Access | Where-Object {
        $_.IdentityReference -like "*aluno*" -and $_.AccessControlType -eq "Deny"
    } | ForEach-Object {
        $acl.RemoveAccessRule($_)
    }

    Set-Acl -Path $labDesktop -AclObject $acl
}

# =========================
# 4. REMOVER ATALHOS CRIADOS
# =========================

Write-Host "Removendo atalhos..."

Remove-Item "$TOOLS_PATH\Google Chrome.lnk" -Force
Remove-Item "$TOOLS_PATH\Microsoft Edge.lnk" -Force

Remove-Item "C:\Users\aluno\Desktop\Google Chrome.lnk" -Force
Remove-Item "C:\Users\aluno\Desktop\Microsoft Edge.lnk" -Force

$taskbarDir = "C:\Users\aluno\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

Remove-Item "$taskbarDir\Google Chrome.lnk" -Force
Remove-Item "$taskbarDir\Microsoft Edge.lnk" -Force

# =========================
# 5. REMOVER PASTA E SCRIPT
# =========================

Write-Host "Removendo arquivos do sistema..."

Remove-Item $TOOLS_PATH -Recurse -Force

# =========================
# FINAL
# =========================

Write-Host "Sistema restaurado. Reinicie o computador."
pause
