
# Exceção de Bloqueio de Tela via GPO

## Objetivo

Este documento descreve o procedimento validado para criar exceções de bloqueio de tela em computadores específicos, mantendo a política ativa para os demais usuários e equipamentos do domínio.

O cenário tratado neste procedimento possui uma única GPO com configurações em dois escopos:

- **Configuração do Usuário**
- **Configuração do Computador**

GPO utilizada no cenário:

```text
Bloqueio de Tela_458
```

O requisito é permitir que determinadas máquinas **não apliquem o bloqueio de tela**, sem liberar o usuário da política em outros computadores.

---

## Cenário validado

Exemplo de máquina utilizada na validação:

```text
BA-COATV1
```

Grupo de exceção utilizado:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

Filtro WMI utilizado:

```text
WMI - Exceção Bloqueio de Tela
```

A GPO original possuía configurações tanto de usuário quanto de computador. Por isso, foi necessário tratar os dois escopos.

---

# 1. Criar o grupo de segurança de exceção

No **Active Directory Users and Computers** (`dsa.msc`), crie um grupo de segurança.

Nome sugerido:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

Configuração:

```text
Tipo: Segurança
Escopo: Global
```

Adicione ao grupo os **objetos de computador** que não deverão receber o bloqueio.

Exemplo:

```text
BA-COATV1$
BA-NOTESI277$
BA-PCMATV01$
```

> O grupo deve conter os computadores, e não os usuários.

---

# 2. Configurar a exceção no escopo de computador

Abra:

```text
gpmc.msc
```

Localize a GPO:

```text
Bloqueio de Tela_458
```

Acesse:

```text
Delegação
→ Avançado
```

Adicione:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

Configure as permissões:

| Permissão | Configuração |
|---|---|
| Leitura | Permitir |
| Aplicar política de grupo | **Negar** |

Resultado esperado:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA

Leitura
✅ Permitir

Aplicar política de grupo
❌ Negar
```

Isso impede que a parte de **Configuração do Computador** da GPO seja aplicada às máquinas pertencentes ao grupo de exceção.

---

# 3. Reiniciar a máquina após adicionar ao grupo

Após adicionar um computador ao grupo de segurança, reinicie a estação.

Isso é importante porque a associação do computador aos grupos de segurança é atualizada no contexto de segurança da conta da máquina.

Depois do reinício:

```cmd
gpupdate /force
```

---

# 4. Validar a exceção de computador

Execute:

```cmd
gpresult /r /scope computer
```

Resultado esperado:

```text
Os GPOs a seguir não foram aplicados porque foram filtrados
------------------------------------------------------------

Bloqueio de Tela_458
    Filtragem: Negado (segurança)
```

Também deve aparecer o grupo entre os grupos de segurança do computador:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

Exemplo validado:

```text
O computador faz parte dos seguintes grupos de segurança
--------------------------------------------------------
BA-COATV1$
GRP-GPO-EXCECAO-BLOQUEIO-TELA
Computadores do domínio
```

Se a GPO aparecer como:

```text
Filtragem: Negado (segurança)
```

a exceção de computador está funcionando.

---

# 5. Problema encontrado no escopo de usuário

A mesma GPO também possuía configurações em:

```text
Configuração do Usuário
```

Nesse caso, apenas adicionar o computador ao grupo de exceção não é suficiente para controlar a aplicação da política de usuário conforme o nome da máquina.

A necessidade era:

```text
O usuário continua recebendo a política em computadores normais.

Porém:

