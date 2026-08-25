
# 🗑️ Limpeza Completa do Oracle no Windows

Este procedimento realiza a **remoção completa de componentes Oracle instalados em uma máquina Windows**, incluindo Oracle Database, Oracle Client e demais componentes que utilizem os diretórios, serviços, registros e variáveis tratados pelo script.

O script foi criado principalmente para **máquinas de teste, laboratório ou equipamentos que precisam receber uma nova instalação limpa do Oracle**.

> ⚠️ **ATENÇÃO**
>
> Este procedimento é destrutivo.
>
> Ele remove diretórios, serviços, registros e variáveis relacionados ao Oracle. Utilize somente quando tiver certeza de que **nenhum componente Oracle deve permanecer instalado na máquina**.
>
> Não utilize em servidores de produção sem avaliar previamente o impacto.

---

## 📋 O que o script remove

O procedimento realiza:

- Encerramento de processos relacionados ao Oracle
- Parada dos serviços Oracle
- Exclusão dos serviços Oracle
- Remoção dos diretórios Oracle
- Remoção das chaves Oracle do Registro do Windows
- Remoção das variáveis de ambiente Oracle
- Limpeza das referências Oracle no `PATH`
- Validação final da remoção

---

# 1. Executar o PowerShell como Administrador

Abra o menu **Iniciar**, procure por:

```text
PowerShell
```

Clique com o botão direito e selecione:

```text
Executar como administrador
```

O script precisa de privilégios administrativos para remover serviços, diretórios protegidos, registros e variáveis de ambiente da máquina.

---

# 2. Script de limpeza

Salve o conteúdo abaixo como:

```text
Remove-Oracle.ps1
```

```powershell
# ============================================================
# LIMPEZA COMPLETA DO ORACLE - MAQUINA DE TESTE
# Execute PowerShell como Administrador
# ============================================================

Write-Host "=== 1. Encerrando processos Oracle ===" -ForegroundColor Cyan

Get-Process -ErrorAction SilentlyContinue |
Where-Object {
    $_.ProcessName -match 'oracle|oui|sqlplus|tnslsnr|java'
} |
Stop-Process -Force -ErrorAction SilentlyContinue


Write-Host "=== 2. Parando e removendo servicos Oracle ===" -ForegroundColor Cyan

$OracleServices = Get-Service -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -match '^Oracle' -or $_.DisplayName -match '^Oracle'
}

foreach ($Service in $OracleServices) {

    Write-Host "Removendo servico: $($Service.Name)"

    Stop-Service -Name $Service.Name -Force -ErrorAction SilentlyContinue

    sc.exe delete $Service.Name | Out-Null
}


Write-Host "=== 3. Removendo diretorios Oracle ===" -ForegroundColor Cyan

$Folders = @(
    "C:\oracle",
    "C:\app",
    "C:\Program Files\Oracle",
    "C:\Program Files (x86)\Oracle"
)

foreach ($Folder in $Folders) {

    if (Test-Path $Folder) {

        Write-Host "Removendo: $Folder"

        takeown.exe /F "$Folder" /R /D Y | Out-Null

        icacls.exe "$Folder" /grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q | Out-Null

        Remove-Item $Folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}


Write-Host "=== 4. Removendo registro Oracle ===" -ForegroundColor Cyan

$RegistryPaths = @(
    "HKLM:\SOFTWARE\Oracle",
    "HKLM:\SOFTWARE\WOW6432Node\Oracle"
)

foreach ($Reg in $RegistryPaths) {

    if (Test-Path $Reg) {

        Write-Host "Removendo: $Reg"

        Remove-Item $Reg -Recurse -Force -ErrorAction SilentlyContinue
    }
}


Write-Host "=== 5. Removendo variaveis Oracle ===" -ForegroundColor Cyan

$EnvironmentVariables = @(
    "ORACLE_HOME",
    "ORACLE_BASE",
    "TNS_ADMIN"
)

foreach ($Variable in $EnvironmentVariables) {

    [Environment]::SetEnvironmentVariable(
        $Variable,
        $null,
        "Machine"
    )
}


Write-Host "=== 6. Limpando Oracle do PATH da maquina ===" -ForegroundColor Cyan

$MachinePath = [Environment]::GetEnvironmentVariable("Path","Machine")

$NewPath = ($MachinePath -split ";" |
Where-Object {
    $_ -and $_ -notmatch '(?i)\\oracle\\|\\app\\.*\\product\\.*\\client'
}) -join ";"

[Environment]::SetEnvironmentVariable(
    "Path",
    $NewPath,
    "Machine"
)


Write-Host "=== 7. VALIDACAO ===" -ForegroundColor Yellow

Write-Host ""
Write-Host "C:\oracle:"
Test-Path "C:\oracle"

Write-Host "C:\app:"
Test-Path "C:\app"

Write-Host "C:\Program Files\Oracle:"
Test-Path "C:\Program Files\Oracle"

Write-Host "C:\Program Files (x86)\Oracle:"
Test-Path "C:\Program Files (x86)\Oracle"

Write-Host "Registro Oracle x64:"
Test-Path "HKLM:\SOFTWARE\Oracle"

Write-Host "Registro Oracle x86:"
Test-Path "HKLM:\SOFTWARE\WOW6432Node\Oracle"

Write-Host ""
Write-Host "Servicos Oracle:"
Get-Service -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -match '^Oracle' -or $_.DisplayName -match '^Oracle'
}

Write-Host ""
Write-Host "sqlplus no PATH:"
where.exe sqlplus

Write-Host ""
Write-Host "=== LIMPEZA FINALIZADA ===" -ForegroundColor Green
```

