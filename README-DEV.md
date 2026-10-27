# Devin PT-BR — montagem e auditoria

Revisão de 27/10/2026 para Devin Desktop 3.11.228 / VS Code OSS 1.126.0.

O catálogo precisa usar `contents[moduleId][key]`, com o nome simbólico de cada chave de `nls.keys.json`. Um catálogo com índices numéricos é ignorado pelo carregador do Devin. A limpeza de cache é necessária após corrigir o conteúdo, mas não corrige um catálogo incompatível.

## Montagem

1. Extraia `assets/Devin-PTBR.vsix` para uma pasta temporária.
2. Defina `DEVIN_APP_VERSION=1.126.0` e, para outra instalação, os caminhos `DEVIN_NLS_METADATA`, `DEVIN_NLS_KEYS` e `DEVIN_NLS_MESSAGES`.
3. Execute `node tools/build-language-pack.cjs <pasta-extraida> <pasta-de-saida>`.
4. Compacte o conteúdo da pasta de saída como VSIX, sem adicionar uma pasta externa.

A base e o aplicativo devem ter a mesma versão. O pacote `base-language-pack-ptbr-1.128.vsix` é uma referência histórica e não é a base usada pelo instalador da versão 1.126.0.

## Verificação

- `node tools/audit-catalog.cjs <nls.metadata.json> <main.i18n.json> --summary`: conta apenas as chaves que o carregador realmente procura e rejeita chaves desconhecidas.
- `node tools/verify-shipped-nls.cjs <pasta-out-do-Devin> <main.i18n.json>`: extrai e executa o gerador NLS do aplicativo em uma pasta temporária isolada, sem iniciar Electron nem alterar o perfil do usuário. Verifica menus, campos do Sobre e crédito único. A extração é específica da compilação analisada e falha explicitamente se o carregador mudar.
- `node tests/embedded-ui.cjs`: verifica recursos JSON, chaves de objeto, expressões regulares, comentários, templates e reaplicação.

O carregador real confirmou 20.208 de 21.210 mensagens diferentes do inglês (95,3%). A conferência foi repetida no cache gerado pelo Devin 3.11.228 após a aplicação. As 1.002 entradas restantes incluem nomes, termos técnicos, textos de acessibilidade e outros rótulos ainda sem tradução direta; os textos embutidos fora do NLS são contados separadamente.

## Instalador e restaurador

Ambos oferecem `-NoPrompt` para execução sem a pergunta de abertura. O instalador calcula a revisão dos arquivos da tradução e dos scripts de instalação e a compara com a extensão instalada, evitando considerar um pacote antigo atualizado apenas por ter a mesma versão. A revisão precisa corresponder aos arquivos publicados no ZIP. O cache `clp` é arquivado antes de ser recriado. O restaurador usa os backups originais da versão selecionada e remove a extensão do mesmo identificador.

O tradutor embutido usa Acorn 8.16.0, incluído sob licença MIT em `tools/vendor`. Ele descobre os bundles web com strings do catálogo, ignora os pacotes de idioma auxiliares e prepara todos os arquivos antes da troca. Os backups originais são preservados. O instalador tenta encerrar o Devin normalmente e finaliza os processos restantes após 15 segundos.