O mesmo usuário não deve receber a política ao utilizar uma máquina de exceção.
```

Para isso, foi criado um **Filtro WMI baseado no nome do computador**.

---

# 6. Criar o Filtro WMI

No `gpmc.msc`, navegue até:

```text
Floresta
→ Domínios
→ bioaroeira.com.br
→ Filtros WMI
```

Clique com o botão direito:

```text
Novo
```

Nome:

```text
WMI - Exceção Bloqueio de Tela
```

Descrição sugerida:

```text
Filtro utilizado para impedir a aplicação da GPO Bloqueio de Tela_458
em computadores definidos como exceção.
```

Adicione uma consulta.

Namespace:

```text
root\CIMv2
```

Consulta utilizada:

```sql
SELECT * FROM Win32_ComputerSystem
WHERE Name <> "BA-NOTESI277"
AND Name <> "BA-COATV1"
AND Name <> "BA-PCMATV01"
```

Salve o filtro.

---

# 7. Como funciona o Filtro WMI

O operador:

```text
<>
```

significa:

```text
Diferente de
```

Portanto:

```sql
Name <> "BA-COATV1"
```

significa que a GPO somente continuará sendo processada se o computador **não** for `BA-COATV1`.

Com múltiplas máquinas:

```sql
WHERE Name <> "BA-NOTESI277"
AND Name <> "BA-COATV1"
AND Name <> "BA-PCMATV01"
```

o resultado será:

| Computador | Resultado WMI | Aplicação da GPO |
|---|---:|---|
| BA-NOTESI100 | TRUE | Aplica |
| BA-NOTESI150 | TRUE | Aplica |
| BA-NOTESI277 | FALSE | Não aplica |
| BA-COATV1 | FALSE | Não aplica |
| BA-PCMATV01 | FALSE | Não aplica |

---

# 8. Vincular o Filtro WMI à GPO

Selecione:

```text
Bloqueio de Tela_458
```

Acesse:

```text
Escopo
```

Na seção:

```text
Filtragem WMI
```

selecione:

```text
WMI - Exceção Bloqueio de Tela
```

Confirme a associação.

Resultado esperado:

```text
GPO:
Bloqueio de Tela_458

Filtro WMI:
WMI - Exceção Bloqueio de Tela
```

> Apenas criar o filtro não é suficiente. Ele precisa estar vinculado à GPO.

---

# 9. Validar a exceção no escopo de usuário

Na máquina de exceção, com o usuário logado:

```cmd
gpupdate /force
```

Faça logoff e login novamente.

Depois execute:

```cmd
gpresult /r /scope user
```

Resultado esperado:

```text
Os GPOs a seguir não foram aplicados porque foram filtrados
------------------------------------------------------------

Bloqueio de Tela_458
    Filtragem: Negado (filtro WMI)
    Filtro WMI: WMI - Exceção Bloqueio de Tela
```

Esse resultado confirma que o usuário continua autorizado no domínio, porém a GPO foi recusada especificamente por causa da máquina utilizada.

---

# 10. Resultado validado

Na máquina:

```text
BA-COATV1
```

foi validado:

## Escopo de computador

```text
Bloqueio de Tela_458
    Filtragem: Negado (segurança)
```

## Escopo de usuário

```text
Bloqueio de Tela_458
    Filtragem: Negado (filtro WMI)
    Filtro WMI: WMI - Exceção Bloqueio de Tela
```

Portanto:

```text
Computador
    ↓
Grupo de exceção
    ↓
Negado por segurança
```

e:

```text
Usuário
    ↓
Filtro WMI verifica o computador
    ↓
