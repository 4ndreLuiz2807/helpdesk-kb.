# Redirecionamento Dinâmico de Pastas de Usuário

## Visão geral

Este projeto redireciona automaticamente algumas pastas do perfil do usuário para um disco secundário durante o logon no Windows.

O perfil principal continua em:

```text
C:\Users\<usuario>
```

O script não move o perfil inteiro.

Por padrão, somente estas pastas são redirecionadas:

```text
Downloads
Videos
Music
```

Estas pastas são exceções e permanecem no local atual:

```text
Desktop
Documents
Pictures
```

Também permanecem no disco do sistema:

```text
AppData
NTUSER.DAT
NTUSER.DAT.LOG
ntuser.ini
```

---

# Objetivo

Reduzir o consumo de espaço do disco do Windows, mantendo a estrutura do perfil compatível com o sistema operacional e com os aplicativos.

Exemplo:

```text
Perfil Windows:

C:\Users\thiagomoura
├── AppData
├── Desktop
├── Documents
├── Pictures
├── Downloads
├── Videos
└── Music
```

Após a execução:

```text
C:\Users\thiagomoura
├── AppData
├── Desktop
├── Documents
├── Pictures
├── Downloads   -> Junction
├── Videos      -> Junction
└── Music       -> Junction
```

Os dados redirecionados ficam fisicamente em:

```text
C:\Armazenamento\Usuarios\thiagomoura
├── Downloads
├── Videos
└── Music
```

---

# Funcionamento dinâmico

O nome do usuário é identificado automaticamente por:

```powershell
$env:USERNAME
```

O caminho original do perfil é identificado por:

```powershell
$env:USERPROFILE
```

Exemplo:

```text
Usuário logado:
thiagomoura
```

Destino criado:

```text
C:\Armazenamento\Usuarios\thiagomoura
```

Outro usuário:

```text
andre.neto
```

Destino criado:

```text
C:\Armazenamento\Usuarios\andre.neto
```

Não é necessário informar manualmente o nome de cada usuário.

---

# Estrutura recomendada

## Disco do Windows

```text
C:\
├── Windows
├── Program Files
└── Users
    └── <usuario>
        ├── AppData
        ├── NTUSER.DAT
        ├── Desktop
        ├── Documents
        ├── Pictures
        ├── Downloads
        ├── Videos
        └── Music
```

## Disco secundário

O segundo SSD deve ser montado no caminho configurado no script.

Padrão:

```text
C:\Armazenamento
```

Estrutura:

```text
C:\Armazenamento
└── Usuarios
    └── <usuario>
        ├── Downloads
        ├── Videos
        └── Music
```

---

# Pastas redirecionadas

Por padrão:

```text
Downloads
Videos
Music
```

Essas pastas são movidas para o disco secundário.

O script também altera o caminho das Known Folders do Windows e cria uma Junction no caminho antigo.

Exemplo:

```text
C:\Users\thiagomoura\Downloads
```

aponta para:

```text
C:\Armazenamento\Usuarios\thiagomoura\Downloads
```

Assim, um aplicativo que continuar tentando salvar em:

```text
C:\Users\thiagomoura\Downloads
```

acabará gravando fisicamente no SSD secundário.

---

# Pastas excluídas

As seguintes pastas são exceções permanentes na configuração atual:

```text
Desktop
Documents
Pictures
```

Elas estão definidas nesta variável:

```powershell
$ExcludedFolders = @(
    "Desktop",
    "Documents",
    "Pictures"
)
```

Para essas pastas, o script não realiza:

```text
Movimentação de arquivos
Alteração de Registro
Criação de Junction
Criação da pasta de destino
```

Isso é especialmente útil para evitar conflitos com OneDrive e Known Folder Move.

---

# Como remover uma pasta das exceções

Exemplo: permitir que `Documents` também seja redirecionada.

Configuração atual:

```powershell
$ExcludedFolders = @(
    "Desktop",
    "Documents",
    "Pictures"
)
```

Altere para:

```powershell
$ExcludedFolders = @(
    "Desktop",
    "Pictures"
)
```

Na próxima execução, `Documents` poderá ser processada pelo script.

Faça isso somente após validar que a pasta não está sendo controlada por OneDrive/KFM.

---

# Principal parâmetro para outra máquina

O principal item que deve ser alterado ao utilizar o script em outro computador é:

```powershell
$StorageMount = "C:\Armazenamento"
```

## Exemplo 1

Se o segundo disco estiver montado em:

```text
D:\Armazenamento
```

use:

```powershell
$StorageMount = "D:\Armazenamento"
```

## Exemplo 2

Se quiser utilizar:

```text
D:\Dados
```

use:

```powershell
$StorageMount = "D:\Dados"
```

## Exemplo 3

Se outro computador também utilizar:

```text
C:\Armazenamento
```

nenhuma alteração é necessária.

