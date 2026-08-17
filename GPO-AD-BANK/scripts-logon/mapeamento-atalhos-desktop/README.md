# Mapeamento de Atalhos no Desktop

**Tipo de GPO:** Configuração do Usuário (*User Configuration*)
**Categoria:** Logon Script
**Script:** [`Mp-atalho-desktop.ps1`](./Mp-atalho-desktop.ps1)

## Por que é GPO de Usuário, não de Computador

| | Computador (Startup) | **Usuário (Logon)** ✅ |
|---|---|---|
| Quando roda | Boot da máquina, antes do login | Logon de qualquer usuário na máquina |
| Contexto | SYSTEM | Contexto do usuário logado |
| Onde aponta | — | `[Environment]::GetFolderPath("Desktop")` = área de trabalho **do usuário logado** |
| Se 2 pessoas usam o mesmo PC | Rodaria 1x só no boot, atalho iria pro perfil errado ou nenhum | Roda a cada logon, sempre no perfil de quem logou |

Como o objetivo é colocar o atalho na área de trabalho de quem está logando
— e não uma vez só na máquina — isso é necessariamente uma **GPO de
Usuário com script de Logon**. Uma GPO de Computador (Startup) rodaria como
SYSTEM antes de qualquer usuário logar, e não teria como saber em qual
perfil colocar o atalho.

## Esquema de aplicação

```
Active Directory
   └── OU (ex: OU=Financeiro,OU=Usuarios,DC=empresa,DC=com)
         └── GPO vinculada aqui
               └── Configuração do Usuário
                     └── Políticas
                           └── Configurações do Windows
                                 └── Scripts (Logon/Logoff)
                                       └── Logon
                                             └── Mp-atalho-desktop.ps1
                                                   (copiado para o SYSVOL da própria GPO)
```

## Passo a passo (GPMC)

### 1. Ajustar o script antes de publicar

Abra `Mp-atalho-desktop.ps1` e edite a variável no topo:

```powershell
$PastaOrigem = "\\server\compartilhamento\AtalhosDesktop"
```

Aponte para o compartilhamento de rede real com os arquivos que devem
virar atalho.

### 2. Criar (ou editar) a GPO

1. Abra `gpmc.msc` (Group Policy Management Console).
2. Clique com o botão direito na OU alvo → **Create a GPO in this domain,
   and Link it here...** (ou use uma GPO existente).
3. Nomeie de forma identificável, ex: `USR - Atalhos Desktop`.

### 3. Configurar o script de Logon

1. Edite a GPO → **User Configuration** → **Policies** → **Windows
   Settings** → **Scripts (Logon/Logoff)**.
2. Duplo clique em **Logon**.
3. Aba **PowerShell Scripts** → **Add** → **Browse**.
4. O botão Browse abre direto a pasta do SYSVOL dessa GPO
   (`\\dominio\SYSVOL\dominio\Policies\{GUID}\User\Scripts\Logon\`) —
   copie o `.ps1` para dentro dela.
5. Selecione o arquivo copiado → **OK**.

> Use a aba **PowerShell Scripts**, não a aba antiga "Scripts" (essa é
> para `.vbs`/`.bat`). Se sua GPO ainda mostrar as duas abas, também
> configure a ordem em **"For this GPO, run scripts in the following
> order"** caso haja mais de um script.

### 4. Permitir execução de script (se ainda não houver política de execução)

Sem isso, o script pode ser bloqueado pela Execution Policy do PowerShell
no cliente. Configure em uma GPO de **Computador** (pode ser a mesma ou
outra):

```
Computer Configuration → Policies → Administrative Templates →
Windows Components → Windows PowerShell → Turn on Script Execution
```

Habilitar, com **Execution Policy = "Allow local scripts and remote signed
scripts"**.

### 5. Vincular ao escopo certo

1. Confirme que a GPO está linkada na OU correta (ou grupo, via
   **Security Filtering**, se quiser restringir a um subconjunto de
   usuários dentro da OU).
2. Em **Security Filtering**, por padrão fica "Authenticated Users" —
   ajuste para um grupo de segurança específico se não quiser aplicar a
   todo mundo da OU.

### 6. Testar

No cliente, force a atualização e o próximo logon:

```powershell
gpupdate /force
```

Deslogue e logue novamente (script de Logon só roda no evento de logon,
`gpupdate` sozinho não dispara).

Para conferir se a GPO está sendo aplicada:

```powershell
gpresult /r
# ou, mais detalhado:
gpresult /h relatorio.html
```

### 7. Validar o resultado

Confirme que os atalhos apareceram na área de trabalho e que rodar de novo
(segundo logon) não duplica nada — o script já verifica `Test-Path` antes
de recriar.

## Troubleshooting rápido

| Sintoma | Causa provável | Solução |
|---|---|---|
| Script não roda no logon | GPO não vinculada à OU certa, ou usuário fora do Security Filtering | Conferir link da GPO e Security Filtering |
| Atalho não aparece mas sem erro visível | `$PastaOrigem` inacessível pro usuário (permissão de rede) | Testar `Test-Path $PastaOrigem` logado como o usuário afetado |
| Erro de política de execução | Execution Policy bloqueando | Aplicar a GPO de Computador do passo 4 |
| Atalhos duplicando a cada logon | Não deveria — o script checa `Test-Path` antes | Confirmar que não há dois scripts de logon criando o mesmo atalho |
