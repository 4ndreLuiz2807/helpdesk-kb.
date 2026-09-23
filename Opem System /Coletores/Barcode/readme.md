
# Ativação do Barcode Utility / Scanner Nativo no MovFast Ranger 2 via ADB

## Objetivo

Documentar o procedimento utilizado para restaurar as funcionalidades nativas de leitura de código de barras do **MovFast Ranger 2** quando o equipamento está gerenciado pelo **Microsoft Intune em modo quiosque Android Enterprise** e apresenta sintomas como:

- botão laranja do scanner não aciona a mira;
- Barcode Utility não aparece entre os aplicativos;
- aplicativo nativo existe no firmware, mas não está disponível para o usuário Android atual;
- equipamento continua normalmente registrado no Intune.

O procedimento utiliza o **Android SDK Platform-Tools (ADB)**, sem necessidade de reinstalar firmware ou baixar APK do Barcode Utility.

---

## Cenário

- Dispositivo: **MovFast Ranger 2**
- Gerenciamento: **Microsoft Intune**
- Modo de registro: **Android Enterprise Dedicated**
- Launcher: **Managed Home Screen**
- Modo: **Quiosque**
- Scanner nativo: Xcheng / MovFast

Sintoma inicial:

```text
Botão laranja pressionado
        ↓
Scanner não acende
        ↓
Barcode Utility não aparece
```

---

## 1. Baixar o Android SDK Platform-Tools

No computador administrativo, baixe o **Android SDK Platform-Tools**.

Não é necessário instalar o Android Studio.

Após extrair, por exemplo:

```text
C:\Users\A N D R E\Desktop\platform-tools
```

Abra o PowerShell nessa pasta.

Valide o ADB:

```powershell
.\adb.exe version
```

Exemplo de retorno:

```text
Android Debug Bridge version 1.0.41
Version 37.0.1-15733141
```

---

## 2. Liberar temporariamente a Depuração USB

Como o Ranger 2 estava em modo quiosque, foi necessário permitir temporariamente as opções de desenvolvedor pelo Intune.

No perfil Android Enterprise utilizado para diagnóstico:

```text
Configurações do desenvolvedor = Permitir
```

Depois:

1. sincronize o dispositivo no Intune;
2. no Ranger 2, acesse:

```text
Configurações
→ Sistema
→ Opções do desenvolvedor
→ Depuração USB
```

3. habilite **Depuração USB**;
4. conecte o Ranger 2 ao computador via USB.

---

## 3. Autorizar o ADB

Execute:

```powershell
.\adb.exe devices
```

Inicialmente pode aparecer:

```text
MT15AM424070845 unauthorized
```

No Ranger 2, aceite a mensagem:

```text
Permitir depuração USB?
```

Depois execute novamente:

```powershell
.\adb.exe devices
```

Resultado esperado:

```text
List of devices attached
MT15AM424070845 device
```

---

## 4. Localizar os componentes do scanner

Execute:

```powershell
.\adb.exe shell pm list packages -u | Select-String -Pattern "xcheng|scan|barcode"
```

O parâmetro `-u` é importante porque também exibe pacotes que continuam registrados no Android, mesmo que não estejam instalados para o usuário atual.

Foram encontrados componentes como:

```text
com.xcheng.scanner4710
com.xcheng.scannere3
com.xcheng.datawedge

com.xcheng.scanner4710.overlay
com.xcheng.scannere3.overlay
com.xcheng.deviceconfig
com.xcheng.movstageservice
com.xcheng.pandora.deviceconfigservice
```

---

## 5. Comparar com os pacotes disponíveis para o usuário atual

Execute sem o parâmetro `-u`:

```powershell
.\adb.exe shell pm list packages | Select-String -Pattern "scanner4710|scannere3|datawedge"
```

Antes da correção, o resultado mostrava somente:

```text
package:com.xcheng.scanner4710.overlay
package:com.xcheng.scannere3.overlay
```

Não apareciam:

```text
com.xcheng.scannere3
com.xcheng.datawedge
```