---

# Padronização recomendada

Para utilizar o mesmo script em várias máquinas, padronize o segundo disco sempre como:

```text
C:\Armazenamento
```

Dessa forma o script pode ser reutilizado independentemente de o computador possuir:

```text
SSD SATA 240 GB
SSD SATA 500 GB
NVMe 1 TB
SSD 2 TB
```

O script não depende de:

```text
Disco 0
Disco 1
Modelo do SSD
Capacidade do SSD
Rótulo do volume
```

Ele depende do caminho configurado em:

```powershell
$StorageMount
```

---

# Nome da pasta raiz dos usuários

O padrão é:

```powershell
$UsersFolderName = "Usuarios"
```

Isso gera:

```text
C:\Armazenamento\Usuarios
```

Se quiser:

```text
C:\Armazenamento\Perfis
```

altere para:

```powershell
$UsersFolderName = "Perfis"
```

---

# Validação do segundo disco

O script pode exigir que o destino esteja em um volume diferente do Windows.

Configuração:

```powershell
$RequireSecondaryVolume = $true
```

Com essa opção habilitada, o script tenta impedir que os dados sejam redirecionados para o mesmo volume físico do sistema.

Não basta criar manualmente uma pasta:

```text
C:\Armazenamento
```

Ela precisa realmente apontar para o SSD secundário, caso essa seja a arquitetura utilizada.

---

# Verificar ponto de montagem

Use:

```powershell
Get-Partition |
Select-Object DiskNumber, PartitionNumber, DriveLetter, AccessPaths |
Format-List
```

O SSD deve mostrar algo semelhante a:

```text
AccessPaths : {C:\Armazenamento\}
```

Também pode ser verificado com:

```cmd
mountvol C:\Armazenamento\ /L
```

Se retornar algo semelhante a:

```text
\\?\Volume{GUID}\
```

há um volume associado ao caminho.

---

# Como o script move os dados

A migração utiliza:

```text
Robocopy
```

com movimentação dos arquivos existentes.

O script considera os códigos do Robocopy:

```text
0 até 7  = sucesso ou diferenças normais
8 ou mais = erro
```

Se ocorrer erro de migração, o Registro não é alterado para aquela pasta.

---

# Junction

Após mover os dados, o script cria uma Junction.

Exemplo:

```text
C:\Users\thiagomoura\Downloads
```

apontando para:

```text
C:\Armazenamento\Usuarios\thiagomoura\Downloads
```

Isso permite manter compatibilidade com aplicativos que ainda utilizem o caminho antigo.

---

# Testar Junctions

Execute:

```cmd
dir C:\Users\%USERNAME% /AL
```

Exemplo esperado:

```text
<JUNCTION> Downloads
           [C:\Armazenamento\Usuarios\thiagomoura\Downloads]

<JUNCTION> Videos
           [C:\Armazenamento\Usuarios\thiagomoura\Videos]

<JUNCTION> Music
           [C:\Armazenamento\Usuarios\thiagomoura\Music]
```

---

# Teste de gravação

Crie um arquivo pelo caminho antigo:

```cmd
echo TESTE > "%USERPROFILE%\Downloads\teste-redirecionamento.txt"
```

Depois verifique:

```powershell
Test-Path "C:\Armazenamento\Usuarios\$env:USERNAME\Downloads\teste-redirecionamento.txt"
```

Esperado:

```text
True
```

Isso confirma que um aplicativo usando o caminho antigo está gravando no novo armazenamento.

---

# Verificar caminho oficial de Downloads

Use:

```powershell
(Get-ItemProperty `
"HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders").'{374DE290-123F-4565-9164-39C4925E467B}'
```

Esperado:

```text
C:\Armazenamento\Usuarios\<usuario>\Downloads
```

---

# Aviso ao usuário

O script exibe uma mensagem informando que algumas pastas foram movidas para o novo armazenamento.

O aviso informa que:

```text
Downloads
Videos
Music
```

passaram a utilizar o disco secundário.

Também informa que:

```text
Desktop
Documents
Pictures
```

não foram alteradas.

O caminho antigo poderá continuar aparecendo no Windows por causa da Junction.

---

# Exibir o aviso novamente

O script controla o aviso através de:

```powershell
$NoticeVersion = 1
```

Para que o aviso seja exibido novamente para os usuários após uma atualização, altere para:

```powershell
$NoticeVersion = 2
```

Depois:

```powershell
$NoticeVersion = 3
```

e assim por diante.

---

# Desabilitar o aviso

Altere:

```powershell
$ShowUserNotice = $true
```

para:

```powershell
$ShowUserNotice = $false
```

---

# Registro utilizado pelo aviso

O controle é salvo em:

```text
HKCU\Software\Bioaroeira\ProfileRedirect
```

Valor:

```text
AvisoVersao
```

Isso é individual para cada usuário.

---

# Local do log

O log é salvo em:

```text
%LOCALAPPDATA%\ProfileRedirect\ProfileRedirect.log
```

Exemplo:

```text
C:\Users\thiagomoura\AppData\Local\ProfileRedirect\ProfileRedirect.log
```

---

# Informações registradas no log

O log registra:

```text
Usuário executando o script
Perfil original
Destino
Validação do volume
Pastas ignoradas
Pastas processadas
Código do Robocopy
Alterações no Registro
Criação das Junctions
Erros
Exibição do aviso
```

---

# Execução no logon

O script deve ser executado no contexto do usuário.

Isso é importante porque utiliza:

```powershell
$env:USERNAME
$env:USERPROFILE
HKCU:
```

Se o script for executado como `SYSTEM`, o contexto poderá ser diferente do usuário interativo.

---

# Formas de distribuição

Pode ser utilizado por:

```text
GPO de Logon
Intune
Tarefa Agendada no logon
Execução manual para homologação
```

---

# Exemplo de execução

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Redirect-UserFolders.ps1"
```

