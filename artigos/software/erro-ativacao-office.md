# Erro de licença/ativação do Microsoft Office

**Categoria:** Software
**Sintoma relatado pelo usuário:** "O Word/Excel está pedindo pra ativar" / "Aparece 'Produto não licenciado' em cima da tela"
**Nível:** N1 - resolvível rápido

---

## Sintomas / como identificar

Aplicativos do Office (Word, Excel, PowerPoint) abrem em modo limitado, com faixa vermelha/amarela no topo dizendo "Produto não licenciado" ou pedindo para inserir uma chave de produto, mesmo em ambiente com licença M365 corporativa.

## Causas prováveis

1. Licença M365 não atribuída ao usuário (ou removida por engano).
2. Token de ativação expirado — a licença é validada periodicamente online, e a máquina ficou muito tempo sem conseguir validar (ex.: fora da rede, VPN não usada).
3. Conta errada logada no Office (conta pessoal em vez da corporativa, ou duas contas conflitando).
4. Cache de licenciamento local corrompido.

## Passo a passo de diagnóstico

1. Confirmar no portal admin do M365 (ou perguntar ao time responsável) se o usuário tem licença ativa que inclua Office (M365 E3/E5, Business Standard/Premium, etc.).
2. No aplicativo Office, verificar qual conta está logada: **Arquivo → Conta**.
3. Perguntar há quanto tempo a máquina não conecta à internet/rede corporativa normalmente (VPN, escritório).

## Solução

### Se a licença não está atribuída

Escalonar/verificar com quem administra licenciamento — atribuir a licença M365 correta ao usuário no portal admin ou via grupo de licenciamento dinâmico.

### Se a licença está atribuída mas o Office não reconhece (mais comum)

1. Fechar todos os apps do Office.
2. Ir em **Arquivo → Conta → Sair** (se houver conta logada) e logar novamente com a conta corporativa correta.
3. Forçar reativação:
   ```
   cd "C:\Program Files\Microsoft Office\Office16"
   cscript ospp.vbs /act
   ```
   (ajustar o caminho conforme a versão/arquitetura instalada — 32 ou 64 bits)
4. Reiniciar os aplicativos do Office.

### Se persistir — limpar cache de licenciamento

```powershell
# Fechar todos os processos do Office antes
Get-Process -Name winword, excel, powerpnt -ErrorAction SilentlyContinue | Stop-Process -Force

# Remover credenciais de licenciamento em cache
cmdkey /list | findstr "MicrosoftOffice"
# Remover cada entrada listada relacionada ao Office com:
# cmdkey /delete:<nome-da-entrada>
```

Reabrir o Office e reautenticar do zero.

## Quando escalonar

- Licença confirmada como atribuída, mas o erro persiste após todos os passos acima — pode ser problema de sincronização no lado do M365, escalonar para quem administra o tenant.
- Vários usuários com o mesmo erro simultaneamente — possível problema de licenciamento em massa (ex.: renovação de contrato não processada a tempo).

## Scripts relacionados

- [`scripts/verificar-status-conta.ps1`](../../scripts/verificar-status-conta.ps1) *(para confirmar status geral da conta do usuário)*