Negado por filtro WMI
```

---

# 11. Bloqueio continuou mesmo após a GPO ser negada

Durante a validação, mesmo com a GPO corretamente filtrada, a estação continuou bloqueando a tela.

Foi verificado o seguinte valor:

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Resultado encontrado:

```text
InactivityTimeoutSecs    REG_DWORD    0x69
```

Conversão:

```text
0x69 = 105 segundos
```

Isso indicava que o limite de inatividade da máquina ainda estava configurado localmente.

A configuração corresponde a:

```text
Configuração do Computador
→ Configurações do Windows
→ Configurações de Segurança
→ Políticas Locais
→ Opções de Segurança
→ Logon interativo: limite de inatividade da máquina
```

---

# 12. Validar o registro de inatividade

Execute:

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Se retornar um valor diferente de `0`, existe um limite de inatividade configurado.

Exemplo:

```text
0x69
```

equivale a:

```text
105 segundos
```

---

# 13. Teste de correção

Para validar se o bloqueio estava relacionado ao valor persistente:

```cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f
```

Valide novamente:

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Resultado esperado:

```text
InactivityTimeoutSecs    REG_DWORD    0x0
```

Depois execute:

```cmd
gpupdate /force
```

Reinicie a máquina e teste novamente.

> A alteração manual do registro deve ser utilizada para diagnóstico e validação. Para produção, prefira aplicar a correção através de GPO.

---

# 14. Criar uma GPO específica para as máquinas de exceção

Para evitar correções manuais em cada estação, recomenda-se criar uma GPO específica.

Nome sugerido:

```text
GPO - Exceção Bloqueio de Tela
```

Configure:

```text
Configuração do Computador
→ Políticas
→ Configurações do Windows
→ Configurações de Segurança
→ Políticas Locais
→ Opções de Segurança
→ Logon interativo: limite de inatividade da máquina
```

Defina:

```text
0 segundos
```

Isso desabilita o limite de inatividade dessa configuração.

---

# 15. Filtragem de segurança da GPO de exceção

Na GPO:

```text
GPO - Exceção Bloqueio de Tela
```

configure a Filtragem de Segurança para o grupo:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

Essa GPO deve atingir somente os computadores que realmente são exceção.

Fluxo:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
            │
            ▼
GPO - Exceção Bloqueio de Tela
            │
            ▼
Interactive Logon:
Machine inactivity limit = 0
```

---

# 16. Validação final

Depois de configurar a GPO de exceção:

```cmd
gpupdate /force
```

Reinicie o computador.

Valide o escopo de computador:

```cmd
gpresult /r /scope computer
```

Valide o escopo de usuário:

```cmd
gpresult /r /scope user
```

Valide o registro:

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Resultado esperado:

```text
InactivityTimeoutSecs    REG_DWORD    0x0
```

---

# 17. Gerar relatório completo de GPO

Para diagnóstico avançado:

```cmd
mkdir C:\Temp
gpresult /h C:\Temp\GPResult.html /f
```

Abra:

```text
C:\Temp\GPResult.html
```

Procure por:

```text
Bloqueio de Tela_458
```

Na máquina de exceção, o comportamento esperado é:

```text
Escopo de computador:
Negado por segurança

Escopo de usuário:
Negado por filtro WMI
```

---

# 18. Validar via RSOP

Execute:

```cmd
rsop.msc
```

Para políticas de usuário:

```text
Configuração do Usuário
→ Modelos Administrativos
→ Painel de Controle
→ Personalização
```

Verifique itens como:

```text
Habilitar proteção de tela
Tempo limite da proteção de tela
Proteger com senha a proteção de tela
```

Para políticas de computador:

```text
Configuração do Computador
→ Configurações do Windows
→ Configurações de Segurança
→ Políticas Locais
→ Opções de Segurança
```

Verifique:

```text
Logon interativo: limite de inatividade da máquina
```

---

# 19. Adicionar uma nova máquina à exceção

Exemplo:

```text
BA-NOTESI300
```

## Etapa 1 — Adicionar ao grupo

Adicione o computador ao:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

## Etapa 2 — Atualizar o Filtro WMI

Antes:

```sql
SELECT * FROM Win32_ComputerSystem
WHERE Name <> "BA-NOTESI277"
AND Name <> "BA-COATV1"
AND Name <> "BA-PCMATV01"
```

Depois:

```sql
SELECT * FROM Win32_ComputerSystem
WHERE Name <> "BA-NOTESI277"
AND Name <> "BA-COATV1"
AND Name <> "BA-PCMATV01"
AND Name <> "BA-NOTESI300"
```

## Etapa 3 — Reiniciar

Reinicie a estação para atualizar a associação de grupo do computador.

## Etapa 4 — Atualizar as políticas

```cmd
gpupdate /force
```

## Etapa 5 — Validar

```cmd
gpresult /r /scope computer
```

```cmd
gpresult /r /scope user
```

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

