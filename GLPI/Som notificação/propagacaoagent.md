# Implantação do GLPI Agent 1.21 via GPO (MSI + MST)

> **Procedimento validado em laboratório:** distribuição do GLPI Agent por **Instalação de Software da GPO**, com propriedades personalizadas em um arquivo de transformação `.mst` criado no **Microsoft Orca**. Nesta configuração **não é necessário um script PowerShell para instalar o agente**.
>
> **Ambiente de referência:** Active Directory Windows Server; servidor de arquivos `SERVER200`; servidor GLPI `192.168.18.150`; GLPI Agent `1.21` (x64). Adapte nomes e URLs quando replicar em outro ambiente.

## 1. Objetivo e arquitetura

Instalar o GLPI Agent automaticamente nos **computadores pertencentes à OU atendida pela GPO**, sob o contexto do sistema, sem depender de privilégios administrativos dos usuários finais.

```text
Active Directory / GPO
  └── Configuração do Computador
       └── Instalação de Software (Atribuído)
            ├── MSI: \\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi
            └── MST: \\SERVER200\Softwares\GLPI1.21.mst
                 └── SERVER=http://192.168.18.150/front/inventory.php

Computador na OU de destino
  └── Inicialização + acesso à rede do domínio
       └── Windows Installer aplica MSI + MST
            └── Serviço GLPI Agent envia inventário ao GLPI
```

**Ponto decisivo da implantação:** os pacotes de **Instalação de Software** devem ser referenciados por caminhos de rede UNC (`\\servidor\compartilhamento\arquivo`). **Não cadastrar `C:\Softwares\...`** como origem do MSI ou do MST, mesmo que a pasta exista no controlador de domínio ou no servidor de arquivos. Foi essa a correção que permitiu a implantação no teste.

## 2. Informações e parâmetros do ambiente

| Item | Valor utilizado |
| --- | --- |
| Servidor que hospeda os pacotes | `SERVER200` |
| Diretório físico do compartilhamento | `C:\Softwares` no `SERVER200` |
| Nome do compartilhamento SMB | `Softwares` |
| MSI original | `GLPI-Agent-1.21-x64.msi` |
| MST criado no Orca | `GLPI1.21.mst` |
| Caminho UNC do MSI | `\\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi` |
| Caminho UNC do MST | `\\SERVER200\Softwares\GLPI1.21.mst` |
| Servidor de inventário | `http://192.168.18.150/front/inventory.php` |
| Tipo de implantação | **Atribuído**, em **Configuração do Computador** |
| Conta de instalação no cliente | **LocalSystem** / `NT AUTHORITY\SYSTEM` |
| Destino do inventário | GLPI em `192.168.18.150` |

> **URL do GLPI:** o exemplo considera o GLPI instalado na raiz do site. Se ele for acessado em `http://192.168.18.150/glpi/`, ajuste `SERVER` para `http://192.168.18.150/glpi/front/inventory.php`. A URL da interface web e a URL do endpoint de inventário não devem ser confundidas. Em produção, prefira **HTTPS** com certificado confiável.

### Propriedades do MSI personalizadas no MST

| Propriedade | Valor | Finalidade |
| --- | --- | --- |
| `SERVER` | `http://192.168.18.150/front/inventory.php` | Define o destino dos inventários. |
| `EXECMODE` | `1` | Instala o agente no modo **serviço Windows**. |
| `RUNNOW` | `1` | Solicita a execução do agente logo após a instalação. |

Outros modos possíveis para `EXECMODE`: `2` = tarefa agendada; `3` = execução manual. Para este procedimento, manter `1`.

## 3. Preparar o instalador MSI

1. Baixar o instalador oficial **GLPI Agent 1.21 x64** em <https://github.com/glpi-project/glpi-agent/releases/tag/1.21>.
2. Manter uma cópia **original e íntegra** do arquivo `GLPI-Agent-1.21-x64.msi`. **Não renomear outro MSI** para simular a versão 1.21.
3. No `SERVER200`, deixar o MSI em `C:\Softwares`.
4. Opcionalmente, validar a integridade do download antes da implantação:

```powershell
Get-FileHash 'C:\Softwares\GLPI-Agent-1.21-x64.msi' -Algorithm SHA256
```

SHA-256 publicado na página oficial da versão 1.21 para o MSI x64:

```text
152bd777abc5a6d0e8a1f163af25c6b8c166f47895d115076b480863a5f0de6c
```

**Atenção:** no Orca, a tabela `Property` deve mostrar **`ProductName = GLPI Agent 1.21`** e **`ProductVersion = 1.21`**. Nas primeiras tentativas foi aberta uma versão diferente; não alterar manualmente `ProductVersion` para fingir uma atualização.

## 4. Instalar o Microsoft Orca (Windows SDK)