---

# Pastas que não devem ser adicionadas

Não utilize este mecanismo para mover:

```text
AppData
NTUSER.DAT
NTUSER.DAT.LOG
ntuser.ini
ProgramData
Windows
Program Files
```

Não mova o perfil inteiro:

```text
C:\Users\<usuario>
```

O objetivo é manter o perfil original e redirecionar somente as pastas de dados escolhidas.

---

# OneDrive

Desktop, Documents e Pictures estão excluídas justamente para reduzir risco de conflito com:

```text
OneDrive
Known Folder Move
Backup de pastas conhecidas
```

Antes de alterar essas exceções, verifique:

```text
OneDrive
→ Configurações
→ Sincronização e backup
→ Gerenciar backup
```

Se Área de Trabalho, Documentos ou Imagens estiverem sendo protegidas, mantenha essas pastas como exceção.

---

# Resultado esperado

Para:

```text
Usuário: thiagomoura
```

perfil:

```text
C:\Users\thiagomoura
```

destino:

```text
C:\Armazenamento\Usuarios\thiagomoura
```

estrutura final:

```text
C:\Users\thiagomoura
├── AppData
├── Desktop
├── Documents
├── Pictures
├── Downloads  -> Junction
├── Videos     -> Junction
└── Music      -> Junction
```

Dados físicos redirecionados:

```text
C:\Armazenamento\Usuarios\thiagomoura
├── Downloads
├── Videos
└── Music
```

---

# Parâmetros principais

| Finalidade | Variável | Padrão |
|---|---|---|
| Caminho do segundo armazenamento | `$StorageMount` | `C:\Armazenamento` |
| Pasta raiz dos usuários | `$UsersFolderName` | `Usuarios` |
| Exigir outro volume | `$RequireSecondaryVolume` | `$true` |
| Exibir aviso | `$ShowUserNotice` | `$true` |
| Versão do aviso | `$NoticeVersion` | `1` |
| Usuário atual | `$env:USERNAME` | Automático |
| Perfil atual | `$env:USERPROFILE` | Automático |
| Exceções | `$ExcludedFolders` | Desktop, Documents e Pictures |

---

# Checklist de implantação

- [ ] Segundo SSD instalado.
- [ ] Volume em NTFS.
- [ ] Ponto de montagem configurado.
- [ ] Caminho de `$StorageMount` revisado.
- [ ] Confirmado que o armazenamento está em outro volume.
- [ ] Pasta `Usuarios` pode ser criada.
- [ ] Permissões NTFS revisadas.
- [ ] Script testado com usuário de homologação.
- [ ] OneDrive/KFM verificado.
- [ ] Backup dos dados importantes realizado.
- [ ] Logoff/login testado.
- [ ] Reinicialização testada.
- [ ] Downloads validado.
- [ ] Videos validado.
- [ ] Music validado.
- [ ] Junctions verificadas.
- [ ] Consumo de espaço confirmado no SSD secundário.
- [ ] Aviso ao usuário validado.

---

# Recomendação de implantação

Antes de distribuir para vários computadores:

1. Teste em uma única máquina.
2. Utilize um usuário de homologação.
3. Valide Downloads, Videos e Music.
4. Reinicie a máquina.
5. Faça novo logon.
6. Verifique as Junctions.
7. Confirme o espaço usado no SSD secundário.
8. Verifique o log.
9. Somente depois distribua por GPO ou Intune.

---

# Resumo

O script mantém:

```text
C:\Users\<usuario>
```

como perfil oficial do Windows.

Redireciona:

```text
Downloads
Videos
Music
```

para:

```text
C:\Armazenamento\Usuarios\<usuario>
```

Mantém como exceção:

```text
Desktop
Documents
Pictures
```

e preserva:

```text
AppData
NTUSER.DAT
```

no disco do Windows.