---

# 20. Remover uma máquina da exceção

Para fazer o computador voltar a receber a política:

1. Remova o computador de:

```text
GRP-GPO-EXCECAO-BLOQUEIO-TELA
```

2. Remova seu hostname do Filtro WMI.

3. Reinicie o computador.

4. Execute:

```cmd
gpupdate /force
```

5. Faça logoff/login do usuário.

6. Valide:

```cmd
gpresult /r /scope computer
```

```cmd
gpresult /r /scope user
```

---

# 21. Fluxo final

```text
                    Bloqueio de Tela_458
                           │
              ┌────────────┴────────────┐
              │                         │
      Configuração do             Configuração do
        Computador                   Usuário
              │                         │
              ▼                         ▼
     Security Filtering              WMI Filter
              │                         │
              ▼                         ▼
GRP-GPO-EXCECAO-              Verifica hostname
BLOQUEIO-TELA                          │
              │               ┌────────┴────────┐
              ▼               │                 │
        Máquina no grupo   Máquina normal   Máquina exceção
              │               │                 │
              ▼               ▼                 ▼
          GPO NEGADA        GPO APLICA        GPO NEGADA
```

Complemento:

```text
Máquina de exceção
        │
        ▼
GPO - Exceção Bloqueio de Tela
        │
        ▼
InactivityTimeoutSecs = 0
```

---

# 22. Checklist de implementação

- [ ] Criar `GRP-GPO-EXCECAO-BLOQUEIO-TELA`
- [ ] Adicionar os objetos de computador ao grupo
- [ ] Configurar `Deny - Apply Group Policy` na `Bloqueio de Tela_458`
- [ ] Reiniciar os computadores adicionados ao grupo
- [ ] Criar `WMI - Exceção Bloqueio de Tela`
- [ ] Adicionar os hostnames das máquinas de exceção à consulta WMI
- [ ] Vincular o Filtro WMI à `Bloqueio de Tela_458`
- [ ] Executar `gpupdate /force`
- [ ] Fazer logoff/login para validar as configurações de usuário
- [ ] Validar `gpresult /r /scope computer`
- [ ] Validar `gpresult /r /scope user`
- [ ] Verificar `InactivityTimeoutSecs`
- [ ] Criar `GPO - Exceção Bloqueio de Tela` com timeout `0`, se necessário
- [ ] Validar o comportamento após reinicialização

---

# 23. Resultado esperado

Em um computador normal:

```text
Bloqueio de Tela_458
→ Aplicada
```

Em uma máquina pertencente ao grupo de exceção:

```text
Computador:
Bloqueio de Tela_458
→ Negado (segurança)
```

```text
Usuário:
Bloqueio de Tela_458
→ Negado (filtro WMI)
```

E:

```text
InactivityTimeoutSecs = 0
```

Resultado final:

```text
Máquina normal
→ Bloqueio de tela mantido

Máquina de exceção
→ Bloqueio de tela desabilitado

Usuário em outra máquina normal
→ Continua recebendo a política normalmente
```

---

# 24. Boas práticas

- Utilize grupos de segurança para administrar exceções de computador.
- Evite liberar diretamente usuários quando a exceção pertence ao equipamento.
- Documente cada hostname adicionado ao Filtro WMI.
- Utilize nomes padronizados para grupos, GPOs e filtros WMI.
- Sempre valide os dois escopos quando uma GPO possui configurações de usuário e computador.
- Prefira uma GPO específica de correção/exceção em vez de alterações manuais de registro.
- Antes de alterar uma GPO em produção, valide em uma máquina de teste.
- Para ambientes maiores, considere separar definitivamente as configurações de usuário e computador em GPOs distintas.

---

## Referência rápida de comandos

```cmd
gpupdate /force
```

```cmd
gpresult /r /scope computer
```

```cmd
gpresult /r /scope user
```

```cmd
gpresult /h C:\Temp\GPResult.html /f
```

```cmd
rsop.msc
```

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs
```

Teste de correção:

```cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f
```
