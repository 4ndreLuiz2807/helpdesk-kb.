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
│   └── assets/          # Banner e imagens
└── <categoria>/
    └── <nome-da-gpo>/
        ├── script.ps1
        └── README.md     # contexto: onde a GPO é vinculada, escopo, comportamento
```

## 📋 GPOs mapeadas

| GPO | Categoria | Descrição |
|---|---|---|
| [Mapeamento de Atalhos no Desktop](./Mp-atalho-desktop.ps1) | Logon Script | Cria atalhos na área de trabalho do usuário para cada arquivo presente em uma pasta de rede compartilhada |

### Mapeamento de Atalhos no Desktop

**Vínculo da GPO:** Configuração do Usuário → Políticas → Configurações do
Windows → Scripts → Logon.

**O que faz:** ao logar, o script varre uma pasta de rede (`$PastaOrigem`,
a mesma pasta onde o script está publicado ou outro caminho UNC acessível)
e cria um atalho `.lnk` na área de trabalho para cada arquivo encontrado —
sem duplicar atalhos que já existem.

**Uso:** ajuste a variável `$PastaOrigem` no início do script para apontar
para o compartilhamento de rede desejado antes de publicar na GPO.

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
