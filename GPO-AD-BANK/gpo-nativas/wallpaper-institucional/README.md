# Wallpaper Institucional (Desktop + Tela de Bloqueio)

**Mecanismo:** Group Policy Preferences (GPP) + Administrative Templates
(ADMX) — sem script customizado, tudo nativo do GPMC.

Conjunto de 4 configurações que trabalham juntas para distribuir o papel
de parede institucional (área de trabalho e tela de bloqueio) em todas as
máquinas do domínio.

## Visão geral

| # | Configuração | Tipo | Mecanismo |
|---|---|---|---|
| 1 | Criar pasta de destino no dispositivo | **Computador** | GPP → Windows Settings → Folders |
| 2 | Copiar os arquivos de imagem para a pasta | **Computador** | GPP → Windows Settings → Files |
| 3 | Definir wallpaper da área de trabalho | **Usuário** | ADMX → Desktop Wallpaper |
| 4 | Definir wallpaper da tela de bloqueio | **Computador** ⚠️ | ADMX → Personalization (Lock Screen) |

> ⚠️ **Correção em relação ao que costuma se assumir:** a tela de bloqueio
> não segue o usuário — ela é uma propriedade da máquina, aplicada antes
> mesmo de alguém logar. Por isso é Computador, não Usuário, mesmo estando
> "junto" conceitualmente com o wallpaper de desktop.

## Por que essa combinação de tipos

