# Outlook não sincroniza / e-mails não chegam

**Categoria:** E-mail / M365
**Sintoma relatado pelo usuário:** "Não estou recebendo e-mail" / "O Outlook parou de atualizar"
**Nível:** N1 - resolvível rápido

---

## Sintomas / como identificar

Outlook desktop mostra status "Desconectado" ou "Tentando conectar" na barra de status, e-mails não chegam automaticamente (só ao clicar manualmente em "Enviar/Receber"), ou o app trava ao abrir.

## Causas prováveis

1. Perfil do Outlook corrompido (arquivo `.ost` local com problema).
2. Cache de credenciais desatualizado (senha trocada recentemente, credencial salva antiga).
3. Conectividade instável ou proxy/firewall bloqueando os endpoints do Exchange Online.
4. Add-in do Outlook travando o processo.
5. Problema no lado do serviço (Exchange Online fora do ar/degradado — raro, mas acontece).

## Passo a passo de diagnóstico

1. Verificar o status da conexão no canto inferior direito do Outlook (deve dizer "Conectado" ou "Conectado a: Microsoft Exchange").
2. Testar OWA (Outlook Web, `outlook.office.com`) com o mesmo usuário — se funcionar no navegador, o problema é do cliente desktop, não da conta/servidor.
3. Checar o Status do serviço M365 (portal admin ou `portal.office.com/adminportal` → Health).
4. Perguntar se o problema começou depois de alguma troca (senha, computador novo, reinstalação do Office).

## Solução

### Se OWA funciona mas o Outlook desktop não (mais comum)

1. Fechar o Outlook completamente (checar no Gerenciador de Tarefas se não ficou processo pendurado).
2. Limpar credenciais salvas:
   ```
   Painel de Controle → Contas de Usuário → Gerenciador de Credenciais → Credenciais do Windows
   ```
   Remover entradas relacionadas a `MicrosoftOffice*` ou `outlook.office365.com`.
3. Reabrir o Outlook e reautenticar quando solicitado.

### Se persistir — reparar o perfil

```
Painel de Controle → Contas de Usuário → Correio → Mostrar Perfis → Adicionar novo perfil
```
Configurar o novo perfil com o e-mail do usuário (Outlook busca as configurações automaticamente via Autodiscover). Definir como perfil padrão.

### Se for add-in travando

Abrir o Outlook em modo de segurança para confirmar:
```
outlook.exe /safe
```
Se funcionar normalmente em modo seguro, o problema é um add-in — desabilitar um por um em Arquivo → Opções → Suplementos.

## Quando escalonar

- Status do serviço M365 mostra incidente ativo — não é troubleshooting individual, é aguardar a Microsoft resolver e comunicar aos usuários.
- Vários usuários do mesmo setor reportando simultaneamente (pode ser problema de rede/proxy corporativo, não individual).

## Scripts relacionados

- [`scripts/testar-conectividade-vpn.ps1`](../../scripts/testar-conectividade-vpn.ps1) *(adaptável para testar endpoints do Exchange Online)*