O **Orca** permite criar a transformação do Windows Installer. Ele é instalado a partir dos componentes de desenvolvimento do Windows Installer do **Windows SDK**.

1. Instalar o Windows SDK com os componentes **Windows SDK Components for Windows Installer Developers / MSI Tools**, conforme as opções disponíveis no instalador.
2. Procurar o instalador `Orca-x86_en-us.msi` nos diretórios do kit instalado, normalmente sob `C:\Program Files (x86)\Windows Kits\10\bin` (a localização exata varia conforme o SDK).
3. Para localizar com PowerShell:

```powershell
Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' `
    -Recurse -File -Filter 'Orca*.msi' `
    -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
```

4. Instalar o pacote Orca encontrado, abrir **Orca** pelo menu Iniciar.
5. Não confundir o instalador do Orca com o instalador do GLPI Agent.

Se a pasta do SDK contiver apenas DLLs (por exemplo, `GenXBF.dll`), verifique se o componente MSI Tools foi realmente selecionado no SDK.

## 5. Criar o MST no Orca

> **Não modificar nem sobrescrever o MSI original.** O arquivo `.mst` registra apenas as mudanças de configuração.

1. Abrir **Orca**.
2. Clicar em **File > Open** e abrir uma **cópia** de `GLPI-Agent-1.21-x64.msi`.
3. Selecionar a tabela **`Property`** e validar `ProductName` e `ProductVersion`.
4. Selecionar **Transform > New Transform** **antes de editar qualquer propriedade**.
5. Na tabela **Property**, procurar `SERVER`, `EXECMODE` e `RUNNOW`:
   - Se a propriedade já existir, editar o seu valor.
   - Se não existir, clicar com o botão direito na área das linhas e escolher **Add Row** (`Ctrl + R`).
6. Preencher **exatamente**:

```text
Property  Value
--------  --------------------------------------------------
SERVER    http://192.168.18.150/front/inventory.php
EXECMODE  1
RUNNOW    1
```

7. Conferir se os três valores foram gravados na tabela. As linhas modificadas podem aparecer destacadas no Orca.
8. Clicar em **Transform > Generate Transform**.
9. Salvar com o nome **`GLPI1.21.mst`**.
10. Fechar o Orca **sem executar File > Save no MSI original**.

### Verificações do MST

- O arquivo gerado tem extensão **`.mst`**, não `.msi`.
- O MST corresponde **ao mesmo MSI/versão usado para criá-lo**.
- Um MST não contém o aplicativo inteiro; tamanho isoladamente não comprova que esteja válido ou inválido.
- Em caso de troca do MSI por outra versão/build, recriar e validar a transformação correspondente.
- Se a GPO já foi implantada, não presumir que editar o MST original reconfigurará instalações existentes.

## 6. Compartilhar a pasta de implantação

No `SERVER200`:

1. Criar ou localizar `C:\Softwares`.
2. Abrir **Propriedades > Compartilhamento > Compartilhamento Avançado**.
3. Habilitar **Compartilhar esta pasta** e usar o nome **`Softwares`**.
4. Nas permissões **do compartilhamento e do NTFS**, garantir **Leitura e Execução** aos computadores que receberão a GPO (por exemplo, **Computadores do Domínio / Domain Computers**). Manter gravação restrita à equipe administradora.
5. Confirmar a existência dos dois arquivos:

```text
\\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi
\\SERVER200\Softwares\GLPI1.21.mst
```

Em uma estação de teste, validar acesso com a sessão atual:

```powershell
Test-Path '\\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi'
Test-Path '\\SERVER200\Softwares\GLPI1.21.mst'
```

Ambos devem retornar `True`. **Esse teste verifica a conta atual**, não prova que a conta do computador consegue ler o compartilhamento durante o boot. Validar também as permissões efetivas para computadores do domínio e a resolução do nome `SERVER200`.

## 7. Criar a GPO de Instalação de Software

1. No controlador de domínio, executar `gpmc.msc`.
2. Criar uma GPO (sugestão: **`GPO - GLPI AGENT 1.21`**) e vinculá-la inicialmente à **OU que contém uma estação de testes**, sem agente previamente instalado.
3. Editar a GPO e abrir:

```text
Configuração do Computador
  > Políticas
    > Configurações de Software
      > Instalação de Software
```

4. Clicar com o botão direito em **Instalação de Software > Novo > Pacote**.
5. **Digitar o caminho UNC** no campo de nome do arquivo (não selecionar `C:\...` pelo Explorador):

```text
\\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi
```

6. Na seleção de método de implantação, escolher **Avançado (Advanced)**.
7. Na guia **Implantação**, confirmar a opção **Atribuída (Assigned)**.
8. Na guia **Modificações (Modifications)**, usar **Adicionar (Add)** e informar:

```text
\\SERVER200\Softwares\GLPI1.21.mst
```

