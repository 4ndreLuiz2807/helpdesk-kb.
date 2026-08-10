<#
.SYNOPSIS
    Limpa a fila de impressao travada e reinicia o servico de Spooler.
.DESCRIPTION
    Para o servico de Spooler, remove todos os jobs pendentes na pasta de
    spool, e reinicia o servico. Precisa ser executado como Administrador.
.EXAMPLE
    .\limpar-fila-impressao.ps1
#>

Write-Host "Parando o servico de Spooler de Impressao..." -ForegroundColor Yellow
Stop-Service -Name Spooler -Force -ErrorAction Stop

Write-Host "Limpando arquivos pendentes na fila..." -ForegroundColor Yellow
$spoolPath = "$Env:SystemRoot\System32\spool\PRINTERS"
if (Test-Path $spoolPath) {
    Remove-Item "$spoolPath\*" -Force -ErrorAction SilentlyContinue
    Write-Host "Fila limpa: $spoolPath" -ForegroundColor Green
} else {
    Write-Host "Caminho de spool nao encontrado: $spoolPath" -ForegroundColor Red
}

Write-Host "Reiniciando o servico de Spooler..." -ForegroundColor Yellow
Start-Service -Name Spooler

$status = Get-Service -Name Spooler
Write-Host "`nStatus final do Spooler: $($status.Status)" -ForegroundColor Cyan
