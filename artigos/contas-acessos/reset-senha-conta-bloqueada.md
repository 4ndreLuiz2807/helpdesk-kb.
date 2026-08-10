# Reset de senha e conta bloqueada (Entra ID / AD)

**Categoria:** Contas e Acessos
**Sintoma relatado pelo usuário:** "Esqueci minha senha" / "Minha conta está bloqueada, não consigo entrar em nada"
**Nível:** N1 - resolvível rápido (exceto quando envolve MFA quebrado, ver escalonamento)

---

## Sintomas / como identificar

Usuário não consegue logar no Windows, e-mail ou qualquer serviço M365, geralmente com uma das mensagens:

- "Sua conta foi bloqueada" (após várias tentativas erradas)
- "Nome de usuário ou senha incorretos"
- "Sua organização precisa de mais informações" (loop de MFA)

## Causas prováveis

1. Senha expirada (política de expiração do tenant/AD).
2. Conta bloqueada por múltiplas tentativas de login incorretas (proteção contra força bruta).
3. Usuário esqueceu a senha mesmo.
4. Método de MFA perdido/trocado (celular novo, app autenticador reinstalado sem transferir).
5. Conta desabilitada intencionalmente (desligamento, licença não renovada) — confirmar antes de "resolver".

## Passo a passo de diagnóstico

1. **Confirmar identidade do usuário** antes de qualquer ação — nunca resetar senha ou desbloquear conta sem validar quem está pedindo (política de segurança, evita engenharia social).
2. Verificar o estado da conta:
   ```powershell
   # Ambiente Hybrid — verificar no AD local
   Get-ADUser -Identity <username> -Properties LockedOut, PasswordExpired, Enabled
   ```
   ```powershell
   # Via Microsoft Graph — Entra ID
   Connect-MgGraph -Scopes "User.Read.All"
   Get-MgUser -UserId "<usuario@dominio.com>" -Property AccountEnabled, SignInActivity
   ```
3. Confirmar se é bloqueio por tentativas erradas ou senha realmente expirada — a mensagem de erro costuma diferenciar.

## Solução

### Conta bloqueada por tentativas incorretas (ambiente Hybrid, AD local)

```powershell
Unlock-ADAccount -Identity <username>
```

Depois, se necessário, resetar a senha:
```powershell
Set-ADAccountPassword -Identity <username> -Reset -NewPassword (ConvertTo-SecureString "SenhaTemporaria!" -AsPlainText -Force)
Set-ADUser -Identity <username> -ChangePasswordAtLogon $true
```

> Sempre marcar "trocar senha no próximo login" — nunca deixar uma senha temporária definida pelo suporte como senha permanente do usuário.

### Reset via portal (Entra ID / self-service, se habilitado)

Se o usuário tiver Self-Service Password Reset (SSPR) configurado, oriente a usar `aka.ms/sspr` em vez de abrir chamado — reduz volume de tickets repetidos.

### MFA perdido (celular novo, app trocado)

1. Confirmar identidade por outro canal (ex.: gestor confirma, ou verificação por vídeo-chamada com câmera ligada) — **nunca resetar MFA só com a palavra do usuário por chat/telefone**, é um dos vetores mais comuns de engenharia social.
2. Resetar o método de autenticação:
   ```powershell
   Connect-MgGraph -Scopes "UserAuthenticationMethod.ReadWrite.All"
   Get-MgUserAuthenticationMethod -UserId "<usuario@dominio.com>"
   # Remover o método antigo e orientar o usuário a recadastrar
   ```
3. Orientar o usuário a recadastrar o MFA imediatamente após o reset.

## Quando escalonar

- Pedido de reset de MFA sem conseguir confirmar identidade por um canal confiável — escalonar para o gestor/segurança antes de agir.
- Conta que deveria estar desabilitada (ex.: usuário desligado) pedindo acesso — não é chamado de suporte, é questão de segurança/RH.
- Bloqueios repetidos na mesma conta em curto intervalo — pode indicar tentativa de invasão, não esquecimento genuíno.

## Scripts relacionados

- [`scripts/verificar-status-conta.ps1`](../../scripts/verificar-status-conta.ps1)