- **Pasta + arquivos = Computador:** a pasta local (ex:
  `C:\ProgramData\Empresa\Wallpaper\`) deve existir **antes** de qualquer
  usuário logar, porque tanto o wallpaper de usuário quanto o de tela de
  bloqueio (que carrega antes do logon) dependem dela. GPOs de Computador
  processam no boot, então a pasta e os arquivos já estão prontos quando o
  logon acontece.
- **Wallpaper de desktop = Usuário:** a política de wallpaper de área de
  trabalho (`Desktop Wallpaper`) só existe do lado de **User
  Configuration** no ADMX — não tem equivalente em Computer Configuration.
- **Wallpaper de tela de bloqueio = Computador:** ao contrário do desktop,
  a tela de bloqueio é exibida **antes do login**, então não há "usuário"
  no contexto — a política só existe do lado de **Computer
  Configuration**.

## Esquema de aplicação

```
Active Directory
   └── OU (ex: OU=Estacoes,DC=empresa,DC=com)
         └── GPO vinculada aqui
               │
               ├── Computer Configuration
               │     └── Preferences
               │           └── Windows Settings
               │                 ├── Folders     → cria C:\ProgramData\Empresa\Wallpaper\
               │                 └── Files       → copia wallpaper-desktop.jpg e wallpaper-lockscreen.jpg
               │     └── Policies
               │           └── Administrative Templates
               │                 └── Control Panel → Personalization
               │                       └── Force a specific default lock screen image
               │
               └── User Configuration
                     └── Policies
                           └── Administrative Templates
                                 └── Desktop → Desktop
                                       └── Desktop Wallpaper
```

## Passo a passo

### 1. Preparar os arquivos de origem

Coloque as imagens num compartilhamento de rede acessível pelas máquinas
(a mesma lógica de origem usada nos outros scripts deste repositório):

```
\\server\compartilhamento\Wallpaper\wallpaper-desktop.jpg
\\server\compartilhamento\Wallpaper\wallpaper-lockscreen.jpg
```

Recomendação: `.jpg`, resolução compatível com os monitores em uso (ex:
1920x1080), tamanho de arquivo enxuto (a tela de bloqueio principalmente
não deve pesar, pois carrega antes do usuário logar).

### 2. Criar (ou editar) a GPO

1. `gpmc.msc` → botão direito na OU alvo → **Create a GPO in this domain,
   and Link it here...**
2. Nomeie de forma identificável, ex: `COMP - Wallpaper Institucional`.

### 3. Computador → criar a pasta de destino (GPP → Folders)

1. Edite a GPO → **Computer Configuration** → **Preferences** →
   **Windows Settings** → **Folders**.
2. Botão direito → **New** → **Folder**.
3. Action: **Create**.
4. Path: `C:\ProgramData\Empresa\Wallpaper`.

### 4. Computador → copiar os arquivos (GPP → Files)

1. Mesma árvore → **Windows Settings** → **Files**.
2. Botão direito → **New** → **File**, uma entrada para cada imagem:

   | Campo | Wallpaper desktop | Wallpaper lock screen |
   |---|---|---|
   | Action | Replace | Replace |
   | Source | `\\server\compartilhamento\Wallpaper\wallpaper-desktop.jpg` | `\\server\compartilhamento\Wallpaper\wallpaper-lockscreen.jpg` |
   | Destination | `C:\ProgramData\Empresa\Wallpaper\wallpaper-desktop.jpg` | `C:\ProgramData\Empresa\Wallpaper\wallpaper-lockscreen.jpg` |

3. Na aba **Common**, marque **Run in logged-on user's security context**
   como **desmarcado** (o item de Computador roda como SYSTEM, precisa de
   permissão de leitura no compartilhamento para a conta de computador —
   `Domain Computers`).

### 5. Usuário → definir wallpaper de desktop (ADMX)

1. **User Configuration** → **Policies** → **Administrative Templates** →
   **Desktop** → **Desktop** → **Desktop Wallpaper**.
2. **Enabled**.
3. Wallpaper Name: `C:\ProgramData\Empresa\Wallpaper\wallpaper-desktop.jpg`
   (caminho **local**, não UNC — o arquivo já foi copiado pra máquina no
   passo 4).
4. Wallpaper Style: `Fill` (ou o estilo desejado).

### 6. Computador → definir wallpaper de tela de bloqueio (ADMX)

1. **Computer Configuration** → **Policies** → **Administrative
   Templates** → **Control Panel** → **Personalization**.
2. **Force a specific default lock screen and logon image** → **Enabled**.
3. Path: `C:\ProgramData\Empresa\Wallpaper\wallpaper-lockscreen.jpg`
   (também caminho local).
4. Opcional: **Prevent changing lock screen and logon image** → **Enabled**,
   se quiser impedir o usuário de trocar manualmente.

### 7. Vincular ao escopo certo

Confirme o link na OU correta e ajuste **Security Filtering** se quiser
restringir a um grupo específico de máquinas/usuários em vez de toda a OU.

### 8. Testar

```powershell
gpupdate /force
```

- Pasta e arquivos (Computador): visíveis após reboot ou próximo ciclo de
  atualização de política de computador (~90-120min, ou forçado).
- Wallpaper de desktop (Usuário): visível no próximo logon.
- Wallpaper de tela de bloqueio (Computador): visível ao bloquear a tela
  (`Win+L`) ou no próximo boot.

```powershell
gpresult /h relatorio.html
```

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| Pasta/arquivos não aparecem em `C:\ProgramData\Empresa\Wallpaper` | GPO de Computador não vinculada, ou conta de computador sem permissão de leitura no compartilhamento de origem | Conferir link da GPO; permissão de `Domain Computers` no share |
| Wallpaper de desktop não muda | Caminho UNC usado em vez de local, ou arquivo não copiado ainda (ordem: pasta/arquivos precisam rodar antes) | Usar caminho local `C:\ProgramData\...`; confirmar que a GPO de Computador já aplicou (reboot) |
| Tela de bloqueio não muda | Política aplicada em User Configuration por engano (não existe lá) | Confirmar que está em **Computer Configuration** → Personalization |
| Usuário consegue trocar o wallpaper manualmente | "Prevent changing..." não habilitado | Habilitar a política complementar no passo 6.4 |
| Imagem de tela de bloqueio não carrega | Arquivo grande demais, ou formato não suportado | Usar `.jpg`, manter arquivo leve (idealmente < 500KB) |
