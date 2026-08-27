
# 🖨️ Deploy de Impressora TCP/IP via GPO

Este documento descreve como realizar o deploy de uma **impressora de rede diretamente pelo endereço IP utilizando GPO**, sem depender de servidor de impressão ou fila compartilhada.

A configuração utiliza uma **GPO de Computador + script PowerShell** para criar a porta TCP/IP e adicionar a impressora automaticamente nas estações.

## 📌 Cenário utilizado neste exemplo

| Configuração          | Valor                                       |
| --------------------- | ------------------------------------------- |
| Endereço IP           | `192.168.60.35`                             |
| Nome da impressora    | `Impressora_Faturamento`                    |
| Driver                | `HP Color LaserJet Pro M478f-9f PCL-6 (V4)` |
| Nome da porta         | `IP_192.168.60.35`                          |
| Tipo                  | TCP/IP                                      |
| Compartilhamento      | Não                                         |
| Servidor de impressão | Não                                         |

A comunicação ocorre diretamente entre a estação e a impressora:

```text
Computador
    │
    │ TCP/IP
    ▼
192.168.60.35
    │
    ▼
Impressora
```

Não é utilizado:

```text
\\Servidor\Impressora
```

---

# ⚠️ CAMPOS QUE DEVEM SER ALTERADOS

Antes de utilizar o script em outro ambiente ou para outra impressora, altere obrigatoriamente as variáveis abaixo:

```powershell
$PrinterName = "Impressora_Faturamento"
$PrinterIP   = "192.168.60.35"
$PortName    = "IP_192.168.60.35"
$DriverName  = "HP Color LaserJet Pro M478f-9f PCL-6 (V4)"
```

### 🔴 `$PrinterName`

Nome que será exibido para o usuário no Windows.

Exemplo:

```powershell
$PrinterName = "Impressora_Faturamento"
```

Para outra impressora:

```powershell
$PrinterName = "Impressora_RH"
```

---

### 🔴 `$PrinterIP`

Endereço IP real da impressora na rede.

Exemplo:

```powershell
$PrinterIP = "192.168.60.35"
```

Para outra infraestrutura:

```powershell
$PrinterIP = "10.10.20.50"
```

---

### 🔴 `$PortName`

Nome da porta TCP/IP que será criada no Windows.

Recomenda-se utilizar o padrão:

```text
IP_ENDERECO-DA-IMPRESSORA
```

Exemplo:

```powershell
$PortName = "IP_192.168.60.35"
```

Para uma impressora `10.10.20.50`:

```powershell
$PortName = "IP_10.10.20.50"
```

---

### 🔴 `$DriverName`

Este é um dos campos **mais importantes**.

O valor precisa corresponder **exatamente ao nome do driver instalado no Windows**.

Neste ambiente:

```powershell
$DriverName = "HP Color LaserJet Pro M478f-9f PCL-6 (V4)"
```

Para descobrir o nome correto do driver:

```powershell
Get-PrinterDriver | Select-Object Name
```

Ou, em uma máquina onde a impressora já está instalada:

```powershell
Get-Printer |
Format-Table Name,DriverName,PortName -AutoSize
```

Exemplo de resultado:

```text
Name                  DriverName                                  PortName
----                  ----------                                  --------
Impressora_Faturamento HP Color LaserJet Pro M478f-9f PCL-6 (V4) IP_192.168.60.35
```

> ⚠️ **IMPORTANTE:** O script apresentado neste documento pressupõe que o driver da impressora já esteja instalado no computador.

---

# 📜 Script PowerShell

Salve o conteúdo abaixo como:

```text
Install-Printer-Faturamento.ps1
```

