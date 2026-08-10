# Impressora não aparece na rede / não é possível adicionar

**Categoria:** Impressoras
**Sintoma relatado pelo usuário:** "Não acho a impressora pra adicionar" / "A impressora sumiu, não consigo imprimir mais"
**Nível:** N1 - resolvível rápido

---

## Sintomas / como identificar

Ao tentar adicionar uma impressora de rede (Configurações → Impressoras e scanners → Adicionar dispositivo), ela não aparece na lista, ou uma impressora que já estava instalada some/para de responder.

## Causas prováveis

1. Serviço de Spooler de Impressão parado ou travado na máquina do usuário.
2. Impressora desligada, sem papel/toner (algumas impressoras somem da rede quando em erro crítico) ou desconectada da rede.
3. Máquina do usuário em uma VLAN/sub-rede diferente da impressora, sem rota ou sem permissão de descoberta de rede (Network Discovery desabilitado).
4. Servidor de impressão (print server) fora do ar, se a impressora for compartilhada via servidor.
5. Driver corrompido — a impressora aparece mas trava ao tentar instalar.

## Passo a passo de diagnóstico

1. Verificar se a impressora está ligada e com luz de rede/status normal (pedir para o usuário verificar fisicamente, ou consultar via painel de gerenciamento se houver acesso remoto).
2. No PowerShell da máquina do usuário, checar o serviço de Spooler:
   ```powershell
   Get-Service -Name Spooler
   ```
3. Testar conectividade com o IP da impressora (se conhecido):
   ```powershell
   Test-Connection -ComputerName <IP-da-impressora> -Count 2
   ```
4. Confirmar se "Descoberta de Rede" está habilitada: Painel de Controle → Rede e Internet → Central de Rede e Compartilhamento → Alterar configurações de compartilhamento avançadas.
5. Perguntar se outros usuários no mesmo setor/rede conseguem imprimir na mesma impressora — se ninguém consegue, o problema é da impressora ou do servidor de impressão, não da máquina do usuário.

## Solução

### Se o Spooler estiver parado

```powershell
Restart-Service -Name Spooler -Force
```

Se o serviço travar ao reiniciar, limpar a fila de impressão manualmente antes:
```powershell
Stop-Service -Name Spooler -Force
Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Force
Start-Service -Name Spooler
```

### Se for problema de rede/descoberta

1. Habilitar Descoberta de Rede no perfil de rede ativo.
2. Se a impressora estiver em outra sub-rede, adicionar manualmente por IP: Adicionar impressora → "A impressora que eu quero não está na lista" → Adicionar usando endereço TCP/IP.

### Se for servidor de impressão fora do ar

Escalonar para o time de infraestrutura — não é resolvível na ponta do usuário.

## Quando escalonar

- Múltiplos usuários/setores sem conseguir imprimir na mesma impressora ao mesmo tempo (indica problema no equipamento ou no servidor, não em uma máquina isolada).
- Impressora com erro físico persistente mesmo após reinício (toner, mecanismo, placa de rede da própria impressora).

## Scripts relacionados

- [`scripts/limpar-fila-impressao.ps1`](../../scripts/limpar-fila-impressao.ps1)
