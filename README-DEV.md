# Devin PT-BR — montagem e auditoria

O instalador gera um pacote VSIX ajustado à versão encontrada no computador, usando o pacote-base oficial Português (Brasil) e os metadados NLS da instalação atual.

<!-- devin-current-audit -->
## Auditoria vigente — Devin 1.126.0 / mecanismo 3.10.48
O catálogo-base recebeu 51 entradas e esta rodada acrescentou duas traduções de rótulos visíveis específicos do Devin. Auditoria do pacote gerado: 20.276/21.220 mensagens NLS (95,6%), com 944 entradas sem tradução direta, em grande parte conteúdo técnico e de acessibilidade. Os scripts de instalação e restauração deduplicam caminhos encontrados por fontes diferentes e mantêm o backup vinculado à versão da instalação escolhida.
<!-- /devin-current-audit -->

## Montar manualmente

1. Extraia `assets/base-language-pack-ptbr-1.128.vsix` para uma pasta temporária.
2. Defina `DEVIN_APP_VERSION` para a versão do Devin desejada.
3. Execute `node tools/build-language-pack.cjs <pasta-extraida> <pasta-de-saida>`.
4. Compacte o conteúdo da pasta de saída como VSIX.

O empacotador lê `nls.metadata.json`, `nls.keys.json` e `nls.messages.json` da instalação encontrada. `translations/devin.json` mantém os complementos próprios do Devin. Cada atualização do aplicativo deve passar por uma nova auditoria de catálogo.

## Auditoria

`node tools/audit-catalog.cjs <nls.metadata.json> <main.i18n.json>` compara a cobertura com os arquivos NLS da instalação Devin 1.126.0.

As chaves internas são índices NLS ordenados e precisam corresponder à versão-alvo; não copie um catálogo gerado para uma versão diferente sem reconstruí-lo.
<!-- devin-status -->
## Estado da atualização — 13/10/2026 · Devin Desktop 1.126.0 / mecanismo 3.10.48

- Foram acrescentadas 51 entradas ao catálogo-base e, nesta rodada, 2 rótulos visíveis específicos do Devin. O pacote gerado foi auditado com 20.276/21.220 mensagens NLS traduzidas diretamente (95,6%), com 944 entradas restantes, em grande parte técnicas ou de acessibilidade.
- Os textos mostrados nas capturas desta rodada já estavam no catálogo, portanto não foram contados de novo. A revisão de novas strings específicas do Devin fica para uma próxima rodada.
- Instalador e restaurador validam primeiro caminhos do processo, registro e locais conhecidos; só quando nenhum candidato válido contém Devin.exe e `resources\app\package.json` iniciam a busca profunda em unidades fixas e removíveis. A busca ignora pastas raiz do sistema e junctions, deduplica caminhos, mantém instalações distintas selecionáveis e não usa a barra sobreposta do PowerShell. Mantenha `Find-Installations.ps1` ao lado dos scripts.
<!-- /devin-status -->


- Devin AI: revisão de acentuação concluída; 0 textos de script precisaram de correção e 0 novas strings foram adicionadas nesta revisão.
# Devin PT-BR — montagem e auditoria

O instalador gera um pacote VSIX ajustado à versão encontrada no computador, usando o pacote-base oficial Português (Brasil) e os metadados NLS da instalação atual.

<!-- devin-current-audit -->
## Auditoria vigente — Devin 1.126.0 / mecanismo 3.10.48
O catálogo-base recebeu 51 entradas e esta rodada acrescentou duas traduções de rótulos visíveis específicos do Devin. Auditoria do pacote gerado: 20.276/21.220 mensagens NLS (95,6%), com 944 entradas sem tradução direta, em grande parte conteúdo técnico e de acessibilidade. Os scripts de instalação e restauração deduplicam caminhos encontrados por fontes diferentes e mantêm o backup vinculado à versão da instalação escolhida.
<!-- /devin-current-audit -->

## Montar manualmente

1. Extraia `assets/base-language-pack-ptbr-1.128.vsix` para uma pasta temporária.
2. Defina `DEVIN_APP_VERSION` para a versão do Devin desejada.
3. Execute `node tools/build-language-pack.cjs <pasta-extraida> <pasta-de-saida>`.
4. Compacte o conteúdo da pasta de saída como VSIX.

O empacotador lê `nls.metadata.json`, `nls.keys.json` e `nls.messages.json` da instalação encontrada. `translations/devin.json` mantém os complementos próprios do Devin. Cada atualização do aplicativo deve passar por uma nova auditoria de catálogo.

## Auditoria

`node tools/audit-catalog.cjs <nls.metadata.json> <main.i18n.json>` compara a cobertura com os arquivos NLS da instalação Devin 1.126.0.

As chaves internas são índices NLS ordenados e precisam corresponder à versão-alvo; não copie um catálogo gerado para uma versão diferente sem reconstruí-lo.
<!-- devin-status -->
## Estado da atualização — 13/10/2026 · Devin Desktop 1.126.0 / mecanismo 3.10.48

- Foram acrescentadas 51 entradas ao catálogo-base e, nesta rodada, 2 rótulos visíveis específicos do Devin. O pacote gerado foi auditado com 20.276/21.220 mensagens NLS traduzidas diretamente (95,6%), com 944 entradas restantes, em grande parte técnicas ou de acessibilidade.
- Os textos mostrados nas capturas desta rodada já estavam no catálogo, portanto não foram contados de novo. A revisão de novas strings específicas do Devin fica para uma próxima rodada.
- Instalador e restaurador validam primeiro caminhos do processo, registro e locais conhecidos; só quando nenhum candidato válido contém Devin.exe e `resources\app\package.json` iniciam a busca profunda em unidades fixas e removíveis. A busca ignora pastas raiz do sistema e junctions, deduplica caminhos, mantém instalações distintas selecionáveis e não usa a barra sobreposta do PowerShell. Mantenha `Find-Installations.ps1` ao lado dos scripts.
<!-- /devin-status -->

