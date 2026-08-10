<#
.SYNOPSIS
    Testa conectividade basica de rede usada para diagnostico de VPN/Exchange Online.
.DESCRIPTION
    Verifica resolucao DNS e conectividade TCP nas portas comumente usadas por
    VPN (L2TP/IPsec: UDP 500/4500) e Exchange Online (TCP 443), alem de teste
    generico de ping. Usar como primeiro passo de diagnostico antes de escalonar.
.EXAMPLE
    .\testar-conectividade-vpn.ps1 -ServidorVPN "vpn.labtask.online"
#>

param(
    [string]$ServidorVPN = "vpn.labtask.online",
    [string]$ExchangeOnlineHost = "outlook.office365.com"
)

Write-Host "=== Teste de conectividade basica ===" -ForegroundColor Cyan

Write-Host "`n[1] Testando DNS..." -ForegroundColor Yellow
try {
    Resolve-DnsName -Name $ServidorVPN -ErrorAction Stop | Format-Table Name, IPAddress
} catch {
    Write-Host "FALHA: nao foi possivel resolver $ServidorVPN" -ForegroundColor Red
}

Write-Host "`n[2] Testando ping para o servidor VPN..." -ForegroundColor Yellow
Test-Connection -ComputerName $ServidorVPN -Count 3 -ErrorAction SilentlyContinue |
    Format-Table Address, ResponseTime, StatusCode

Write-Host "`n[3] Testando porta TCP 443 (HTTPS/Exchange Online)..." -ForegroundColor Yellow
$testHttps = Test-NetConnection -ComputerName $ExchangeOnlineHost -Port 443
"$($testHttps.ComputerName):443 -> $($testHttps.TcpTestSucceeded)"

Write-Host "`n[4] Testando porta UDP 500/4500 (IPsec) no servidor VPN..." -ForegroundColor Yellow
Write-Host "Nota: Test-NetConnection nao testa UDP de forma confiavel; use isso apenas como indicativo de rota."
Test-NetConnection -ComputerName $ServidorVPN -Port 500 -InformationLevel Detailed

Write-Host "`n=== Fim do teste ===" -ForegroundColor Cyan
