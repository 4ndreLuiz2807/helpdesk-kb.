# GLPI — Notificações do Navegador com Sons Personalizados

## Objetivo

Este documento descreve a configuração utilizada para:

- habilitar notificações do navegador no GLPI;
- permitir notificações em um ambiente GLPI acessado por HTTP;
- adicionar sons personalizados além dos sons padrão A, B, C e D;
- associar os sons personalizados ao menu do GLPI;
- configurar a notificação de abertura de chamado para os atendentes;
- validar arquivos, permissões, cache e funcionamento final.

> **Ambiente utilizado**
>
> - Servidor: Debian
> - Web Server: Apache
> - GLPI: `/var/www/glpi`
> - DocumentRoot: `/var/www/glpi/public`
> - URL utilizada: `http://192.168.18.71`
> - Usuário do Apache: `www-data`
> - Usuário administrativo do servidor: `root`
> - Usuário de transferência: `glpiserver`

---

## 1. Estrutura de diretórios

### Diretório do GLPI

```bash
/var/www/glpi
```

### Diretório público dos sons

```bash
/var/www/glpi/public/sound/
```

Os sons padrão encontrados na instalação foram:

```text
sound_a.mp3
sound_a.ogg
sound_b.mp3
sound_b.ogg
sound_c.mp3
sound_c.ogg
sound_d.mp3
sound_d.ogg
```

### Diretório utilizado para upload via WinSCP

```bash
/home/glpiserver/upload/sound/
```

Esse diretório serve apenas como área de transferência.

O GLPI **não reproduz os sons diretamente dessa pasta**.

---

## 2. Permitir notificações do navegador em HTTP

Ao acessar o GLPI por:

```text
http://192.168.18.71
```

o navegador pode bloquear notificações por considerar HTTP uma origem não segura.

No Opera/Opera GX foi utilizado o recurso experimental:

```text
opera://flags/#unsafely-treat-insecure-origin-as-secure
```

Ativar:

```text
Insecure origins treated as secure
```

E informar:

```text
http://192.168.18.71
```

Depois reiniciar completamente o navegador.

Nas configurações do site, confirmar:

```text
Notificações → Permitir
JavaScript   → Permitir
```

> Esta configuração foi utilizada como solução de laboratório/rede interna.
> Para produção, a recomendação é publicar o GLPI utilizando HTTPS com certificado confiável.

---

## 3. Validar notificações no GLPI

Acessar:

```text
Configurar
→ Notificações
→ Configuração das notificações do navegador
```

Configurações utilizadas:

```text
Som de notificação padrão: configurável
Tempo para verificar novas notificações: 5 segundos
Período de validade das notificações: 7 dias
URL do ícone: /pics/glpi.png
```

Utilizar o botão:

```text
Envie uma notificação do navegador de teste para você
```

Antes de personalizar os sons, confirmar que pelo menos um som padrão funciona.

---

## 4. Localizar os sons utilizados pelo GLPI

Com acesso root:

```bash
find /var/www/glpi -type f \
\( -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.wav" \) \
2>/dev/null
```

Resultado esperado:

```text
/var/www/glpi/public/sound/sound_a.ogg
/var/www/glpi/public/sound/sound_a.mp3
/var/www/glpi/public/sound/sound_b.ogg
/var/www/glpi/public/sound/sound_b.mp3
/var/www/glpi/public/sound/sound_c.ogg
/var/www/glpi/public/sound/sound_c.mp3
/var/www/glpi/public/sound/sound_d.ogg
/var/www/glpi/public/sound/sound_d.mp3
```

---

## 5. Arquivo responsável pelo menu de sons

O menu é definido no template:

```bash
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

Antes de editar, criar backup:

```bash
cp \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig.bak
```

Editar:

```bash
nano /var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

---

## 6. Criar opções personalizadas de som

A configuração final utilizada foi:

```twig
{% extends 'generic_show_form.html.twig' %}
{% import 'components/form/fields_macros.html.twig' as fields %}

{% block form_fields %}
    {{ fields.dropdownArrayField('notifications_ajax_sound', config('notifications_ajax_sound'), {
        sound_custom_1: 'SOM 1',
        sound_custom_2: 'SOM 2',
    }, __('Default notification sound'), {
        display_emptychoice: true,
        emptylabel: __('Disabled'),
    }) }}

    {{ fields.dropdownNumberField('notifications_ajax_check_interval', config('notifications_ajax_check_interval'), __('Time to check for new notifications (in seconds)'), {
        min: 5,
        max: 120,
        step: 5
    }) }}

    {{ fields.textField('notifications_ajax_icon_url', config('notifications_ajax_icon_url'), __('URL of the icon'), {
        additional_attributes: {
            placeholder: path('pics/glpi.png')
        }
    }) }}
```

