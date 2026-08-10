# VPN não conecta — Erro 809

**Categoria:** Rede
**Sintoma relatado pelo usuário:** "Não consigo conectar na VPN, aparece um erro 809" / "VPN dá erro assim que eu tento conectar"
**Nível:** N1 - resolvível rápido

---

## Sintomas / como identificar

Ao tentar conectar a VPN (cliente nativo do Windows, L2TP/IPsec), aparece:

```
Erro 809: O computador remoto não respondeu. Isso pode ocorrer porque um
dispositivo intermediário (como firewall ou NAT) entre o seu computador e
o servidor remoto não permite conexões usando o protocolo GRE.
```

## Causas prováveis

1. Rede local (Wi-Fi doméstico, hotspot de celular, rede de terceiros) bloqueando o protocolo usado pela VPN (GRE, comum em PPTP; ou UDP 500/4500 no caso de L2TP/IPsec).
2. Roteador doméstico do usuário sem suporte a passthrough de VPN habilitado.
3. Firewall da empresa bloqueando a porta de origem específica do usuário (raro, mas acontece em bloqueios geográficos por IP).
4. Cliente VPN corporativo (ex.: FortiClient, Cisco AnyConnect) com configuração de servidor incorreta ou desatualizada.

## Passo a passo de diagnóstico

1. Perguntar em que rede o usuário está (Wi-Fi de casa, 4G/5G do celular, rede pública). Redes de operadora móvel e Wi-Fi público costumam bloquear GRE/IPsec.
2. Pedir para testar em outra rede (ex.: hotspot do celular) — se conectar, o problema é do roteador/rede de origem, não do servidor.
3. Confirmar se é VPN nativa do Windows ou cliente de terceiros (FortiClient, etc.) — o erro 809 é específico do cliente nativo do Windows.
4. Verificar se outros usuários na mesma rede/operadora relatam o mesmo problema no mesmo horário (indica bloqueio de operadora, não do usuário).

## Solução

### Se for bloqueio de rede/roteador doméstico (caso mais comum)

1. Orientar o usuário a acessar o roteador (geralmente `192.168.0.1` ou `192.168.1.1`) e habilitar "VPN Passthrough" (pode aparecer como "IPsec Passthrough" ou "PPTP Passthrough").
2. Se o roteador não tiver essa opção, recomendar o uso do cliente VPN corporativo (ex.: FortiClient) em vez da VPN nativa do Windows — costuma ter melhor NAT traversal.

### Se for o cliente corporativo (FortiClient) com erro parecido

1. Confirmar que o servidor VPN configurado no cliente está correto (nome/IP, porta).
2. Reimportar a configuração de VPN (`.conf`) se disponível — ver [scripts/testar-conectividade-vpn.ps1](../../scripts/testar-conectividade-vpn.ps1) para validar portas antes de reinstalar do zero.
3. Se persistir, verificar se a licença/certificado do FortiClient expirou.

## Quando escalonar

- Se múltiplos usuários reportam o mesmo erro simultaneamente (pode ser o servidor VPN corporativo fora do ar, não o cliente).
- Se o teste em rede alternativa (hotspot) também falhar — indica problema no lado do servidor ou nas credenciais do usuário, não na rede local.

## Scripts relacionados

- [`scripts/testar-conectividade-vpn.ps1`](../../scripts/testar-conectividade-vpn.ps1)

## Referências

- Documentação da Microsoft sobre troubleshooting de VPN Erro 809 (buscar "VPN error 809" no Microsoft Learn para a versão mais atual)
