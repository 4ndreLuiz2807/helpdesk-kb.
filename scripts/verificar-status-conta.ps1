<#
.SYNOPSIS
    Verifica status de conta de usuario no Active Directory e/ou Entra ID.
.DESCRIPTION
    Consulta bloqueio, expiracao de senha e habilitacao da conta, tanto no
    AD local (ambiente Hybrid) quanto no Entra ID via Microsoft Graph.
    Requer o modulo ActiveDirectory (RSAT) e/ou Microsoft.Graph conforme
    o ambiente.
.EXAMPLE
    .\verificar-status-conta.ps1 -Usuario "jsilva"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Usuario
)

Write-Host "=== Verificacao de status: $Usuario ===" -ForegroundColor Cyan

if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Host "`n[AD Local]" -ForegroundColor Yellow
    try {
        Get-ADUser -Identity $Usuario -Properties LockedOut, PasswordExpired, Enabled, LastLogonDate |
            Format-List Name, Enabled, LockedOut, PasswordExpired, LastLogonDate
    } catch {
        Write-Host "Usuario nao encontrado no AD local ou modulo sem conexao com o dominio." -ForegroundColor Red
    }
} else {
    Write-Host "`nModulo ActiveDirectory (RSAT) nao instalado - pulando verificacao local." -ForegroundColor DarkGray
}

if (Get-Module -ListAvailable -Name Microsoft.Graph.Users) {
    Write-Host "`n[Entra ID]" -ForegroundColor Yellow
    try {
        Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
        $mgUser = Get-MgUser -UserId $Usuario -Property DisplayName, AccountEnabled, SignInActivity
        $mgUser | Format-List DisplayName, AccountEnabled
        if ($mgUser.SignInActivity) {
            "Ultimo login: $($mgUser.SignInActivity.LastSignInDateTime)"
        }
    } catch {
        Write-Host "Nao foi possivel consultar o Entra ID. Verifique conexao/permissoes." -ForegroundColor Red
    }
} else {
    Write-Host "`nModulo Microsoft.Graph.Users nao instalado - pulando verificacao no Entra ID." -ForegroundColor DarkGray
}