> Não duplicar o bloco `dropdownArrayField`.
>
> Deve existir somente uma definição de `notifications_ajax_sound`.

Validar:

```bash
grep -c "dropdownArrayField('notifications_ajax_sound'" \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

Resultado esperado:

```text
1
```

---

## 7. Limpar cache após alterar o template

Executar:

```bash
cd /var/www/glpi
runuser -u www-data -- php bin/console cache:clear
```

Depois atualizar o navegador com:

```text
Ctrl + Shift + R
```

O menu deve exibir:

```text
Desabilitado
SOM 1
SOM 2
```

---

## 8. Upload dos sons personalizados

Os arquivos foram enviados pelo WinSCP para:

```bash
/home/glpiserver/upload/sound/
```

Exemplo:

```text
SOM-1.wav
SOM-2.mp3
```

Validar:

```bash
ls -lah /home/glpiserver/upload/sound/
```

---

## 9. Converter WAV para MP3

O GLPI utiliza diretamente arquivos `.mp3` e `.ogg`.

Para converter WAV para MP3:

```bash
apt update
apt install ffmpeg -y
```

Converter:

```bash
ffmpeg -y \
-i "/home/glpiserver/upload/sound/SOM-1.wav" \
-codec:a libmp3lame -q:a 2 \
"/var/www/glpi/public/sound/sound_custom_1.mp3"
```

Copiar o segundo arquivo:

```bash
cp -f \
"/home/glpiserver/upload/sound/SOM-2.mp3" \
"/var/www/glpi/public/sound/sound_custom_2.mp3"
```

---

## 10. Ajustar permissões

```bash
chown root:www-data \
/var/www/glpi/public/sound/sound_custom_1.mp3 \
/var/www/glpi/public/sound/sound_custom_2.mp3
```

```bash
chmod 644 \
/var/www/glpi/public/sound/sound_custom_1.mp3 \
/var/www/glpi/public/sound/sound_custom_2.mp3
```

Validar:

```bash
ls -lh /var/www/glpi/public/sound/sound_custom*
```

---

## 11. Validar o formato dos arquivos

```bash
file /var/www/glpi/public/sound/sound_custom_1.mp3
file /var/www/glpi/public/sound/sound_custom_2.mp3
```

Exemplo de saída válida:

```text
Audio file with ID3 version 2.4.0, contains: MPEG ADTS, layer III
MPEG ADTS, layer III
```

---

## 12. Testar os sons diretamente pelo navegador

Testar:

```text
http://192.168.18.71/sound/sound_custom_1.mp3
```

```text
http://192.168.18.71/sound/sound_custom_2.mp3
```

Se houver suspeita de cache:

```text
http://192.168.18.71/sound/sound_custom_1.mp3?v=123
```

```text
http://192.168.18.71/sound/sound_custom_2.mp3?v=123
```

O parâmetro `?v=123` força o navegador a tratar a URL como diferente.

---

## 13. Por que utilizar `sound_custom_1` e `sound_custom_2`

Inicialmente foram utilizados:

```text
sound_e
sound_f
sound_g
```

Esses arquivos haviam sido criados como cópias dos sons padrão.

Como o navegador já havia armazenado os arquivos antigos em cache, continuava reproduzindo o áudio anterior.

Para eliminar esse problema, foram utilizados nomes novos:

```text
sound_custom_1
sound_custom_2
```

Assim:

```text
SOM 1
  ↓
sound_custom_1
  ↓
/sound/sound_custom_1.mp3
```

```text
SOM 2
  ↓
sound_custom_2
  ↓
/sound/sound_custom_2.mp3
```

---

## 14. Configurar aviso para abertura de chamado

Ter som funcionando não significa que um novo chamado gerará alerta automaticamente.

É necessário configurar uma notificação para o evento de abertura do chamado.

Acessar:

```text
Configurar
→ Notificações
→ Notificações
```

Abrir a notificação relacionada a:

```text
Novo chamado
```

Confirmar:

```text
Ativa: Sim
Evento: Novo chamado
Tipo: Chamado
```

---

## 15. Configurar os destinatários

Para que os atendentes recebam a notificação, definir destinatários adequados.

Uma boa prática é criar um grupo dedicado, por exemplo:

```text
GRP - GLPI - ATENDENTES
```

Adicionar os técnicos/atendentes nesse grupo.

Na notificação de **Novo chamado**, configurar o grupo como destinatário.

Evitar depender apenas de:

```text
Técnico responsável
```

porque um chamado recém-criado pode ainda não possuir técnico atribuído.

---

## 16. Configurar o template de navegador

A notificação deve possuir um template associado ao modo:

```text
Navegador
```

Não basta possuir somente:

```text
E-mail
```

A notificação de navegador é o mecanismo responsável pelo alerta visual e pelo som configurado.

---

## 17. Requisitos no computador do atendente

Cada atendente precisa:

```text
Estar logado no GLPI
+
Ter o GLPI aberto no navegador
+
Permitir notificações do site
+
Permitir som no navegador/Windows
+
Ser destinatário da notificação
```

Também verificar no Windows:

```text
Configurações
→ Sistema
→ Notificações
→ Opera / navegador utilizado
```

Confirmar que o som das notificações está habilitado.

---

## 18. Fluxo final

```text
Usuário abre chamado
        ↓
