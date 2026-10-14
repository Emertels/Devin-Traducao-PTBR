# 🤖 Devin AI Desktop — Tradução para Português do Brasil (PT-BR) 🇧🇷
### Revisão do instalador — 14/10/2026
O instalador PowerShell foi recuperado após corrupção de aspas que impedia sua execução e agora carrega acentos corretamente com BOM UTF-8, sem mudar o código de página do CMD. Os metadados NLS são buscados na instalação detectada, inclusive quando está em outra unidade. Se ocorrer uma falha, o CMD permanece aberto para leitura. Nenhuma nova string de interface foi incluída nesta correção.


![Versão](https://img.shields.io/badge/Versão-v1.0.0-blue?style=for-the-badge)
![Idioma](https://img.shields.io/badge/Idioma-Português%20(Brasil)-green?style=for-the-badge)

Pacote portátil de localização oficial do **Devin Desktop (Devin AI)** para Português do Brasil (pt-BR), desenvolvido e preparado por **Emerson Teles**. A tradução cobre mais de 20.276 mensagens NLS (95,6% de cobertura direta), módulos exclusivos do Devin/Windsurf (agentes, editor, sessões em nuvem, alternâncias, SSH e painéis integrados), com instalador e restaurador automatizados.

<!-- devin-status -->
## Estado da atualização — 14/10/2026 · Devin Desktop 1.126.0 / mecanismo 3.10.48

- O pacote gerado foi auditado contra os metadados NLS da instalação Devin 1.126.0: 20.276/21.220 mensagens traduzidas diretamente (95,6%), com 944 entradas restantes, em grande parte conteúdo técnico e de acessibilidade. A auditoria encontrou dois rótulos visíveis sem tradução — “Explain and Fix Problem” e “Explain and Fix” — agora mapeados em PT-BR.
- Os textos mostrados nas capturas desta rodada já estavam no catálogo, portanto não foram contados de novo. A revisão de novas strings específicas do Devin fica para uma próxima rodada.
- Em 14/10/2026, o usuário confirmou que testou a instalação e a restauração do Devin; ambas estão funcionando. A correção de BOM UTF-8 do instalador também foi validada sintaticamente.
- Instalador e restaurador validam primeiro caminhos do processo, registro e locais conhecidos; só quando nenhum candidato válido contém Devin.exe e `resources\app\package.json` iniciam a busca profunda em unidades fixas e removíveis. A busca ignora pastas raiz do sistema e junctions, deduplica caminhos, mantém instalações distintas selecionáveis e não usa a barra sobreposta do PowerShell. Mantenha `Find-Installations.ps1` ao lado dos scripts.
<!-- /devin-status -->

---

## 🎥 Vídeo Tutorial & Demonstração

*(Vídeo tutorial em breve! Enquanto isso, siga o passo a passo completo de instalação abaixo.)*

---

## 📋 Índice
1. [Sobre o Pacote](#-sobre-o-pacote)
2. [O que Foi Traduzido](#-o-que-foi-traduzido)
3. [Destaque Tecnológico: Remontagem NLS Dinâmica](#-destaque-tecnológico-remontagem-nls-dinâmica)
4. [Estrutura da Pasta](#-estrutura-da-pasta)
5. [Como Instalar em 2 Cliques](#-como-instalar-em-2-cliques)
6. [Como Restaurar o Original de Fábrica](#-como-restaurar-o-original-de-fábrica)
7. [Sistema de Backup Modular e Segurança](#-sistema-de-backup-modular-e-segurança)
8. [Diretórios no Computador](#-diretórios-no-computador)
9. [Créditos e Autoria](#-créditos-e-autoria)
10. [Sobre o Autor](#-sobre-o-autor)

---

## 🌟 Sobre o Pacote

Este pacote foi desenvolvido para localizar profundamente as mensagens e interfaces do Devin Desktop para pt-BR com detecção automática de versão, backup e restauração:
* **Portátil e Independente:** Pode ser executado de qualquer pasta (ex: `C:\Projetos`, `Área de Trabalho`, `Downloads`, `Pen-drive`, `HD Externo`), sem necessidade de conexão com a internet.
* **Base Oficial e Extensões Devin:** Deriva do pacote oficial Português (Brasil) da Microsoft para VS Code, complementado cirurgicamente com 53 módulos e extensões exclusivas do Devin.
* **Remontagem Dinâmica:** Detecta a versão do Devin, remonta o catálogo PT-BR para os índices NLS daquela versão e atualiza os checksums de `product.json` preservando a integridade do aplicativo.
* **Backup Automático e Seguro:** Salva a configuração original em `<pasta do Devin>\_backups\<versão>` sem sobrescrever backups prévios antes de qualquer alteração.
* **Execução Limpa e Desacoplada:** Ao iniciar o Devin após a tradução, o aplicativo é aberto em processo isolado e independente, configurando explicitamente `--locale=pt-br`.

---

## 🎯 O que Foi Traduzido

| Categoria | Detalhes da Localização |
| :--- | :--- |
| **Catálogo NLS (20.276+ Mensagens)** | Cobertura de 95,6% das mensagens do Devin Desktop, abrangendo menus, comandos, sessões na nuvem, alternância Agente/Editor, diagnósticos, barra lateral e atalhos. |
| **Módulos do Devin/Windsurf** | Telas de boas-vindas, configurações do modelo, alternância entre chat e editor de código, SSH para agentes remotos e comandos de interface. |
| **Diálogo "Sobre o Devin"** | Crédito oficial integrado: *"Tradução PT-BR: Emerson Teles"* visível diretamente na caixa Sobre em português. |
| **Ações de IA e Diagnóstico** | Localização de botões como *"Explicar e corrigir o problema"* (*Explain and Fix Problem*) e orientações de execução de agentes. |
| **Seletor de Idiomas Nativos** | Configuração automática de `pt-br` no perfil do usuário (`argv.json`), garantindo inicialização nativa em português. |

---

## ⚡ Destaque Tecnológico: Remontagem NLS Dinâmica

Diferente de métodos manuais que causam inconsistências de versão, este pacote conta com o **`core/instalar.ps1`** e **`tools/build-language-pack.cjs`**:
* **Busca em Camadas (`Find-Installations.ps1`):** Localiza a instalação ativa através de processos em execução, chaves de registro do Windows e varredura recursiva de unidades montadas.
* **Remontagem de Índices:** Mapeia os identificadores numéricos exatos da versão instalada, evitando mensagens trocadas ou descompassadas.
* **Injeção Segura:** Atualiza checksums de `product.json` para permitir que o Electron carregue os bundles sem alertas de corrupção.

---

## 📁 Estrutura da Pasta

```text
Devin-Traducao-PTBR/
├── core/
│   ├── Find-Installations.ps1          # Motor de busca em camadas de instalações
│   ├── instalar.ps1                    # Script principal de instalação e montagem NLS
│   └── restaurar.ps1                   # Script de restauração e reversão total
├── tools/
│   ├── audit-catalog.cjs               # Auditoria estática de chaves e lacunas
│   ├── build-language-pack.cjs         # Construtor dinâmico do pacote de idioma
│   └── EmbeddedUiLiteralReplacer.cs    # Substituidor de literais da interface embutida
├── translations/
│   ├── devin.json                      # Catálogo central de traduções do Devin
│   ├── devin-complemento.json          # Complementos e termos específicos
│   └── embedded-ui.json                # Rótulos da interface web e componentes
├── assets/
│   ├── base-language-pack-ptbr-1.128.vsix
│   └── Devin-PTBR.vsix                 # VSIX base para remontagem
├── Instalar-Traducao.bat               # Instalador executável em 2 cliques
└── Restaurar-Original.bat              # Restaurador executável em 2 cliques
```

---

## 🚀 Como Instalar em 2 Cliques

1. Baixe o pacote portátil `Devin-Traducao-PTBR-v1.0.0-Portable.zip` e extraia para qualquer pasta.
2. Dê um duplo clique no arquivo:
   ```cmd
   Instalar-Traducao.bat
   ```
3. O instalador detecta a versão do Devin, remonta o catálogo PT-BR, cria backup em `_backups\<versão>\` e instala a localização.
4. Ao final, pressione **S** para iniciar o Devin Desktop em Português do Brasil!

---

## 🔄 Como Restaurar o Original de Fábrica

Se desejar retornar o Devin exatamente para o estado original em inglês:
1. Dê um duplo clique no arquivo:
   ```cmd
   Restaurar-Original.bat
   ```
2. O script remove o pacote PT-BR, recupera `argv.json` e restaura os bundles originais a partir da pasta de backup.
3. Pressione **S** para abrir o Devin no idioma padrão de fábrica.

---

## 🛡️ Sistema de Backup Modular e Segurança

* **Backup Automático por Versão:** Antes de alterar qualquer arquivo, o instalador salva os bundles originais e a configuração em:
  `<pasta-do-Devin>\_backups\<versão>\`
* **Proteção contra Sobrescrita:** O backup original nunca é sobrescrito por arquivos já traduzidos.
* **Reversibilidade Garantida:** A desinstalação é 100% limpa e restaura o estado de fábrica com verificação de integridade.

---

## 📍 Diretórios no Computador

* **Diretório do Aplicativo:**
  `%LOCALAPPDATA%\Programs\Devin\`
* **Recursos do Electron:**
  `%LOCALAPPDATA%\Programs\Devin\resources\app\`
* **Pasta Segura de Backup Original:**
  `%LOCALAPPDATA%\Programs\Devin\_backups\`
* **Perfil do Usuário e Idioma:**
  `%USERPROFILE%\.devin\`

---

## ✍️ Créditos e Autoria

* **Tradução PT-BR: Emerson Teles**
* **Arquitetura do Instalador e Localização:** Emerson Teles
* **Localização:** Português do Brasil (`pt-BR`)
* **Distribuição:** Pacote portátil, autônomo e de alta performance.

*Devin AI é uma marca registrada de seus respectivos desenvolvedores (Cognition AI). O catálogo base deriva do pacote oficial do VS Code (Microsoft Corporation, licença MIT). Este pacote de tradução é uma personalização desenvolvida de forma independente por Emerson Teles.*

---

## 👨‍💻 Sobre o Autor

Desenvolvido e mantido por **Emerson Teles** (conhecido na comunidade como **Emertels**).

Entusiasta de tecnologia, informática, jogos, manutenção de sistemas e tradução/localização de softwares para Português do Brasil (PT-BR). Desenvolvedor focado em utilitários práticos, ferramentas de produtividade, automação inteligente em PowerShell e soluções completas de localização técnica que aproximam ferramentas modernas do público brasileiro.

### 🛠️ Projetos & Contribuições

- [AI-Chat-Vault](https://github.com/Emertels/AI-Chat-Vault) — Backup portátil e recuperação de conversas locais de 20+ ferramentas e assistentes de IA.
- [Antigravity — Tradução PT-BR](https://github.com/Emertels/Antigravity-Traducao-PTBR) — Localização completa do Google Antigravity Desktop para Português do Brasil.
- [Codex Router — Tradução PT-BR](https://github.com/Emertels/CodexRouter-Traducao-PTBR) — Pacote de tradução e localização do Codex Router Control Center em PT-BR.
- [Cursor AI — Tradução PT-BR](https://github.com/Emertels/Cursor-Traducao-PTBR) — Localização completa e profunda do Cursor AI para Português do Brasil.
- [Devin AI — Tradução PT-BR](https://github.com/Emertels/Devin-Traducao-PTBR) — Tradução e localização completa do Devin Desktop para Português do Brasil.
- [GPU Tweak III — Tradução PT-BR](https://github.com/Emertels/GPU-Tweak-III-Traducao-PTBR) — Tradução em português brasileiro e instalador automatizado para ASUS GPU Tweak III.
- [Microsoft Photos Fix](https://github.com/Emertels/Microsoft-Photos-Fix) — Solução definitiva em PowerShell e C# para rota de inicialização rápida e visualização no app Fotos do Windows.
- [PSBBN-Translator](https://github.com/Emertels/PSBBN-Translator) — Suíte corporativa de tradução e localização para o PSBBN Definitive Project (PlayStation 2) em 40 idiomas.
- [Silent Hill: Homecoming — Tradução PT-BR](https://github.com/Emertels/Silent-Hill-Homecoming-Traducao-PTBR) — Tradução e revisão completa do jogo para PC em português brasileiro.
- [Suite-Emuladores](https://github.com/Emertels/Suite-Emuladores) — Suíte inteligente em PowerShell para download e atualização autônoma de 56 emuladores e frontends no Windows.
- [ZCode — Tradução PT-BR](https://github.com/Emertels/ZCode-Traducao-PTBR) — Tradução e localização completa do ZCode Desktop para Português do Brasil.

### 🌐 Conecte-se comigo & Comunidades Oficiais

<div align="left">

[![GitHub](https://img.shields.io/badge/GitHub-Emertels-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emertels)
[![Website](https://img.shields.io/badge/Website-Emerson_Teles-0070F3?style=for-the-badge&logo=googlechrome&logoColor=white)](https://emertels.github.io)
[![Discord](https://img.shields.io/badge/Discord-Emertels%20Server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://emertels.github.io/discord)
[![X / Twitter](https://img.shields.io/badge/X_Twitter-@emertels-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/emertels)
[![YouTube](https://img.shields.io/badge/YouTube-Emerson_Teles-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@emersonteles2379)
[![Telegram](https://img.shields.io/badge/Telegram-Aplicativos%20Mods-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/apksmodsandroid)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Apoiar%20Projeto-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/emertels)

</div>
