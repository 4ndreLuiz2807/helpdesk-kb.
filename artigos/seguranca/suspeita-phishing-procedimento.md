# Suspeita de phishing — procedimento de resposta

**Categoria:** Segurança
**Sintoma relatado pelo usuário:** "Recebi um e-mail estranho pedindo minha senha" / "Cliquei num link e agora não sei se fiz besteira"
**Nível:** N1 (e-mail suspeito, ainda não clicado) a N2/N3 (usuário já inseriu credenciais ou executou algo)

---

## Sintomas / como identificar

Duas situações bem diferentes, que pedem respostas diferentes:

1. **Usuário recebeu e-mail suspeito e não interagiu** — quer saber se é phishing.
2. **Usuário já clicou/inseriu credenciais/baixou algo** — situação de possível comprometimento ativo.

## Sinais comuns de phishing

- Remetente com domínio parecido mas não idêntico ao real (ex.: `microsoft-support.net` em vez de `microsoft.com`).
- Urgência artificial ("sua conta será bloqueada em 24h", "ação necessária imediatamente").
- Link cujo texto exibido não bate com o destino real (passar o mouse por cima sem clicar para conferir).
- Pedido de credenciais fora do fluxo normal (ex.: "clique aqui e faça login" em vez do usuário acessar o portal diretamente).
- Anexo inesperado, especialmente `.zip`, `.exe`, ou macro em `.docm`/`.xlsm`.

## Passo a passo — Caso 1: e-mail suspeito, sem interação

1. Orientar o usuário a **não clicar em nada** e não responder.
2. Confirmar remetente real: passar o mouse sobre o nome do remetente para ver o endereço completo, não confiar só no nome de exibição.
3. Se confirmado como phishing, orientar a usar a opção de "Denunciar" do Outlook/M365 (se o botão de report estiver habilitado no tenant), e depois excluir.
4. Registrar o remetente/padrão para bloqueio preventivo, se recorrente (encaminhar para quem administra regras de transporte/anti-spam).

## Passo a passo — Caso 2: usuário já interagiu (clicou, inseriu senha, baixou anexo)

**Priorizar contenção antes de investigação — cada minuto conta se a credencial foi realmente capturada.**

1. **Se inseriu a senha em uma página falsa:** resetar a senha da conta imediatamente (ver [reset-senha-conta-bloqueada.md](../contas-acessos/reset-senha-conta-bloqueada.md)) e revogar sessões ativas:
   ```powershell
   Connect-MgGraph -Scopes "User.RevokeSessions.All"
   Revoke-MgUserSignInSession -UserId "<usuario@dominio.com>"
   ```
2. **Verificar se MFA está configurado** na conta — se sim, o risco de acesso indevido é bem menor, mas ainda assim resetar a senha.
3. **Se baixou/executou um anexo:** desconectar a máquina da rede (desligar Wi-Fi, desconectar cabo) **antes** de qualquer outra ação, para limitar propagação. Escalonar para o time de segurança/antivírus para varredura.
4. **Verificar login recente suspeito** na conta:
   ```powershell
   Get-MgAuditLogSignIn -Filter "userPrincipalName eq '<usuario@dominio.com>'" -Top 10
   ```
   Procurar por logins de localização/IP incomuns próximos ao horário do incidente.
5. Documentar o incidente: hora, o que foi clicado/inserido, ações tomadas — necessário para eventual investigação maior.

## Quando escalonar

- **Sempre escalonar para o time/responsável de segurança** quando houver credencial inserida em página falsa ou anexo executado — isso não se resolve só na ponta do N1.
- Se o mesmo e-mail de phishing chegou para múltiplos usuários — indica campanha direcionada, tratar como incidente maior, não chamados isolados.
- Login suspeito confirmado no Sign-in log após o incidente.

## Scripts relacionados

- [`scripts/verificar-status-conta.ps1`](../../scripts/verificar-status-conta.ps1)

## Referências

- Portal de submissão de amostras de phishing da Microsoft (Microsoft Defender / Security.microsoft.com), se disponível no tenant.