Isso indicou que os componentes continuavam presentes no firmware, mas não estavam instalados para o usuário Android `0`.

---

## 6. Confirmar que os APKs continuam no firmware

Execute:

```powershell
.\adb.exe shell "find /system /product /vendor /system_ext -type f 2>/dev/null | grep -i -E 'barcode|scan|xcheng'"
```

Entre os resultados encontrados:

```text
/system/app/Scanner4100/Scanner4100.apk
/system/app/ScannerE3_Code/ScannerE3_Code.apk

/product/overlay/ScannerE3Overlay.apk
/product/overlay/Scanner4100Overlay.apk

/vendor/etc/init/e3scan.rc
/vendor/etc/init/e3scan1.rc
/vendor/etc/init/e3scan2.rc
/vendor/etc/init/e3scan3.rc
```

Isso confirmou que **não era necessário baixar o Barcode Utility**.

---

## 7. Restaurar o DataWedge

O primeiro componente restaurado foi:

```text
com.xcheng.datawedge
```

Execute:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.datawedge
```

Resultado:

```text
Package com.xcheng.datawedge installed for user: 0
```

Valide:

```powershell
.\adb.exe shell pm list packages | Select-String -Pattern "datawedge"
```

Resultado esperado:

```text
package:com.xcheng.datawedge
```

---

## 8. Restaurar o Barcode Utility / Scanner E3

O componente que restaurou o scanner no Ranger 2 foi:

```text
com.xcheng.scannere3
```

Execute:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.scannere3
```

Resultado esperado:

```text
Package com.xcheng.scannere3 installed for user: 0
```

Valide:

```powershell
.\adb.exe shell pm list packages | Select-String -Pattern "scannere3|datawedge"
```

Resultado esperado:

```text
package:com.xcheng.scannere3
package:com.xcheng.scannere3.overlay
package:com.xcheng.datawedge
```

Após esse procedimento, o botão laranja voltou a acionar o scanner.

---

## 9. Resultado final

Antes:

```text
Botão laranja
     ↓
Nada acontece
     ↓
Mira não acende
```

Depois:

```text
com.xcheng.datawedge restaurado
            +
com.xcheng.scannere3 restaurado
            ↓
Scanner operacional
            ↓
Botão laranja funcionando
            ↓
Leitura de código de barras restaurada
```

---

## 10. Comandos de recuperação rápida

Após estabelecer comunicação ADB:

```powershell
.\adb.exe devices
```

Verificar todos os pacotes relacionados, inclusive removidos para o usuário:

```powershell
.\adb.exe shell pm list packages -u | Select-String -Pattern "scannere3|datawedge"
```

Verificar os pacotes realmente instalados para o usuário atual:

```powershell
.\adb.exe shell pm list packages | Select-String -Pattern "scannere3|datawedge"
```

Restaurar o DataWedge:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.datawedge
```

Restaurar o ScannerE3 / Barcode Utility:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.scannere3
```

Validar:

```powershell
.\adb.exe shell pm list packages | Select-String -Pattern "scannere3|datawedge"
```

---

## 11. O que faz o `install-existing`

O comando:

```powershell
adb shell cmd package install-existing --user 0 PACOTE
```

**não instala um APK externo**.

Ele solicita ao Android que disponibilize para o usuário especificado um pacote que **já existe na imagem do sistema**.

Neste caso:

```text
Firmware Ranger 2
│
├── ScannerE3_Code.apk
│      └── com.xcheng.scannere3
│
└── DataWedge
       └── com.xcheng.datawedge
```

Fluxo:

```text
Pacote existe no firmware
        ↓
Não está instalado para user 0
        ↓
install-existing
        ↓
Pacote restaurado para user 0
        ↓
Scanner volta a funcionar
```

---

## 12. Atenção ao comando `pm`

O comando abaixo **não funciona diretamente no PowerShell do Windows**:

```powershell
pm list packages -u
```

`pm` é o **Package Manager do Android**.

### Errado

```powershell
pm list packages -u
```

