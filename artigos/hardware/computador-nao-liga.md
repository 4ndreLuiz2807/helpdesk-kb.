# Computador não liga / desliga sozinho

**Categoria:** Hardware
**Sintoma relatado pelo usuário:** "Meu computador não liga" / "Ele desliga do nada enquanto estou usando"
**Nível:** N1 (não liga por cabo/energia) a N2 (hardware interno)

---

## Sintomas / como identificar

Diferenciar os cenários é o primeiro passo — "não liga" tem causas bem diferentes de "desliga sozinho":

- **Não liga:** nenhuma luz acende, nenhum som de ventoinha.
- **Liga mas não exibe imagem:** ventoinhas giram, luzes acendem, mas monitor fica preto.
- **Desliga sozinho durante o uso:** liga normalmente, mas desliga após minutos/horas de uso, às vezes ligado a esforço (jogos, muitas abas, calor ambiente).

## Causas prováveis

### Não liga
1. Cabo de energia solto ou fonte com problema.
2. Tomada/filtro de linha sem energia.
3. Fonte de alimentação queimada (desktop).
4. Bateria completamente descarregada + carregador com defeito (notebook).

### Liga mas sem imagem
1. Cabo de vídeo solto ou porta errada (ex.: conectado na placa de vídeo integrada em vez da dedicada, ou vice-versa).
2. Módulo de memória RAM mal encaixado.
3. Monitor selecionado na entrada errada (HDMI vs DisplayPort).

### Desliga sozinho
1. Superaquecimento (cooler sujo, pasta térmica ressecada) — comum em notebooks/desktops mais antigos.
2. Fonte de alimentação insuficiente para a carga (após upgrade de hardware, por exemplo).
3. Problema elétrico na rede local (quedas de energia, filtro de linha ruim).

## Passo a passo de diagnóstico

1. **Não liga:** testar em outra tomada, testar com outro cabo de energia se disponível.
2. **Liga mas sem imagem:** reconectar o cabo de vídeo, testar em outro monitor/porta.
3. **Desliga sozinho:** perguntar em que situação acontece (esforço, tempo de uso, calor ambiente) — isso já direciona bastante entre superaquecimento e problema elétrico.
4. Para desktops, se possível fisicamente: abrir o gabinete e verificar se os coolers giram e se há acúmulo de poeira visível.

## Solução

### Não liga — checklist rápido antes de escalonar

1. Trocar de tomada/filtro de linha.
2. Testar com outro cabo de força, se disponível.
3. Para notebook: deixar carregando por 15-20 minutos antes de tentar ligar novamente (bateria pode estar zerada a ponto de nem acender o LED de carregamento).

### Liga mas sem imagem

1. Reconectar o cabo de vídeo firmemente nas duas pontas.
2. Testar outra porta de vídeo (se a placa tiver saída integrada e dedicada, testar as duas).
3. Testar com outro monitor, se disponível, para isolar se o problema é no monitor ou na máquina.

### Desliga sozinho por superaquecimento

Orientar limpeza de coolers/ventilação (se dentro do escopo do suporte fazer isso, ou encaminhar para o time que cuida de hardware físico). Verificar se as saídas de ar não estão obstruídas (uso em cima da cama, tapete, etc., no caso de notebooks).

## Quando escalonar

- Fonte de alimentação suspeita de estar queimada — troca de peça, não é resolvível remotamente.
- Padrão de desligamento por superaquecimento que não melhora após limpeza básica — indica necessidade de manutenção física (troca de pasta térmica, cooler).
- Qualquer sintoma acompanhado de cheiro de queimado ou fumaça — **parar de usar o equipamento imediatamente** e escalonar como prioridade alta.

## Scripts relacionados

Não aplicável — troubleshooting físico não tem script de correção remota. Ver [`scripts/verificar-status-conta.ps1`](../../scripts/verificar-status-conta.ps1) apenas se o chamado também envolver perda de acesso após reinício forçado.
