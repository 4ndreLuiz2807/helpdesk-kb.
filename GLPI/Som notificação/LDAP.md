# Integração GLPI + Active Directory via LDAP/LDAPS

**Guia técnico de instalação, configuração, testes, importação, autenticação e sincronização**  
**Ambiente:** GLPI em Debian 13 (Trixie) + Windows Server AD DS  
**Situação documentada:** conexão LDAP validada no GLPI; importação, login de usuários e sincronização agendada ainda precisam ser validados.  
**Revisão:** 2026-10-29

> **Objetivo:** consultar o Active Directory a partir do GLPI, importar usuários, autenticar com as credenciais do domínio e sincronizar cadastros. Este README registra a configuração que funcionou no laboratório e um procedimento recomendado para migração a LDAPS. **Não publique senhas, chaves privadas ou exportações de credenciais junto a este arquivo.**

---

## Sumário

1. [Inventário e situação atual](#1-inventário-e-situação-atual)
2. [Pré-requisitos e verificações do Windows Server](#2-pré-requisitos-e-verificações-do-windows-server)
3. [Instalar e validar suporte LDAP no Debian](#3-instalar-e-validar-suporte-ldap-no-debian)
4. [Testar conectividade e DNS](#4-testar-conectividade-e-dns)
5. [Configurar diretório LDAP no GLPI](#5-configurar-diretório-ldap-no-glpi)
6. [Validar as cinco etapas do teste GLPI](#6-validar-as-cinco-etapas-do-teste-glpi)
7. [Habilitar uma conexão segura LDAPS/StartTLS](#7-habilitar-uma-conexão-segura-ldapsstarttls)
8. [Importar usuários e mapear atributos](#8-importar-usuários-e-mapear-atributos)
9. [Autorizações e teste de login](#9-autorizações-e-teste-de-login)
10. [Sincronização manual e agendada](#10-sincronização-manual-e-agendada)
11. [Grupos AD no GLPI (opcional)](#11-grupos-ad-no-glpi-opcional)
12. [Diagnóstico e solução de problemas](#12-diagnóstico-e-solução-de-problemas)
13. [Checklist de entrega](#13-checklist-de-entrega)
14. [Referências oficiais](#14-referências-oficiais)

---

## 1. Inventário e situação atual

| Item | Valor / observação |
|---|---|
| Servidor GLPI | Debian 13 (Trixie) |
| Instalação GLPI | `/var/www/glpi` (caminho utilizado no procedimento; validar antes de usar CLI) |
| Servidor web | Apache + PHP-FPM, conforme instalação anterior |
| PHP observado | PHP 8.4 |
| Domínio Active Directory | `server01.local` |
| Controlador de domínio (FQDN) | `SERVER200.server01.local` |
| IP do controlador | `192.168.18.200` |
| BaseDN | `DC=server01,DC=local` |
| Conta de serviço LDAP | `svc_glpi_ldap` |
| RootDN da conta | `CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local` |
| Conta habilitada no AD | **Sim**, confirmado pelo `Get-ADUser` |
| Diretório GLPI | `AD - Controlador de Domínio` |
| ID do diretório GLPI | `2` (identificado na interface: “ID 2”) |
| Campo de login | `sAMAccountName` (`samaccountname` também é válido) |
| Campo de sincronização | `objectGUID` (`objectguid` também é válido) |
| Porta utilizada no teste bem-sucedido | TCP `389` — LDAP, **sem evidência de criptografia** |
| Porta recomendada | TCP `636` — LDAPS com certificado válido e confiável |

### Resultado que já foi observado no GLPI

Na guia **Configurar > Autenticação > Diretórios LDAP > AD - Controlador de Domínio > Testar**, a tela retornou:

1. **Fluxo TCP:** conexão com `SERVER200.server01.local` na porta 389 realizada com sucesso.
2. **DN Base:** `DC=server01,DC=local` configurado.
3. **URI LDAP:** verificação bem-sucedida.
4. **Conexão de vínculo (bind):** autenticação bem-sucedida.
5. **Pesquisar (50 primeiras entradas):** pesquisa bem-sucedida, **6 entradas encontradas**.

**Interpretação:** o GLPI conseguiu conectar, vincular e pesquisar no AD. As 6 entradas não precisam corresponder a 6 usuários; a importação e o login ainda devem ser testados. O teste **não prova** TLS nem LDAPS.

---

## 2. Pré-requisitos e verificações do Windows Server

Execute as instruções desta seção em **PowerShell no controlador de domínio**, preferencialmente como administrador. Para consultas com `Get-AD*`, o módulo `ActiveDirectory` deve estar disponível.

### 2.1. Identificar o domínio e o BaseDN

```powershell
Get-ADDomain | Select-Object DNSRoot, DistinguishedName
```

Resultado confirmado no laboratório:

```text
DNSRoot        : server01.local
DistinguishedName : DC=server01,DC=local
```

**BaseDN do GLPI:** `DC=server01,DC=local`.

Alternativa pelo CMD:

```cmd
dsquery * "RootDSE" -scope base -attr defaultNamingContext
```

### 2.2. Identificar o controlador de domínio

```powershell
Get-ADDomainController -Discover |
    Select-Object HostName, IPv4Address
```

Resultado confirmado: **`SERVER200.server01.local` / `192.168.18.200`**.

Para consultar também os IPs configurados:

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
    Select-Object InterfaceAlias, IPAddress
```

### 2.3. Verificar a conta de serviço já existente

```powershell
Get-ADUser -Identity 'svc_glpi_ldap' |
    Select-Object Name, SamAccountName, DistinguishedName, Enabled
```

Resultado observado:

```text
Name         : svc_glpi_ldap
DistinguishedName : CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local
Enabled      : True
```

> **A conta já existe. Não execute `New-ADUser` novamente neste laboratório.** O erro `ResourceExists` ao tentar criá-la uma segunda vez é esperado.

#### Apenas em uma instalação nova, se a conta não existir

```powershell
$Conta = Get-ADUser -Filter "SamAccountName -eq 'svc_glpi_ldap'" -ErrorAction Stop
if ($null -eq $Conta) {
    $Senha = Read-Host 'Defina a senha da conta de serviço' -AsSecureString
    New-ADUser `
        -Name 'svc_glpi_ldap' `
        -SamAccountName 'svc_glpi_ldap' `
        -UserPrincipalName 'svc_glpi_ldap@server01.local' `
        -Path 'CN=Users,DC=server01,DC=local' `
        -AccountPassword $Senha `
        -Enabled $true `
        -Description 'Consulta LDAP do GLPI'
} else {
    Write-Host 'A conta svc_glpi_ldap já existe; nenhuma alteração realizada.'
}
```

Uma **conta comum de domínio** costuma ser suficiente para ler usuários e grupos; não conceda Domain Admin. Gerencie a senha de acordo com a política do ambiente e atualize o GLPI quando ela for trocada.

### 2.4. Testar o DNS do controlador no Windows

```powershell
Resolve-DnsName SERVER200.server01.local
```

Opcional — conferir portas localmente no controlador:

```powershell
Get-NetTCPConnection -LocalPort 389 -State Listen -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 636 -State Listen -ErrorAction SilentlyContinue
```

**Atenção:** `636` pode não estar disponível antes da instalação de um certificado LDAPS apropriado.

---

## 3. Instalar e validar suporte LDAP no Debian

Execute no terminal Debian do GLPI:

```bash
sudo apt update
sudo apt install -y php-ldap ldap-utils netcat-openbsd bind9-dnsutils openssl ca-certificates
```

No laboratório, `php-ldap` já estava instalado e `ldap-utils` / `netcat-openbsd` foram instalados.

Verifique a versão e se o módulo LDAP está disponível para o PHP de linha de comando:

```bash
php -v
php -m | grep -i '^ldap$'
php -r 'echo "LDAP PHP: ".(extension_loaded("ldap") ? "ATIVO" : "INATIVO").PHP_EOL;'
```

Saída esperada do `grep`:

```text
ldap
```

Reinicie serviços para carregar a extensão no ambiente web:

```bash
PHPVER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sudo systemctl restart "php${PHPVER}-fpm"
sudo systemctl restart apache2
```

Confira o estado:

```bash
systemctl is-active "php${PHPVER}-fpm"
systemctl is-active apache2
```

Ambos devem retornar `active`. Caso o PHP-FPM usado pelo Apache seja de outra versão, verifique o serviço efetivo antes de reiniciá-lo.

---

## 4. Testar conectividade e DNS

### 4.1. Testar rede por IP

```bash
ping -c 4 192.168.18.200
```

No laboratório, o ping retornou **0% de perda**. Um ping bem-sucedido **não comprova** que a porta LDAP esteja aberta.

Verificar TCP:

```bash
nc -zv -w 5 192.168.18.200 389
nc -zv -w 5 192.168.18.200 636
```

- `succeeded`: o serviço aceitou conexão TCP.
- `Connection refused`: porta fechada ou serviço não escutando.
- `timed out`: pode haver firewall, rota ou indisponibilidade.

### 4.2. Testar resolução de nomes

```bash
getent hosts SERVER200.server01.local
getent hosts server01.local
cat /etc/resolv.conf
```

Consultar diretamente o servidor DNS do AD:

```bash
nslookup SERVER200.server01.local 192.168.18.200
nslookup server01.local 192.168.18.200
```

**Falha encontrada durante a implantação:** inicialmente `getent hosts SERVER200.server01.local` não retornava resposta. O GLPI também apresentou:

```text
php_network_getaddresses: getaddrinfo for server01.local failed:
Name or service not known
```

O resultado final do teste GLPI com **`SERVER200.server01.local`** indica que a resolução/conectividade necessária à aplicação foi recuperada posteriormente. O método exato da correção de DNS não foi registrado.

### 4.3. Correção provisória por `/etc/hosts`

Se o DNS ainda não resolver o FQDN, para **laboratório**:

```bash
sudo nano /etc/hosts
```

Adicionar a linha:

```text
192.168.18.200 SERVER200.server01.local SERVER200
```

Salvar com `Ctrl+O`, `Enter`, `Ctrl+X` e validar:

```bash
getent hosts SERVER200.server01.local
```

Resultado esperado:

```text
192.168.18.200 SERVER200.server01.local SERVER200
```

> Esta entrada resolve **somente o nome específico do controlador**. Não é substituta para o DNS do AD. Evite mapear o domínio inteiro `server01.local` para um único IP no `/etc/hosts`.

### 4.4. Ajuste permanente de DNS (recomendado)

Identifique primeiro qual componente gerencia a rede do Debian:

```bash
readlink -f /etc/resolv.conf
systemctl is-active NetworkManager systemd-resolved systemd-networkd 2>/dev/null
ip -br address
ip route
```

Se estiver usando **NetworkManager**:

```bash
nmcli connection show --active
```

Após identificar o **nome exato da conexão**, configure o DNS do AD (troque `<NOME_DA_CONEXAO>`):

```bash
sudo nmcli connection modify '<NOME_DA_CONEXAO>' ipv4.dns '192.168.18.200' ipv4.dns-search 'server01.local' ipv4.ignore-auto-dns yes
```

Aplique a conexão em uma janela de manutenção ou com acesso ao console, pois reativar a interface pode interromper uma sessão remota:

```bash
sudo nmcli connection up '<NOME_DA_CONEXAO>'
```

Se estiver usando **systemd-networkd**, **ifupdown** ou outra solução, configure o DNS pelo arquivo/gerenciador real dessa interface; **não** suponha que mudanças diretas em `/etc/resolv.conf` sejam permanentes. Garanta também resolução de nomes públicos, usando o DNS do AD com encaminhadores corretos quando aplicável.

Validar:

```bash
getent hosts SERVER200.server01.local
nc -zv -w 5 SERVER200.server01.local 389
```

---

## 5. Configurar diretório LDAP no GLPI

Acesse, como Super-Admin:

**Configurar > Autenticação > Diretórios LDAP > Adicionar**.

Escolha a pré-configuração **Active Directory**, caso disponível, e preencha:

| Campo | Valor |
|---|---|
| Nome | `AD - Controlador de Domínio` |
| Servidor padrão | `Sim` (se for o principal) |
| Ativo | `Sim` |
| Servidor | `SERVER200.server01.local` |
| Porta LDAP (configuração do teste já realizado) | `389` |
| BaseDN | `DC=server01,DC=local` |
| Usar vinculação | `Sim` |
| RootDN | `CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local` |
| Senha | **Senha da conta de serviço; não registrar no README** |
| Campo de Login | `sAMAccountName` |
| Campo de sincronização | `objectGUID` |

**Filtro da conexão** (contas habilitadas):

```ldap
(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

**Por que estes campos?**

- `BaseDN`: raiz do escopo de pesquisa de usuários do domínio.
- `RootDN`: identificação da conta usada no *bind* para consultar o AD.
- `sAMAccountName`: login típico no AD (ex.: `joao.silva`).
- `objectGUID`: identificador único para manter a associação do usuário ao sincronizar.
- A grafia `samaccountname` / `objectguid` exibida no GLPI também é aceita.
- O filtro acima **não retorna contas desativadas**; configure a política de tratamento de usuários desativados no GLPI antes de automatizar sua remoção/desativação.

> **Segurança:** a porta 389 só foi usada no teste que já funcionou. **Não presuma que há criptografia nessa configuração.** O procedimento de autenticação definitivo deve utilizar LDAPS/StartTLS validado na seção 7.

Clique em **Adicionar** (ou **Salvar**, caso o diretório já exista). Neste laboratório, o diretório cadastrado tem **ID 2**. Não recrie outro se já estiver configurado.

---

## 6. Validar as cinco etapas do teste GLPI

No diretório LDAP existente, clique em **Testar**.

| Etapa exibida | Resultado esperado | Confirmado no laboratório? |
|---|---|---|
| 1 — Fluxo TCP | Conexão com o servidor e porta estabelecida | Sim, em 389 |
| 2 — DN Base | BaseDN configurado | Sim |
| 3 — URI LDAP | URI validada | Sim |
| 4 — Conexão de vínculo | Autenticação bem-sucedida | Sim |
| 5 — Pesquisar (50 primeiras entradas) | Consulta retorna resultados | Sim, 6 entradas |

> **Os cinco testes foram bem-sucedidos na configuração anterior pela porta 389.** Repita a validação depois de migrar para LDAPS/StartTLS; esse novo teste seguro ainda não foi confirmado.

---

## 7. Habilitar uma conexão segura LDAPS/StartTLS

**Para produção: use TLS antes de transmitir a senha da conta de serviço.** Há duas opções:

- **LDAPS**, servidor `ldaps://SERVER200.server01.local`, porta **636**.
- **StartTLS**, servidor LDAP normal, porta **389**, opção **Usar TLS** ativada em **Informações avançadas**, se o controlador oferecer StartTLS.

Não configure `ldaps://` e StartTLS simultaneamente na mesma conexão sem necessidade. **Não desative a validação do certificado** (`TLS_REQCERT never` e equivalentes não são correções aceitáveis).

### 7.1. Pré-requisitos no controlador

1. O Windows Server precisa possuir **certificado de autenticação de servidor** válido para LDAPS, com o nome `SERVER200.server01.local` coberto pelo certificado, cadeia confiável e chave privada.
2. O certificado pode vir de uma CA corporativa (por exemplo, AD CS). Na ausência de infraestrutura de certificados, providencie-a antes da migração.
3. O certificado da **CA emissora**, não a chave privada do controlador, deve ser disponibilizado ao Debian para confiança.
4. A porta TCP 636 deve estar disponível entre Debian e controlador.

No controlador, consulte certificados disponíveis em `certlm.msc` > **Pessoal > Certificados** e confirme EKU **Server Authentication**. Teste da porta no Debian:

```bash
nc -zv -w 5 192.168.18.200 636
```

### 7.2. Confiar na CA no Debian

Depois de exportar o **certificado público da CA** em formato PEM/CRT (não exporte chave privada) e transferi-lo ao Debian, por exemplo para `/tmp/ca-server01.crt`:

```bash
sudo cp /tmp/ca-server01.crt /usr/local/share/ca-certificates/server01-ca.crt
sudo update-ca-certificates
```

Se o arquivo exportado estiver em **DER** (`.cer` binário), converta antes de instalar:

```bash
openssl x509 -inform DER -in /tmp/ca-server01.cer -out /tmp/ca-server01.crt
```

Verificar o certificado apresentado pelo controlador (nome, cadeia e prazo de validade):

```bash
openssl s_client \
  -connect SERVER200.server01.local:636 \
  -servername SERVER200.server01.local \
  -verify_hostname SERVER200.server01.local \
  -verify_return_error </dev/null
```

Procure **`Verify return code: 0 (ok)`**. Certificado com nome incorreto, inválido ou CA desconhecida deve ser corrigido; **porta 636 aberta, isoladamente, não basta**.

### 7.3. Consultar o AD com `ldapsearch` via LDAPS

Somente depois de validar certificado/CA:

```bash
ldapsearch -LLL -x \
  -H 'ldaps://SERVER200.server01.local:636' \
  -D 'CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local' \
  -W \
  -b 'DC=server01,DC=local' \
  '(&(objectClass=user)(objectCategory=person)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))' \
  dn sAMAccountName givenName sn mail department departmentNumber objectGUID
```

- `-W` solicita a senha interativamente; evita colocá-la na linha de comando.
- Uma lista de entradas `dn:` demonstra que a consulta autenticada foi bem-sucedida.
- `objectGUID` pode aparecer em formato binário/base64 na saída LDAP, o que é normal.

**Alternativa StartTLS em 389**, se habilitada no AD e com certificado válido:

```bash
ldapsearch -LLL -x -ZZ \
  -H 'ldap://SERVER200.server01.local:389' \
  -D 'CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local' \
  -W -b 'DC=server01,DC=local' \
  '(objectClass=user)' dn sAMAccountName
```

`-ZZ` **exige** StartTLS; se falhar, a consulta não deve continuar sem TLS.

### 7.4. Atualizar GLPI para LDAPS

Em **Configurar > Autenticação > Diretórios LDAP > AD - Controlador de Domínio**:

| Campo | Valor definitivo recomendado |
|---|---|
| Servidor | `ldaps://SERVER200.server01.local` |
| Porta | `636` |
| BaseDN | `DC=server01,DC=local` |
| RootDN | `CN=svc_glpi_ldap,CN=Users,DC=server01,DC=local` |
| Usar vinculação | `Sim` (com conta de serviço) |
| Usar TLS (StartTLS) | `Não` **quando o servidor já for `ldaps://`** |

Salve, entre em **Testar**, e confirme novamente as **cinco etapas**. Se LDAPS falhar, reveja certificado, DNS e a cadeia de confiança; não ignore alertas TLS.

---

## 8. Importar usuários e mapear atributos

### 8.1. Mapear atributos na aba `Usuários`

Acesse **Configurar > Autenticação > Diretórios LDAP > AD - Controlador de Domínio > Usuários**.

Os campos disponíveis dependem da versão/configuração do GLPI. Utilize, quando houver um campo correspondente:

| Informação | Atributo AD |
|---|---|
| Identificação para login | `sAMAccountName` |
| Identificador de sincronização | `objectGUID` |
| Nome | `givenName` |
| Sobrenome | `sn` |
| E-mail | `mail` |
| Telefone | `telephoneNumber` |
| Celular | `mobile` |
| Departamento | `department` |
| Cargo | `title` |
| Matrícula | `employeeID` |
| Centro de custo (se disponibilizado/customizado) | `departmentNumber` |

`departmentNumber` é um atributo possível de consulta no AD, mas **não presuma que o GLPI possui um campo nativo de centro de custo mapeável diretamente**. Para um campo específico, pode ser necessário plugin/customização. Teste o valor no `ldapsearch` antes de configurar qualquer regra de importação.

### 8.2. Importar usuários pelo GLPI

1. Abra **Administração > Usuários**.
2. No menu de adição, escolha **Vínculo a diretório LDAP** / **Importação e sincronização de diretório LDAP** (o rótulo varia conforme a versão/tradução).
3. Selecione o diretório **AD - Controlador de Domínio** (ID **2**).
4. Selecione **Novos usuários / Importar novos usuários** e clique em **Pesquisar**.
5. Confira os resultados e **importe primeiro um único usuário comum de teste**.
6. Abra o usuário importado e confirme login, nome, sobrenome, e-mail e **origem LDAP**.
7. Só depois importe o restante dos usuários pretendidos.

**Não use a conta de serviço `svc_glpi_ldap` como usuário comum de teste.** Caso ela apareça na pesquisa, exclua-a da importação mediante filtro/seleção; contas técnicas não devem receber acesso desnecessário ao portal.

---

## 9. Autorizações e teste de login

Autenticar no AD **não garante** autorização para usar o GLPI. É preciso associar o usuário a **perfil** e **entidade**.

### 9.1. Definir a política de criação e acesso

Em **Configurar > Autenticação > Configuração**:

- Se desejar criação no primeiro login, habilite a importação/criação automática de usuários provenientes de fonte externa.
- Defina o comportamento adequado para usuários desativados ou removidos no AD.
- Preserve uma conta local **Super-Admin** funcional para recuperação da integração.

Em **Administração > Regras > Regras de atribuição de entidade e permissões**, crie/valide regras para atribuir:

- **Entidade:** entidade raiz ou a entidade organizacional apropriada.
- **Perfil de colaboradores:** `Self-Service`, como ponto de partida.
- **Perfil técnico:** atribuição específica, preferencialmente por grupo do AD.

Ajuste critérios para evitar conceder acesso irrestrito a toda conta do domínio. A nomenclatura exata dos menus/regras pode variar entre versões do GLPI.

### 9.2. Teste funcional de login

1. Faça logout ou abra o GLPI em janela privativa.
2. Entre com o **`sAMAccountName` de um usuário de teste** e **a senha desse usuário no AD**.
3. Confira se a autenticação funciona, se o perfil/entidade são atribuídos e se o cadastro exibe os dados corretos.
4. Atualize um atributo do usuário de teste no AD (por exemplo, `department` ou `telephoneNumber`), sincronize e confira a atualização no GLPI.

**Ainda não há evidência registrada de que essa etapa tenha sido concluída.**

---

## 10. Sincronização manual e agendada

> **Executar somente após validar a importação, as autorizações e o transporte seguro (LDAPS/StartTLS).** A sincronização pode criar/atualizar contas e, dependendo das políticas escolhidas, desativar ou alterar permissões de usuários.

### 10.1. Verificar o console do GLPI

No Debian:

```bash
ls -l /var/www/glpi/bin/console
cd /var/www/glpi
sudo -u www-data /usr/bin/php bin/console list | grep -i ldap
sudo -u www-data /usr/bin/php bin/console glpi:ldap:synchronize_users --help
```

Se o caminho de instalação for diferente, ajuste `/var/www/glpi` antes de prosseguir.

A documentação oficial descreve o comando **`glpi:ldap:synchronize_users`** e o parâmetro **`--ldap-server-id`**. No ambiente documentado, o ID do diretório é **2**.

### 10.2. Primeiro executar somente atualização dos já importados

```bash
cd /var/www/glpi
sudo -u www-data /usr/bin/php bin/console \
  glpi:ldap:synchronize_users \
  --ldap-server-id=2 \
  --only-update-existing \
  --no-interaction
```

Revise o resultado e os dados do usuário de teste. **Depois**, para permitir importação dos novos usuários e atualização dos existentes:

```bash
cd /var/www/glpi
sudo -u www-data /usr/bin/php bin/console \
  glpi:ldap:synchronize_users \
  --ldap-server-id=2 \
  --no-interaction
```

### 10.3. Preparar logs de sincronização

```bash
sudo install -d -m 0750 -o www-data -g www-data /var/log/glpi
sudo touch /var/log/glpi/ldap-sync.log
sudo chown www-data:www-data /var/log/glpi/ldap-sync.log
sudo chmod 0640 /var/log/glpi/ldap-sync.log
```

### 10.4. Agendar no cron (a cada hora)

Se necessário:

```bash
sudo apt install -y cron
sudo systemctl enable --now cron
```

Crie o agendamento:

```bash
sudo tee /etc/cron.d/glpi-ldap >/dev/null <<'CRON'
0 * * * * www-data cd /var/www/glpi && /usr/bin/php bin/console glpi:ldap:synchronize_users --ldap-server-id=2 --no-interaction >> /var/log/glpi/ldap-sync.log 2>&1
CRON
sudo chmod 0644 /etc/cron.d/glpi-ldap
```

**Periodicidade:** minuto `0` de cada hora. A sincronização não significa mudança instantânea no GLPI a cada alteração do AD.

Verificar:

```bash
cat /etc/cron.d/glpi-ldap
systemctl is-active cron
sudo tail -n 100 /var/log/glpi/ldap-sync.log
sudo journalctl -u cron --since '2 hours ago' --no-pager
```

Como o comando redireciona mensagens para o log, uma falha poderá ser investigada nele; se nenhuma mensagem aparecer, confira o agendamento e execute o comando manualmente.

Para **desativar o agendamento sem remover a configuração**, comente a linha no arquivo `/etc/cron.d/glpi-ldap` ou remova esse arquivo após fazer backup. Não edite `/etc/crontab` se estiver usando `/etc/cron.d/glpi-ldap`.

### 10.5. Política para usuários desativados

Antes de automatizar a desativação de usuários que deixaram de aparecer no LDAP, escolha conscientemente a política em **Configurar > Autenticação > Configuração** e **consulte o `--help` da versão instalada**. No CLI, `--deleted-user-strategy` suporta estratégias específicas, incluindo preservar e desabilitar. **Não aplique exclusão/desativação em massa antes de testar com uma conta controlada.**

---

## 11. Grupos AD no GLPI (opcional)

Para trazer grupos de domínio e depois criar regras específicas:

1. Abra **Configurar > Autenticação > Diretórios LDAP > AD - Controlador de Domínio > Grupos**.
2. Configure o modo de pesquisa de grupos adequado (por usuários, por grupos ou ambos).
3. Em geral, os atributos são `memberOf` no usuário e `member` no grupo.
4. Vá em **Administração > Grupos > Vínculo a diretório LDAP**, importe primeiro um grupo de teste.
5. Associe regras de atribuição de perfis/entidades aos grupos adequados, após confirmar o vínculo de grupo do usuário.

Grupos aninhados no AD podem exigir configuração específica; não presuma que `memberOf` simples liste toda a hierarquia de grupos.

---

## 12. Diagnóstico e solução de problemas

| Sintoma | Possível causa | Teste / correção |
|---|---|---|
| `Name or service not known` no GLPI | Debian não resolve FQDN | `getent hosts SERVER200.server01.local`, `nslookup ... 192.168.18.200`; corrigir DNS |
| `getent hosts` não retorna nada | DNS/hosts inadequado | Checar `/etc/resolv.conf`; entrada provisória em `/etc/hosts` |
| `nc` retorna `refused` em 389 | Serviço não escuta ou bloqueio local | Verificar LDAP/AD DS e firewall no Windows |
| `nc` retorna `timed out` | Falha de rede, rota ou firewall | `ping`, `ip route`, regras entre GLPI e DC |
| `php-ldap` instalado, mas GLPI não detecta | Extensão não carregada no PHP web | `php -m`, verificar FPM e reiniciar serviço correto |
| `invalid credentials` / LDAP 49 | RootDN/senha incorretos, conta bloqueada, expirada etc. | `Get-ADUser`, verificar senha e políticas; não testar credenciais sem TLS |
| LDAP 32 (`No such object`) | BaseDN/RootDN incorreto | Validar `Get-ADDomain` e `Get-ADUser ... DistinguishedName` |
| Teste TCP funciona, mas bind falha | Credenciais, exigência de TLS ou política do DC | Verificar TLS/LDAPS e conta de serviço |
| Porta 636 aberta, mas TLS falha | Certificado inválido, nome divergente, CA não confiável | `openssl s_client ... -verify_hostname ...` |
| Teste LDAP aprovado, mas usuários não aparecem | Filtro restritivo, base errada, sem permissão/importação | Checar filtro, pesquisa na aba de importação, regras de autorização |
| Usuário autentica, mas não entra no GLPI | Sem perfil/entidade atribuídos | Conferir regras de atribuição de autorizações |
| Dados não atualizam | Sync não configurada ou falhou | Executar CLI manual, verificar log/cron |
| `New-ADUser`: conta já existe | Tentativa de recriar `svc_glpi_ldap` | Não criar novamente; verificar `Get-ADUser` |

### 12.1. Comandos de coleta rápida — Debian

```bash
cat /etc/os-release
php -v
php -m | grep -i ldap
systemctl is-active apache2
systemctl is-active php8.4-fpm
ping -c 2 192.168.18.200
getent hosts SERVER200.server01.local
cat /etc/resolv.conf
nc -zv -w 5 192.168.18.200 389
nc -zv -w 5 192.168.18.200 636
```

### 12.2. Comandos de coleta rápida — PowerShell Windows Server

```powershell
Get-ADDomain | Select-Object DNSRoot, DistinguishedName
Get-ADDomainController -Discover | Select-Object HostName, IPv4Address
Get-ADUser -Identity svc_glpi_ldap | Select-Object DistinguishedName, Enabled
Resolve-DnsName SERVER200.server01.local
```

### 12.3. Logs do GLPI

O local dos logs depende da versão e do layout da instalação; em uma instalação tradicional pode ser `files/_log`, enquanto em instalações com dados externos ao diretório web há um diretório de dados separado. Antes de procurar:

```bash
ls -ld /var/www/glpi/files/_log 2>/dev/null || true
ls -ld /var/lib/glpi/_log 2>/dev/null || true
```

Se houver falhas de aplicação, examine também os logs efetivamente configurados do Apache e PHP-FPM (sem publicar senhas ou informações pessoais coletadas).

---

## 13. Checklist de entrega

**Confirmado a partir das capturas enviadas**

- [x] Debian consegue alcançar `192.168.18.200` via ICMP.
- [x] Pacote `php-ldap` presente.
- [x] `ldap-utils` e `netcat-openbsd` instalados.
- [x] Domínio e BaseDN identificados.
- [x] Conta `svc_glpi_ldap` existe e está habilitada.
- [x] Controlador `SERVER200.server01.local` identificado.
- [x] Diretório LDAP do GLPI criado e ativado (ID `2`).
- [x] Login `samaccountname` / sincronização `objectguid` configurados.
- [x] Teste do GLPI concluiu as 5 etapas em TCP 389.
- [x] Pesquisa LDAP retornou 6 entradas.

**Pendente de execução ou confirmação**

- [ ] DNS do Debian configurado permanentemente para resolver o AD (método não registrado).
- [ ] Certificado do controlador configurado para LDAPS, com CA confiável no Debian.
- [ ] Teste TLS com certificado validado e as 5 etapas no GLPI via LDAPS.
- [ ] Importação de usuário comum de teste validada.
- [ ] Regras de perfil/entidade e login com senha do AD validados.
- [ ] Sincronização manual via CLI validada.
- [ ] Cron instalado, executado e conferido em log.
- [ ] (Opcional) Importação de grupos e mapeamento de `departmentNumber`.

---

## 14. Referências oficiais

- GLPI — Diretórios LDAP: <https://help.glpi-project.org/documentation/modules/configuration/authentication/ldap>
- GLPI — Importação de usuários: <https://help.glpi-project.org/documentation/modules/administration/users/usersimport>
- GLPI — Interface de linha de comando: <https://help.glpi-project.org/documentation/cli>
- GLPI — Perguntas frequentes LDAP: <https://help.glpi-project.org/faq/glpi/ldap>
- GLPI — Agendamento de ações automáticas: <https://help.glpi-project.org/faq/glpi/cron_automatic_action>

---

**Observação:** este README contém os parâmetros específicos confirmados no laboratório `server01.local`. Para outro ambiente, substitua nome do domínio, FQDN, IP, BaseDN, RootDN e ID do diretório GLPI antes de executar comandos de alteração.
