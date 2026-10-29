
# QR Inventário para GLPI — Protótipo 0.1.0

**Objetivo:** Etiquetar notebooks e desktops já registrados em **Ativos → Computadores** com QR Code, consultar a ficha ao ler a etiqueta no celular, registrar conferências físicas e exportar o histórico em CSV.

## Compatibilidade e escopo

- Criado para avaliação no **GLPI 11.x e 12.x**, **Debian 13**, PHP 8.4 e MariaDB. Estrutura verificada contra documentação do GLPI 11/12; **não executado dentro de uma instância GLPI real**. Validar em laboratório antes de produção.
- **Não** é um agente de inventário. Não descobre equipamentos, não cria computadores automaticamente e não atualiza seus campos por leitura do QR. Use GLPI Agent para coleta automática, e o formulário nativo do GLPI para alterar os dados.
- O QR contém **apenas a URL absoluta** da ficha. Todo conteúdo da ficha requer uma sessão autorizada no GLPI (permite respeitar perfis/entidades).
- A conferência física é adicionada à tabela própria `glpi_plugin_qrinventory_checks` quando alguém com direito de atualização clica **Confirmar conferência**. Escanear sem confirmar não grava histórico.
- Os testes de geração do QR foram realizados localmente com um decodificador; é necessário validar também autenticação, persistência e impressão no GLPI real.

## Instalação de laboratório em Debian 13

Assumindo a instalação tradicional do laboratório em `/var/www/glpi` e o Apache apontando para `/var/www/glpi/public`:

1. Faça um backup/snapshot da VM e do banco antes de instalar plugins experimentais.
2. Transfira `qrinventory_v0.1.0.zip` para o servidor (ex.: `/tmp/qrinventory_v0.1.0.zip`).
3. Execute:

```bash
sudo apt-get install -y unzip
sudo unzip -o /tmp/qrinventory_v0.1.0.zip -d /var/www/glpi/plugins/
sudo chown -R root:www-data /var/www/glpi/plugins/qrinventory
sudo find /var/www/glpi/plugins/qrinventory -type d -exec chmod 755 {} \;
sudo find /var/www/glpi/plugins/qrinventory -type f -exec chmod 644 {} \;
php -l /var/www/glpi/plugins/qrinventory/setup.php
php -l /var/www/glpi/plugins/qrinventory/front/asset.php
```

4. No GLPI, entre como administrador e vá a **Configurar → Plugins** (ou **Configuração → Plugins**, dependendo do idioma). Localize **QR Inventário**, clique **Instalar** e depois **Ativar**.
5. Saia e entre novamente para atualizar o menu. Procure em **Ferramentas → QR Inventário** ou abra diretamente:

```text
http://192.168.18.150/plugins/qrinventory/front/index.php
```

> O IP é um exemplo do seu laboratório mais recente. Substitua-o pelo endereço realmente acessível. Se a VM tiver IP diferente, use esse IP ou DNS. Na versão 11/12, URLs dos plugins são tratadas pelo roteador do GLPI, mesmo com DocumentRoot em `/public`.

## Teste funcional sugerido

1. Em **Ativos → Computadores**, cadastre um notebook de teste (ex.: `NOTE-LAB-001`) com **Patrimônio** `PAT-001`, serial, tipo, modelo e localização.
2. Abra **QR Inventário**; pesquise `NOTE-LAB-001`, marque a caixa e escolha **Imprimir etiquetas selecionadas** (60 × 39 mm, folha A4).
3. Antes de imprimir, confira se está acessando o GLPI pelo IP ou DNS que o celular também alcança. Evite `localhost`/`127.0.0.1`.
4. Escaneie a etiqueta pela câmera do celular conectado à mesma rede (ou VPN). Faça login no GLPI se solicitado. Confira nome, serial, patrimônio, tipo e local.
5. Com um perfil que possa **atualizar computadores**, digite uma observação e pressione **Confirmar conferência**.
6. Atualize a ficha: a conferência e o responsável devem aparecer no histórico. Na página principal, use **Exportar conferências CSV**.
7. No cadastro nativo, altere a localização do notebook. Escaneie novamente: a ficha QR deve apresentar a informação atualizada automaticamente.

## Resolução de problemas

- **Plugin não aparece**: valide a pasta `/var/www/glpi/plugins/qrinventory` e os arquivos `setup.php` e `hook.php`, permissões e a tela de Plugins. Não coloque o código na pasta de *dados* `GLPI_PLUGIN_DOC_DIR`.
- **Erro 500**: execute `php -l` nos arquivos, veja logs do GLPI (`/var/log/glpi` ou caminho configurado) e logs PHP-FPM/Apache. Teste no GLPI 12.0.1 com plugins da mesma versão.
- **QR não abre no celular**: valide host, IP fixo/DNS, firewall, Wi-Fi, VPN, HTTP/HTTPS e login. Não é recomendável abrir o GLPI diretamente na internet sem VPN/HTTPS.
- **Nenhum computador**: crie o ativo no inventário e confirme permissões de leitura/entidade; o plugin não cria equipamentos novos.
- **Não consigo confirmar**: perfil sem direito de atualização do computador, plugin não instalado com sua tabela, ou restrição CSRF (GLPI 11 exige token, GLPI 12 usa validação de origem).
- **Lista incompleta**: a versão de teste limita a consulta a 500 registros candidatos e exibe até 60 itens autorizados. Use a busca para encontrar um ativo específico.

## Segurança e dados

- Nenhuma informação patrimonial é enviada para APIs externas ou geradores de QR online.
- O URL do QR não confere acesso: o GLPI autentica e checa permissão para abrir o item.
- O histórico de conferências inclui ID do ativo, ID do usuário, data/hora do servidor e observação (500 caracteres). Não guarda geolocalização.
- **Desinstalar o plugin exclui sua tabela de conferências e perde seu histórico.** Faça backup/CSV antes de desinstalar. Os computadores originais do GLPI não são excluídos.
- Para usar fora do laboratório, faça revisão de segurança, testes de integração e homologação de versões. Não é plugin oficial/certificado pelo projeto GLPI.

## Estrutura

```text
qrinventory/
  setup.php                 metadados e menu
  hook.php                  instalação/remoção da tabela do histórico
  front/index.php           busca, seleção e impressão de etiquetas
  front/asset.php           ficha autenticada e conferência
  front/report.php          exportação CSV das conferências
  inc/functions.php         permissões, URLs e consultas
  inc/menu.class.php        menu Ferramentas
  public/css/style.css      interface e layout de impressão
  public/js/qr-core.js      gerador de QR local (MIT)
  public/js/labels.js       geração SVG e impressão
  THIRD_PARTY_LICENSES.txt  atribuição da biblioteca
```

## Fontes técnicas

- Documentação GLPI: https://glpi-developer-documentation.readthedocs.io/en/latest/plugins/
- Guia de migração GLPI 11 (roteamento): https://glpi-developer-documentation.readthedocs.io/en/latest/upgradeguides/glpi-11.0.html
- Instruções oficiais de instalação de plugins: https://help.glpi-project.org/documentation/modules/configuration/plugins
- Plugin pronto alternativo para etiquetas: https://nextoolsolutions.com/plugins-glpi/barcode