9. Confirmar as configurações, clicar em **OK** e verificar se a GPO mostra o pacote como **Atribuído** e com origem `\\SERVER200\Softwares\...`.
10. Aplicar a GPO apenas na OU piloto antes de expandir às demais.

**Importante:** o MST deve ser cadastrado durante a configuração inicial do pacote, antes de finalizar sua implantação. Se o pacote anterior foi criado com `C:\Softwares\...`, é preferível criar um pacote/GPO de teste novo com os caminhos UNC corretos; não usar o antigo como referência. Não remover GPOs que estejam atendendo outras estações sem avaliar o impacto.

### Política auxiliar para aguardar a rede

Na GPO, ou em outra GPO de configuração aplicável ao mesmo computador:

```text
Configuração do Computador
  > Políticas
    > Modelos Administrativos
      > Sistema
        > Logon
          > Sempre esperar pela rede na inicialização e no logon do computador
```

Definir como **Habilitado**. A instalação de software atribuída ao computador depende do processamento da política na inicialização, quando o cliente já consegue alcançar o domínio e os arquivos em rede. Em algumas condições, podem ser necessários mais de um ciclo de inicialização/reinicialização.

## 8. Aplicar e validar na estação de testes

Na estação que pertence à OU piloto, executar em Prompt de Comando elevado:

```cmd
gpupdate /force
shutdown /r /t 0
```

Depois do reinício, validar:

```powershell
# GPOs efetivamente aplicadas ao computador
gpresult /scope computer /r

# Serviço instalado e seu estado
Get-Service -Name 'glpi-agent' -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType

# Configuração do destino (se presente nesta chave)
Get-ItemProperty 'HKLM:\SOFTWARE\GLPI-Agent' -ErrorAction SilentlyContinue |
    Select-Object server, execmode

# Conectividade TCP com o servidor GLPI (não valida o endpoint HTTP)
Test-NetConnection 192.168.18.150 -Port 80
```

Se necessário, verificar também a visualização de Registro 32 bits:

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\GLPI-Agent' -ErrorAction SilentlyContinue |
    Select-Object server, execmode
```

**Critérios de sucesso:** GPO aplicada à conta do computador, produto instalado, serviço `glpi-agent` presente (preferencialmente `Running` e inicialização automática), URL do agente correta e **computador visível em Ativos > Computadores no GLPI** depois do inventário. Serviço ativo **não é prova isolada** de que o inventário foi recebido.

A interface local do agente, quando habilitada e acessível, pode ser consultada em `http://localhost:62354/` para solicitar o inventário. O log padrão do agente é geralmente `C:\Program Files\GLPI-Agent\logs\glpi-agent.log`.

## 9. Troubleshooting — problemas encontrados e soluções

| Sintoma | Causa ou hipótese | Verificação / correção |
| --- | --- | --- |
| O MSI foi copiado para `C:\Software`, mas a GPO de software não instala | Pacote de GPO cadastrado com **caminho local** ou conta do computador sem acesso | A origem da GPO deve ser `\\SERVER200\Softwares\...`; verificar SMB/NTFS. |
| O MST aparece como `C:\Softwares\GLPI1.21.mst` | Transformação cadastrada com caminho local | Recriar o pacote de teste usando **UNC** para MSI e MST. |
| `Get-Service glpi-agent` não encontra serviço | Agente não foi instalado nessa estação ou a implantação falhou | Conferir `gpresult`, eventos de instalação e acesso ao compartilhamento. |
| Código MSI **1603** | Erro fatal **genérico**, não identifica sozinho a causa | Examinar log MSI verbose e linhas anteriores à ação que falhou (`Return value 3`). |
| Teste manual retornou `False` no `IsInRole(Administrator)` | PowerShell não elevado | Reabrir como administrador **apenas para teste manual**. A GPO de computador executa no contexto SYSTEM. |
| Porta 80 retorna `TcpTestSucceeded : True`, mas não aparece inventário | TCP chega ao host, mas destino GLPI/configuração do agente pode estar incorreto | Validar URL `SERVER`, log do agente, configurações de inventário e recepção no GLPI. |
| Pacote aparece como **Atribuído** mas o agente não instala | GPO ainda não foi processada no boot, OU incorreta, falta de rede ou problema do MSI | `gpresult /scope computer /r`, política de aguardar rede, reboot, eventos. |
| Orca mostra `ProductVersion = 1.19` ou `1.18` | MSI aberto é de outra versão | Abrir o MSI original correto `1.21`; não alterar `ProductVersion` manualmente. |
| Dois mecanismos tentam instalar o agente | GPO de script antiga continua ativa ao lado do pacote MSI | Desativar **somente a implantação antiga do GLPI** na OU piloto, após confirmar que não atende outros objetivos. |

### Consultar eventos da instalação no cliente