```powershell
# ============================================================
# DEPLOY DE IMPRESSORA TCP/IP VIA GPO
# ============================================================
#
# IMPORTANTE:
# Altere as quatro variaveis abaixo de acordo com
# a infraestrutura e o modelo da impressora.
#
# ============================================================


# ============================================================
# ALTERAR CONFORME A INFRAESTRUTURA
# ============================================================

$PrinterName = "Impressora_Faturamento"                  # ALTERAR
$PrinterIP   = "192.168.60.35"                           # ALTERAR
$PortName    = "IP_192.168.60.35"                        # ALTERAR
$DriverName  = "HP Color LaserJet Pro M478f-9f PCL-6 (V4)" # ALTERAR


# ============================================================
# NAO E NECESSARIO ALTERAR ABAIXO DESTA LINHA
# ============================================================

Write-Output "==========================================="
Write-Output "Configurando impressora: $PrinterName"
Write-Output "IP: $PrinterIP"
Write-Output "==========================================="


# ------------------------------------------------------------
# 1. Verificar driver
# ------------------------------------------------------------

$Driver = Get-PrinterDriver `
    -Name $DriverName `
    -ErrorAction SilentlyContinue

if (-not $Driver) {

    Write-Error "ERRO: Driver nao encontrado."
    Write-Error "Driver esperado: $DriverName"

    exit 1
}

Write-Output "Driver localizado."


# ------------------------------------------------------------
# 2. Criar porta TCP/IP
# ------------------------------------------------------------

$ExistingPort = Get-PrinterPort `
    -Name $PortName `
    -ErrorAction SilentlyContinue

if (-not $ExistingPort) {

    Write-Output "Criando porta TCP/IP..."

    Add-PrinterPort `
        -Name $PortName `
        -PrinterHostAddress $PrinterIP

    Write-Output "Porta criada."
}
else {

    Write-Output "Porta ja existente."
}


# ------------------------------------------------------------
# 3. Criar impressora
# ------------------------------------------------------------

$ExistingPrinter = Get-Printer `
    -Name $PrinterName `
    -ErrorAction SilentlyContinue

if (-not $ExistingPrinter) {

    Write-Output "Criando impressora..."

    Add-Printer `
        -Name $PrinterName `
        -DriverName $DriverName `
        -PortName $PortName

    Write-Output "Impressora criada."
}
else {

    Write-Output "Impressora ja existente."
}


# ------------------------------------------------------------
# 4. Validar instalacao
# ------------------------------------------------------------

$Printer = Get-Printer `
    -Name $PrinterName `
    -ErrorAction SilentlyContinue

if ($Printer) {

    Write-Output ""
    Write-Output "==========================================="
    Write-Output "INSTALACAO CONCLUIDA"
    Write-Output "==========================================="
    Write-Output "Nome:   $($Printer.Name)"
    Write-Output "Driver: $($Printer.DriverName)"
    Write-Output "Porta:  $($Printer.PortName)"
    Write-Output "IP:     $PrinterIP"
    Write-Output "==========================================="

    exit 0
}
else {

    Write-Error "Falha ao criar a impressora."

    exit 1
}
```

---

# 🔍 Pré-requisitos

Antes da implantação, valide:

* [ ] A estação consegue alcançar o IP da impressora.
* [ ] O driver está instalado no computador.
* [ ] O nome utilizado em `$DriverName` corresponde exatamente ao driver instalado.
* [ ] A porta TCP/IP não está sendo utilizada incorretamente por outra impressora.
* [ ] O computador está dentro da OU onde a GPO será vinculada.
* [ ] A GPO está sendo aplicada ao objeto de **computador**.

Para testar comunicação:

```powershell
Test-Connection 192.168.60.35
```

Também é possível testar a porta RAW 9100:

```powershell
Test-NetConnection 192.168.60.35 -Port 9100
```

Resultado esperado:

```text
TcpTestSucceeded : True
```

> O endereço IP dos comandos acima também deve ser alterado conforme a infraestrutura.

---

# 🧪 Testar o script manualmente

Antes de distribuir via GPO, recomenda-se testar em uma única estação.

Abra o PowerShell como **Administrador** e execute:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Execute:

```powershell
.\Install-Printer-Faturamento.ps1
```

Depois valide:

```powershell
Get-Printer -Name "Impressora_Faturamento"
```

Verifique também a porta:

```powershell
Get-PrinterPort -Name "IP_192.168.60.35"
```

---

# 🏢 Criando a GPO

No servidor com o **Group Policy Management**, execute:

```text
gpmc.msc
```

Crie uma nova GPO.

Exemplo:

```text
GPO-IMPRESSORA-FATURAMENTO
```

Vincule a GPO à OU que contém os **computadores** que deverão receber a impressora.

---

# ⚙️ Configurando o script na GPO

Edite a GPO e navegue até:

```text
Configuração do Computador
└── Políticas
    └── Configurações do Windows
        └── Scripts
            └── Inicialização