GLPI registra o chamado
        ↓
Evento "Novo chamado"
        ↓
Notificação do navegador
        ↓
Grupo de atendentes
        ↓
Atendente logado no GLPI
        ↓
Notificação do sistema
        ↓
SOM 1 / SOM 2
```

---

## 19. Comandos úteis de diagnóstico

### Ver sons disponíveis

```bash
ls -lah /var/www/glpi/public/sound/
```

### Validar MP3

```bash
file /var/www/glpi/public/sound/*.mp3
```

### Validar template

```bash
grep -n -A20 "notifications_ajax_sound" \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

### Confirmar apenas um seletor

```bash
grep -c "dropdownArrayField('notifications_ajax_sound'" \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

### Limpar cache

```bash
cd /var/www/glpi
runuser -u www-data -- php bin/console cache:clear
```

### Ver logs do Apache

```bash
tail -f /var/log/apache2/glpi_error.log
```

ou:

```bash
journalctl -u apache2 -f
```

---

## 20. Problemas encontrados e soluções

### Notificações bloqueadas pelo navegador

**Sintoma**

```text
Bloqueada para proteger sua privacidade
```

**Causa**

GLPI acessado por HTTP.

**Solução aplicada no laboratório**

```text
Insecure origins treated as secure
```

para:

```text
http://192.168.18.71
```

---

### Novo som aparece no menu, mas não toca

**Causa possível**

O arquivo não existe em:

```bash
/var/www/glpi/public/sound/
```

**Validação**

```bash
ls -lah /var/www/glpi/public/sound/
```

---

### Som personalizado toca como som antigo

**Causa**

Cache do navegador.

**Solução utilizada**

Criar nomes novos:

```text
sound_custom_1.mp3
sound_custom_2.mp3
```

---

### Arquivo WAV não toca

**Causa**

O JavaScript do GLPI procura MP3/OGG.

**Solução**

Converter com `ffmpeg`:

```bash
ffmpeg -y -i entrada.wav -codec:a libmp3lame -q:a 2 saida.mp3
```

---

### Menu continua mostrando somente A, B, C e D

**Causas**

- template editado incorretamente;
- bloco duplicado;
- cache do GLPI.

**Solução**

Confirmar uma única ocorrência:

```bash
grep -c "dropdownArrayField('notifications_ajax_sound'" \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

Resultado:

```text
1
```

Depois:

```bash
runuser -u www-data -- php /var/www/glpi/bin/console cache:clear
```

---

## 21. Observação importante sobre atualizações

O arquivo:

```bash
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig
```

faz parte do GLPI.

Uma atualização do sistema pode sobrescrever essa personalização.

Antes de atualizar o GLPI:

```bash
cp \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig \
/root/ajax_setting.html.twig.custom-backup
```

Depois da atualização, validar novamente o menu de sons.

---

## 22. Backup dos sons personalizados

Recomendado:

```bash
mkdir -p /root/glpi-custom-backup/sound
```

```bash
cp /var/www/glpi/public/sound/sound_custom_*.mp3 \
/root/glpi-custom-backup/sound/
```

Também salvar o template:

```bash
cp \
/var/www/glpi/templates/pages/setup/notification/ajax_setting.html.twig \
/root/glpi-custom-backup/
```

---

## 23. Resultado final

Após a configuração:

- notificações do navegador habilitadas;
- sons personalizados adicionados;
- nomes personalizados exibidos no GLPI;
- abertura de chamado notificando os atendentes;
- som reproduzido nos navegadores dos atendentes;
- configuração validada com teste de navegador.

---

## Recomendações

Para ambiente definitivo:

1. Publicar o GLPI em HTTPS.
2. Utilizar DNS interno, por exemplo:

```text
https://glpi.empresa.local
```

3. Utilizar certificado confiável.
4. Distribuir a CA interna por GPO/Intune, se aplicável.
5. Manter backup das customizações antes de atualizar o GLPI.
6. Utilizar grupo específico de atendentes como destinatário das notificações.
7. Usar sons curtos, discretos e distintos para evitar excesso de ruído.

---

**Documento:** GLPI — Notificações do Navegador com Sons Personalizados  
**Ambiente:** Debian + Apache + GLPI  
**Última revisão:** 22/09/2026