### Correto

```powershell
.\adb.exe shell pm list packages -u
```

Sempre que utilizar comandos Android como:

```text
pm
cmd package
dumpsys
getevent
am
```

execute por meio do `adb shell`.

---

## 13. Pacotes que não devem ser confundidos

Também existem:

```text
com.xcheng.scanner4710.overlay
com.xcheng.scannere3.overlay
```

Esses pacotes são **overlays** e não são o Barcode Utility.

Pacote restaurado com sucesso:

```text
com.xcheng.scannere3
```

Componente auxiliar restaurado:

```text
com.xcheng.datawedge
```

---

## 14. Não habilitar ScannerE3 e Scanner4710 indiscriminadamente

O firmware possui suporte a mais de um engine:

```text
com.xcheng.scannere3
com.xcheng.scanner4710
```

No equipamento validado neste procedimento, o pacote que resolveu o problema foi:

```text
com.xcheng.scannere3
```

Por isso, não é recomendado executar automaticamente:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.scanner4710
```

sem antes validar o hardware e o firmware do equipamento.

---

## 15. Tornar a correção permanente pelo Intune

O ADB corrige o equipamento atual, mas o objetivo é impedir que o problema volte após:

- factory reset;
- novo enrollment;
- reprovisionamento;
- reaplicação das políticas;
- novo ingresso no modo quiosque.

No Intune, cadastre o aplicativo nativo como **Android Enterprise System App**.

No portal utilizado neste ambiente:

```text
Aplicativos
→ Android
→ Criar
→ Categoria: Aplicativo referenciado
→ Aplicativo do sistema Android Enterprise
```

Cadastrar:

```text
Nome:
Barcode Utility - Ranger 2

Editor:
Xcheng / MovFast

Package name:
com.xcheng.scannere3
```

Em **Atribuições**:

```text
Obrigatório / Required
→ Grupo dos Ranger 2
```

Cadastrar também, caso necessário:

```text
Nome:
DataWedge - Ranger 2

Package name:
com.xcheng.datawedge
```

Também como `Required`.

---

## 16. Estrutura recomendada no Intune

```text
Android Enterprise Dedicated
          │
          ├── Managed Home Screen
          │
          ├── Aplicativo operacional
          │
          └── Componentes nativos preservados
                    │
                    ├── com.xcheng.scannere3
                    └── com.xcheng.datawedge
```

Resultado esperado:

```text
Intune
  +
Modo quiosque
  +
Apps controlados
  +
Scanner físico funcionando
```

---

## 17. Checklist de validação

```text
[ ] Ranger 2 aparece no Intune
[ ] Android Enterprise Dedicated
[ ] Managed Home Screen instalado
[ ] Aplicativo operacional instalado
[ ] com.xcheng.scannere3 disponível para user 0
[ ] com.xcheng.datawedge disponível para user 0
[ ] Botão laranja aciona a mira
[ ] Scanner lê código de barras
[ ] Código é entregue ao aplicativo
[ ] Scanner continua funcionando após reiniciar
[ ] Scanner continua funcionando após Sync do Intune
```

---

## Resumo da solução

Os dois comandos que efetivamente recuperaram as funcionalidades foram:

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.datawedge
```

```powershell
.\adb.exe shell cmd package install-existing --user 0 com.xcheng.scannere3
```

Pacote identificado para o Barcode/Scanner no equipamento testado:

```text
com.xcheng.scannere3
```

Componente auxiliar:

```text
com.xcheng.datawedge
```

A correção **não exigiu baixar APK, reinstalar firmware ou remover o dispositivo do Intune**.

O aplicativo já estava presente no firmware e precisou apenas ser restaurado para o usuário Android utilizado pelo modo quiosque.

---

## Observação de segurança

Após finalizar o diagnóstico e confirmar que a configuração permanente no Intune está funcionando, recomenda-se voltar a bloquear:

```text
Configurações do desenvolvedor
Depuração USB
```

caso essas funções não sejam necessárias para a operação normal dos coletores.