```powershell
Get-WinEvent -FilterHashtable @{
    LogName      = 'Application'
    ProviderName = 'MsiInstaller'
    StartTime    = (Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue |
    Select-Object -First 20 TimeCreated, Id, Message |
    Format-List
```

Consultar também **Visualizador de Eventos > Logs de Aplicativos e Serviços > Microsoft > Windows > GroupPolicy > Operational** e **Logs do Windows > Aplicativo**. Os eventos mostram o que ocorreu no processamento da GPO e na execução do Windows Installer.

Se houver um arquivo de log MSI verbose, extrair o trecho da falha:

```powershell
$Log = 'C:\Windows\Temp\GLPI-Agent-MSI-Test.log' # Ajuste para o log existente
Select-String -Path $Log -Pattern 'Return value 3' -Context 40,10 |
    Select-Object -First 1 |
    ForEach-Object { $_.Context.PreContext; $_.Line; $_.Context.PostContext }
```

### Teste manual opcional do MSI + MST (somente em máquina piloto sem o agente)

Pode ser útil para isolar problemas de instalação do pacote de problemas de processamento da GPO. Executar em **CMD elevado**:

```cmd
msiexec.exe /i "\\SERVER200\Softwares\GLPI-Agent-1.21-x64.msi" TRANSFORMS="\\SERVER200\Softwares\GLPI1.21.mst" /qn /norestart /L*v "C:\Windows\Temp\GLPI-Agent-MSI-Test.log"
echo %ERRORLEVEL%
```

Códigos comuns: `0` = sucesso; `3010` = instalação concluída com reinicialização necessária; `1603` = falha fatal genérica, investigar log. Este teste manual **não substitui o teste real da GPO na inicialização**. Não utilizar o mesmo procedimento como reparo automático de instalações já existentes.

## 10. Boas práticas e operação

- Implantar **primeiro em uma OU piloto**, validando MSI, MST, serviço e inventário recebido, depois liberar gradualmente às demais OUs.
- Usar **uma única estratégia de implantação do GLPI Agent por estação**; não misturar GPO de script, GPO de instalação de software e outros mecanismos sem controle.
- Evitar manter o arquivo no caminho físico `C:\Softwares` das estações como dependência da **GPO de Instalação de Software**: esta usa o compartilhamento **UNC** para obter o pacote.
- Não aplicar MST de outra versão/build. Para atualizar o agente, planejar **novo pacote/upgrade** e testes; a alteração de propriedades no MST não implica reconfiguração automática do agente já instalado.
- Registrar versão, data, URL e hash do MSI, nome da GPO, OU piloto e responsável pela liberação.
- Usar acesso somente de leitura aos pacotes para as contas de computador e escrita apenas para administradores do compartilhamento.
- Em caso de falha, documentar **nome do computador**, horário de reinicialização, GPO aplicada, código MSI e log do instalador.

### Checklist de implantação

- [ ] MSI oficial `1.21` x64 validado
- [ ] MST `GLPI1.21.mst` criado com `SERVER`, `EXECMODE=1` e `RUNNOW=1`
- [ ] MSI e MST no `SERVER200`, na pasta compartilhada `Softwares`
- [ ] Permissão de leitura SMB + NTFS concedida aos computadores do domínio
- [ ] Ambos os arquivos referenciados por **UNC** na GPO
- [ ] Pacote criado em **Configuração do Computador**, como **Atribuído**
- [ ] MST adicionado na guia **Modificações** antes de concluir o pacote
- [ ] Política **Sempre esperar pela rede...** habilitada para a OU piloto
- [ ] Estação da OU piloto reiniciada e pacote instalado
- [ ] Serviço `glpi-agent` ativo e `SERVER` conferido
- [ ] Computador localizado em **Ativos > Computadores** no GLPI
- [ ] Liberação gradual para as demais OUs autorizada

## 11. Referências oficiais

- GLPI Agent — parâmetros do instalador Windows: <https://glpi-agent.readthedocs.io/en/latest/installation/windows-command-line.html>
- GLPI Agent 1.21 — release e MSI original: <https://github.com/glpi-project/glpi-agent/releases/tag/1.21>
- Microsoft — instalar software remotamente via GPO: <https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/use-group-policy-to-install-software>
- Microsoft — Orca.exe e Windows SDK: <https://learn.microsoft.com/pt-br/windows/win32/msi/orca-exe>
- Microsoft — funcionamento do processamento síncrono de GPO: <https://learn.microsoft.com/en-us/previous-versions/windows/desktop/policy/logon-optimization>

---

**Resumo da correção que resolveu este caso:** manter o MSI original e o MST no `SERVER200`, compartilhar `C:\Softwares`, e cadastrar **ambos na GPO por `\\SERVER200\Softwares\...`**, não por caminho `C:\...`.
