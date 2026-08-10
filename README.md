<div align="center">

# 🎧 Base de Conhecimento — Suporte de TI / HelpDesk

**Procedimentos, troubleshooting e fluxos de atendimento documentados para o dia a dia de suporte de TI**

[![Last Commit](https://img.shields.io/github/last-commit/4ndreLuiz2807/helpdesk-kb?color=0078D4&label=último%20commit)](https://github.com/4ndreLuiz2807/helpdesk-kb/commits/main)
[![License](https://img.shields.io/badge/licença-MIT-blue.svg)](./LICENSE)

</div>

---

## 📖 Sobre

Este repositório reúne artigos de troubleshooting, procedimentos padrão e fluxos de atendimento usados no suporte de TI. Cada artigo documenta um problema real, o diagnóstico passo a passo, e a solução — no formato mais próximo possível do que alguém no primeiro atendimento precisa para resolver rápido.

Repositório irmão deste: [lab-intune-entraid](https://github.com/4ndreLuiz2807/lab-intune-entraid), focado especificamente em Intune/Entra ID/M365. Aqui entra o suporte de TI mais geral — hardware, rede, impressoras, contas, e os fluxos de atendimento em si.

## 🗂️ Estrutura

```
helpdesk-kb/
├── README.md
├── LICENSE
├── docs/
│   └── modelos/
│       └── modelo-artigo.md      # Modelo padrão para novos artigos
├── artigos/
│   ├── hardware/                  # Problemas de máquina física: boot, periféricos, disco
│   ├── software/                  # Instalação, erro de aplicativo, licenciamento
│   ├── rede/                      # Conectividade, Wi-Fi, VPN, DNS
│   ├── impressoras/                # Fila de impressão, driver, compartilhamento
│   ├── email-m365/                 # Outlook, Teams, OneDrive, problemas de M365 no dia a dia
│   ├── contas-acessos/             # Reset de senha, bloqueio de conta, permissões
│   └── seguranca/                  # Phishing, malware, incidentes
├── fluxos-atendimento/            # SLA, escalonamento, prioridades, triagem de chamado
└── scripts/                        # Scripts de diagnóstico/correção rápida usados em atendimento
```

## 📝 Convenção de nomes e commits

Artigos: `artigos/<categoria>/titulo-curto-do-problema.md`, ex.: `artigos/rede/vpn-nao-conecta-erro-809.md`

Commits:

| Prefixo | Uso |
|---|---|
| `artigo:` | Novo artigo de troubleshooting |
| `fluxo:` | Novo ou atualizado fluxo de atendimento |
| `script:` | Novo script ou correção em script |
| `doc:` | Atualização de documentação/modelo |

## 🚀 Como usar

1. Ao resolver um chamado que provavelmente vai se repetir, documente como artigo usando o [modelo padrão](./docs/modelos/modelo-artigo.md).
2. Categorize na pasta certa (`hardware`, `rede`, `software`, etc.) — se não tiver certeza, categorize pelo sintoma principal, não pela causa raiz (o próximo técnico busca pelo sintoma).
3. Scripts de diagnóstico/correção usados no artigo vão em `scripts/`, referenciados a partir do artigo.

## ⚠️ Aviso

Ambiente documentado aqui é de suporte real de TI — **nunca inclua** dados de usuários reais, senhas, IPs internos sensíveis ou qualquer informação que identifique pessoas ou sistemas de produção específicos. Generalize exemplos quando necessário.

---

<div align="center">

Feito por [Andre Luiz](https://github.com/4ndreLuiz2807) — base de conhecimento de suporte de TI.

</div>