---

# 3. Executar o script

Acesse pelo PowerShell a pasta onde o arquivo foi salvo.

Exemplo:

```powershell
cd C:\DeployOracle
```

Caso a política de execução esteja bloqueando scripts, para esta sessão do PowerShell pode ser utilizado:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Execute:

```powershell
.\Remove-Oracle.ps1
```

---

# 4. Processos encerrados

O script procura processos cujo nome corresponda a:

```text
oracle
oui
sqlplus
tnslsnr
java
```

Quando encontrados, eles são encerrados utilizando:

```powershell
Stop-Process -Force
```

Isso ajuda principalmente quando a exclusão retorna erros semelhantes a:

```text
The process cannot access the file because it is being used by another process.
```

---

# 5. Serviços Oracle

Todos os serviços cujo nome ou nome de exibição comece com `Oracle` são identificados.

Exemplo:

```powershell
Get-Service |
Where-Object {
    $_.Name -match '^Oracle' -or $_.DisplayName -match '^Oracle'
}
```

O script então:

1. Para o serviço.
2. Remove o serviço do Windows.

A exclusão é realizada através de:

```powershell
sc.exe delete $Service.Name
```

---

# 6. Diretórios removidos

Os seguintes diretórios são tratados:

```text
C:\oracle
C:\app
C:\Program Files\Oracle
C:\Program Files (x86)\Oracle
```

Antes da exclusão, o script assume a propriedade dos arquivos:

```powershell
takeown.exe
```

Em seguida concede controle total ao grupo local de administradores:

```powershell
icacls.exe
```

Finalmente executa:

```powershell
Remove-Item -Recurse -Force
```

Isso ajuda na remoção de arquivos protegidos ou pertencentes aos serviços Oracle.

---

# 7. Registro do Windows

São removidas as seguintes árvores:

```text
HKEY_LOCAL_MACHINE\SOFTWARE\Oracle
```

e:

```text
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Oracle
```

Correspondentes no PowerShell:

```powershell
HKLM:\SOFTWARE\Oracle
HKLM:\SOFTWARE\WOW6432Node\Oracle
```

---

# 8. Variáveis de ambiente

O script remove as variáveis de máquina:

```text
ORACLE_HOME
ORACLE_BASE
TNS_ADMIN
```

Isso evita que aplicações continuem tentando utilizar uma instalação Oracle que já foi removida.

---

# 9. Limpeza do PATH

Também são removidas do `PATH` da máquina referências correspondentes a diretórios Oracle.

Exemplos:

```text
C:\oracle\product\19.0.0\client_x64\bin
```

ou estruturas semelhantes em:

```text
C:\app\...\product\...\client...
```

---

# 10. Validação

Ao final, o próprio script verifica os principais diretórios e registros.

Para:

```powershell
Test-Path "C:\oracle"
```

o resultado esperado é:

```text
False
```

O mesmo deve ocorrer para os demais diretórios removidos.

### Verificar serviços

Também pode ser executado manualmente:

```powershell
Get-Service -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -match '^Oracle' -or $_.DisplayName -match '^Oracle'
}
```

Se nenhum serviço Oracle permanecer, o comando não deverá retornar resultados.

### Verificar SQL*Plus

Execute:

```powershell
where.exe sqlplus
```

Se a remoção foi concluída e não existe outro Oracle Client instalado, o executável não deverá ser encontrado.

### Verificar variáveis Oracle

```powershell
Get-ChildItem Env: |
Where-Object Name -match 'ORACLE|TNS'
```

Após abrir uma **nova sessão do PowerShell**, não devem existir as variáveis removidas.

---

# 11. Reiniciar a máquina

Após concluir a limpeza, é recomendado reiniciar o Windows:

```powershell
Restart-Computer
```

A reinicialização garante que processos antigos sejam encerrados e que as alterações de variáveis de ambiente e `PATH` sejam carregadas corretamente.

---

# ⚠️ Observações importantes

Este script não deve ser tratado como um desinstalador oficial da Oracle.

Ele realiza uma **limpeza forçada do ambiente** e é indicado principalmente para:

- máquinas de laboratório;
- máquinas de teste;
- estações com instalação Oracle corrompida;
- preparação para reinstalação limpa;
- remoção de Oracle Database/Client que não será mais utilizado.

Tenha atenção especial ao diretório:

```text
C:\app
```

Esse diretório pode conter diferentes Oracle Homes, bancos, clientes ou outros componentes Oracle.

O script remove **todo o diretório `C:\app`**.

Também tenha atenção ao processo:

```text
java.exe
```

O script original encerra processos que contenham `java` no nome. Caso existam outras aplicações Java sendo executadas na máquina, elas também poderão ser encerradas durante o procedimento.

---

## 📂 Estrutura sugerida para o repositório

```text
ORACLE/
│
├── REMOCAO/
│   ├── Remove-Oracle.ps1
│   └── README.md
│
└── README.md
```

---

## Objetivo

Manter um procedimento documentado e reproduzível para realizar a limpeza de instalações Oracle em estações Windows antes de uma reinstalação ou novo processo de deploy.

---

**Ambiente:** Windows  
**Shell:** PowerShell  
**Execução:** Administrador  
**Finalidade:** Remoção completa / Troubleshooting / Preparação para novo deploy
