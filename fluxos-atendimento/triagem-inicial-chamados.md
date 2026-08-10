# Triagem inicial de chamados

**Nome do fluxo:** Triagem inicial de chamados
**Aplica-se a:** Todo chamado novo, antes de qualquer direcionamento

---

## Objetivo

Padronizar a primeira resposta a qualquer chamado, garantindo classificação correta de prioridade e categoria antes de iniciar o troubleshooting, evitando retrabalho e chamados mal direcionados.

## Critérios de prioridade

| Prioridade | Critério | SLA alvo (ajustar conforme contrato/política interna) |
|---|---|---|
| Crítica | Sistema essencial fora do ar para toda a empresa ou um setor inteiro (ex.: e-mail geral fora do ar, ERP indisponível) | Resposta imediata, resolução em até 1h |
| Alta | Usuário individual impossibilitado de trabalhar (máquina não liga, sem acesso a sistema essencial) | Resposta em até 30min, resolução em até 4h |
| Média | Funcionalidade específica com problema, mas usuário consegue contornar (ex.: impressora, um app específico) | Resposta em até 2h, resolução em até 1 dia útil |
| Baixa | Solicitação, dúvida, ou melhoria sem urgência (ex.: instalação de programa, dúvida de uso) | Resposta em até 1 dia útil |

## Passo a passo do fluxo

1. **Classificar a categoria** com base no sintoma relatado (Hardware / Software / Rede / Impressoras / E-mail-M365 / Contas-Acessos / Segurança) — usar a categoria mais próxima do sintoma, não da causa raiz ainda desconhecida.
2. **Aplicar a tabela de prioridade** acima com base no impacto relatado.
3. **Buscar na base de conhecimento** (`artigos/<categoria>/`) se já existe um artigo cobrindo o sintoma antes de investigar do zero.
4. **Se prioridade Crítica:** notificar imediatamente o responsável/gestor de plantão, mesmo antes de iniciar o diagnóstico completo.
5. **Se envolver segurança** (suspeita de phishing, malware, acesso indevido): seguir imediatamente o fluxo de [suspeita de phishing](../artigos/seguranca/suspeita-phishing-procedimento.md), que tem prioridade sobre a classificação padrão.
6. Executar o diagnóstico conforme o artigo aplicável.
7. Se não houver artigo aplicável e o problema for resolvido, **documentar como novo artigo** usando o [modelo padrão](../docs/modelos/modelo-artigo.md) antes de fechar o chamado.

## Quando escalonar

- Sintomas que já apontam diretamente para os critérios de escalonamento listados em cada artigo específico.
- Qualquer chamado onde a causa raiz não é identificada após os passos de diagnóstico padrão do artigo aplicável.
- Qualquer chamado envolvendo segurança de credenciais sem confirmação de identidade segura.

## Papéis envolvidos

| Papel | Responsabilidade neste fluxo |
|---|---|
| N1 | Triagem, classificação, aplicação de artigos existentes, primeira tentativa de resolução |
| N2 | Investigação mais profunda quando N1 não resolve, problemas que envolvem múltiplos sistemas |
| N3 / Especialista | Problemas de infraestrutura, incidentes de segurança confirmados, decisões que afetam todo o ambiente |