```

Adicione:

```text
Install-Printer-Faturamento.ps1
```

A utilização em **Configuração do Computador** permite que o script seja executado no contexto da máquina durante a inicialização.

---

# 🔄 Forçar atualização da GPO

Na estação de teste:

```cmd
gpupdate /force
```

Para confirmar se a GPO foi aplicada:

```cmd
gpresult /r /scope computer
```

Ou gerar um relatório HTML:

```cmd
gpresult /h C:\Temp\GPO.html
```

Após a aplicação, pode ser necessário reiniciar a estação para que o script de inicialização seja executado:

```cmd
shutdown /r /t 0
```

---

# 🔎 Validando a instalação

Depois que a máquina reiniciar:

```powershell
Get-Printer |
Where-Object {$_.Name -eq "Impressora_Faturamento"} |
Format-Table Name,DriverName,PortName
```

Resultado esperado:

```text
Name                   DriverName                                  PortName
----                   ----------                                  --------
Impressora_Faturamento HP Color LaserJet Pro M478f-9f PCL-6 (V4)  IP_192.168.60.35
```

Para verificar a porta:

```powershell
Get-PrinterPort -Name "IP_192.168.60.35" |
Select-Object Name,PrinterHostAddress
```

Resultado esperado:

```text
Name                PrinterHostAddress
----                ------------------
IP_192.168.60.35    192.168.60.35
```

---

# 🛠️ Utilizando em outras impressoras

Para reutilizar o mesmo script, normalmente basta alterar **somente estas quatro variáveis**:

```powershell
# ============================================================
# ALTERAR CONFORME A INFRAESTRUTURA
# ============================================================

$PrinterName = "NOME_DA_IMPRESSORA"
$PrinterIP   = "IP_DA_IMPRESSORA"
$PortName    = "IP_IP_DA_IMPRESSORA"
$DriverName  = "NOME_EXATO_DO_DRIVER"
```

Exemplo:

```powershell
$PrinterName = "Impressora_RH"
$PrinterIP   = "192.168.10.50"
$PortName    = "IP_192.168.10.50"
$DriverName  = "NOME EXATO DO DRIVER"
```

Todo o restante do script pode permanecer igual.

---

# ⚠️ Tratamento do driver

Este procedimento **não realiza automaticamente a instalação do driver**.

Caso o driver abaixo:

```text
HP Color LaserJet Pro M478f-9f PCL-6 (V4)
```

não esteja instalado na estação, o script será encerrado com erro antes de criar a impressora.

Para verificar:

```powershell
Get-PrinterDriver |
Where-Object {$_.Name -like "*M478*"}
```

Em ambientes onde o driver não está previamente instalado, recomenda-se criar uma etapa adicional para distribuição do driver antes da criação da impressora.

---

# 📁 Estrutura sugerida para o GitHub

```text
GPO-Impressora-TCPIP/
│
├── README.md
│
└── Scripts/
    └── Install-Printer-Faturamento.ps1
```

---

## ✅ Resultado

Após a aplicação da GPO, cada computador terá uma impressora local:

```text
Impressora_Faturamento
```

utilizando:

```text
Driver
   │
   ▼
HP Color LaserJet Pro M478f-9f PCL-6 (V4)
   │
   ▼
IP_192.168.60.35
   │
   ▼
192.168.60.35
```

Dessa forma, a impressão ocorre **diretamente entre a estação e a impressora TCP/IP**, sem necessidade de:

```text
\\Servidor\FilaDeImpressao
```

e sem dependência de um servidor de impressão para processar os trabalhos.
