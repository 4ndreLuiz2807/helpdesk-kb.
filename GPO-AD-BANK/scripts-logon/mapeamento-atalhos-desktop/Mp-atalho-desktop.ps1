<#
.SINOPSE
    Cria atalhos na área de trabalho do usuário para cada arquivo presente
    em uma pasta de origem (geralmente um compartilhamento de rede mapeado
    via GPO).

.USO VIA GPO
    Configuração do Usuário > Políticas > Configurações do Windows >
    Scripts > Logon. Aponte para este .ps1. A pasta indicada em
    $PastaOrigem deve estar na mesma pasta de rede onde este script
    está publicado (ou em outro caminho UNC acessível pelo usuário).

.OBSERVAÇÕES
    - Não recria atalhos que já existem no Desktop (evita duplicar a cada
      logon).
    - IconLocation usa o próprio arquivo como fonte do ícone; para atalhos
      de executáveis (.exe) o ícone vem correto automaticamente. Para
      outros tipos de arquivo (.pdf, .docx etc.) o Windows usa o ícone
      padrão do tipo de arquivo.
#>

# ================== CONFIGURAÇÃO — AJUSTE AQUI ==================
$PastaOrigem = "\\server\compartilhamento\AtalhosDesktop"
# ==================================================================

$Desktop = [Environment]::GetFolderPath("Desktop")
$Shell   = New-Object -ComObject WScript.Shell

if (-not (Test-Path -Path $PastaOrigem)) {
    Write-Warning "Pasta de origem inacessível: $PastaOrigem"
    exit 1
}

Get-ChildItem -Path $PastaOrigem -File | ForEach-Object {

    $NomeAtalho    = "$($_.BaseName).lnk"
    $CaminhoAtalho = Join-Path $Desktop $NomeAtalho

    if (Test-Path -Path $CaminhoAtalho) {
        Write-Host "Atalho já existe: $NomeAtalho"
        return
    }

    try {
        $Atalho = $Shell.CreateShortcut($CaminhoAtalho)
        $Atalho.TargetPath       = $_.FullName
        $Atalho.WorkingDirectory = $_.DirectoryName
        $Atalho.IconLocation     = "$($_.FullName),0"
        $Atalho.Save()

        Write-Host "Criado: $NomeAtalho"
    }
    catch {
        Write-Warning "Falha ao criar atalho para $($_.Name): $_"
    }
}
