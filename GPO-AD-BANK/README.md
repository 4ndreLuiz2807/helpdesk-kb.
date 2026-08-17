<div align="center">

<img src="./docs/assets/banner.png" alt="GPO-AD-BANK" width="100%" />

</div>

## 📖 Sobre

Este repositório reúne as **GPOs (Group Policy Objects)** mapeadas e em uso
no ambiente Active Directory, junto com os scripts que elas executam
(logon, logoff, startup). A ideia é simples: cada GPO configurada em
produção tem uma cópia documentada aqui — para consulta rápida, reuso em
outros ambientes/domínios, ou recuperação caso a política precise ser
recriada.

Cada entrada inclui o script em si, o contexto de onde a GPO é vinculada
(qual OU, qual escopo), e o comportamento esperado.

## 🗂️ Estrutura

```
GPO-AD-BANK/
├── README.md
├── docs/
│   └── assets/                # Banner e imagens
├── scripts-logon/              # GPOs de Usuário — Logon Scripts
│   └── <nome-da-gpo>/
│       ├── <script>.ps1
│       └── README.md           # tipo (usuário/computador), esquema, passo a passo de aplicação
├── scripts-startup/            # GPOs de Computador — Startup Scripts (quando houver)
│   └── <nome-da-gpo>/
│       ├── <script>.ps1
│       └── README.md
└── gpo-nativas/                 # GPOs via GPP/ADMX nativo (sem script) — Computador e/ou Usuário
    └── <nome-da-gpo>/
        └── README.md           # cada configuração documentada com seu próprio tipo
```

Cada GPO fica na pasta correspondente ao seu **tipo** (Usuário ou
Computador), já que isso muda o caminho de configuração no GPMC. O README
de cada GPO documenta o motivo do tipo escolhido e o passo a passo exato
de vínculo.

## 📋 GPOs mapeadas

| GPO | Tipo | Categoria | Descrição |
|---|---|---|---|
| [Mapeamento de Atalhos no Desktop](./scripts-logon/mapeamento-atalhos-desktop/) | Usuário | Logon Script | Cria atalhos na área de trabalho do usuário para cada arquivo presente em uma pasta de rede compartilhada |
| [Wallpaper Institucional](./gpo-nativas/wallpaper-institucional/) | Computador + Usuário (misto) | GPP / ADMX | Cria pasta e copia imagens no dispositivo (Computador), define wallpaper de desktop (Usuário) e wallpaper de tela de bloqueio (Computador) |

## 🚀 Como usar este repositório

1. Cada GPO nova vira uma entrada na tabela acima, com o script
   correspondente.
2. Scripts devem ter as variáveis de configuração (caminhos, nomes,
   parâmetros específicos do ambiente) destacadas no topo do arquivo, para
   facilitar adaptação a outro domínio/ambiente.
3. Sempre validar (sintaxe + lógica) antes de subir — evitar publicar
   script com variável não declarada ou dependência não documentada.

## ⚠️ Aviso

Os scripts aqui podem conter caminhos de rede, nomes de servidores ou OUs
de exemplo — sempre revise e ajuste para o ambiente de destino antes de
vincular a uma GPO em produção. Nenhuma credencial, senha ou dado sensível
deve ser versionado.
