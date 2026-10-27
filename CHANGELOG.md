# Histórico de Alterações
## [1.1.0] - 2026-10-27

Compatível com Devin Desktop 3.11.228 e núcleo VS Code OSS 1.126.0.

### Traduções e varredura
- Adicionadas 26 entradas para rótulos da tela mostrada pelo usuário e tempos relativos: 30 palavras de origem correspondem a 31 palavras em PT-BR. Inclui dias, horas, minutos, meses, semanas e anos (por exemplo, “17d ago” → “há 17 dias”).
- A busca agora identifica bundles JavaScript com nomes gerados na interface web do Devin, além dos arquivos de sessão, chat e mensagens NLS. Na auditoria da versão instalada, 183 bundles candidatos foram analisados, 176 receberam alterações e 352 textos do catálogo foram localizados; todos os quatro rótulos usados como verificação obrigatória foram encontrados.
- Auditoria do pacote gerado contra a instalação atual: 20.208/21.210 mensagens NLS traduzidas (95,3%); 1.002 seguem sem tradução direta no catálogo.

### Instalador e pacote
- O instalador pede o encerramento normal do Devin e finaliza processos restantes se continuarem abertos após 15 segundos; atualiza também o checksum do host web.
- Construtor e instalador agora calculam a mesma revisão incluindo traduções, tokenizer e scripts de instalação. Ao reaplicar, o validador consulta os backups imutáveis caso o bundle ativo já tenha sido traduzido.
- Aplicação feita na instalação atual e cache de idioma renovado com cópia preservada. Pacote portátil v1.1.0 sem README, changelog ou arquivos de agente; histórico completo permanece nestas notas de versão.

### Correção do carregamento PT-BR — Devin Desktop 1.126.0 / 3.10.48 — 14/10/2026
- Corrigido o catálogo para gravar os nomes simbólicos de `nls.keys.json`, conforme o carregador distribuído com o Devin. O catálogo numérico anterior era ignorado e produzia um cache em inglês; limpar o cache sozinho não resolvia.
- O instalador compara a revisão do conteúdo da tradução, além da versão do aplicativo e do locale, para atualizar instalações que ainda tenham o catálogo incompatível.
- O diálogo Sobre usa os campos específicos do Devin e mostra `Tradução PT-BR: Emerson Teles` uma única vez, preservando a ordem correta de versões, commit e data.
- A tradução dos textos embutidos usa o tokenizer Acorn, cobre os recursos JSON e templates, e preserva as chaves dos objetos, comentários e expressões regulares. Adicionados rótulos da tela inicial, incluindo espaços, sessões, automações e configurações da nuvem.
- Instalador e restaurador renovam o cache NLS com cópia de segurança. Ambos permitem execução sem perguntas pelo parâmetro `-NoPrompt`.
- O teste com o código real do carregador confirmou 20.267/21.220 mensagens diferentes do inglês (95,5%), incluindo menus e crédito; o catálogo anterior falhou no mesmo teste.

### Correção do cache de idioma — Devin Desktop 1.126.0 — 14/10/2026
- O instalador e o restaurador agora renovam também o cache NLS (`AppData\Roaming\Devin\clp`), que podia manter mensagens em inglês e ocultar traduções já presentes no pacote, inclusive o crédito no diálogo Sobre.
- O cache anterior é preservado com sufixo de data e hora antes de ser renovado.

### Codificação do instalador Devin — 13/10/2026
- Corrigido o `core/instalar.ps1`, salvo sem BOM: o Windows PowerShell lia as mensagens UTF-8 como ANSI e corrompia acentos no console. Agora o arquivo usa BOM UTF-8, como os demais scripts PowerShell.
- Mantidos os lançadores sem chcp 65001; o código de página do CMD não é alterado.



### Auditoria PT-BR — Devin Desktop 1.126.0 — 13/10/2026
- A revisão da interface encontrou os rótulos “Explain and Fix Problem” e “Explain and Fix” e adicionou “Explicar e corrigir o problema” e “Explicar e corrigir”.
- Corrigido o construtor para reutilizar traduções indexadas de `main.i18n.json`, gerar o catálogo no formato numérico do VS Code e exigir uma base da mesma versão do Devin. O instalador usa a base PT-BR 1.126.0 incluída no projeto; versões diferentes são interrompidas com aviso de incompatibilidade.
- Pacote temporário auditado contra a instalação 1.126.0: 20.276/21.220 mensagens NLS cobertas (95,6%); 944 lacunas restantes incluem textos técnicos e de acessibilidade. Nenhuma alteração foi aplicada ao Devin instalado.


### Correções do instalador — 13/10/2026
- Recuperado `core/instalar.ps1`, que tinha aspas e literais removidos e não podia ser interpretado pelo PowerShell. A restauração não foi alterada.
- O pacote de idioma agora usa os metadados NLS da instalação detectada, inclusive quando o Devin está em outra unidade.
- Em falhas, o CMD permanece aberto para leitura. Nenhuma nova string de interface foi adicionada nesta correção.
- A sintaxe PowerShell foi validada; a instalação no aplicativo real ainda não foi executada nesta revisão. O restaurador não foi alterado.

## Em desenvolvimento — Devin Desktop 1.126.0 / mecanismo 3.10.48 (13/10/2026)

### Correção da busca de instalações — 13/10/2026
- Instalador e restaurador validam primeiro caminhos do processo, registro e locais conhecidos; só quando nenhum candidato válido contém Devin.exe e `resources\app\package.json` iniciam a busca profunda em unidades fixas e removíveis. A busca ignora pastas raiz do sistema e junctions, deduplica caminhos, mantém instalações distintas selecionáveis e não usa a barra sobreposta do PowerShell. Mantenha `Find-Installations.ps1` ao lado dos scripts.
- A busca mostra a unidade atual, o número de pastas verificadas e as candidatas encontradas; não segue junctions/reparse points para evitar ciclos. Por cobrir todo o volume, pode levar mais tempo em discos grandes ou externos.
- Esta correção altera apenas a localização: 0 novas strings de interface foram adicionadas nesta etapa.

### Busca em camadas sem barra sobreposta — 13/10/2026
- O instalador e o restaurador validam primeiro caminhos obtidos do processo, registro e locais conhecidos. Só se nenhum contiver `Devin.exe` e `resources\app\package.json` fazem busca profunda em unidades fixas/removíveis.
- A busca profunda ignora pastas de sistema na raiz e junctions, valida o executável junto com `resources\app\package.json`, deduplica caminhos e mantém instalações distintas selecionáveis. O progresso aparece no título da janela; a barra `Write-Progress` foi removida.
- Esta melhoria altera a busca, não a interface: 0 novas strings.

- Busca automática ampliada para localizar `Devin.exe` recursivamente em todas as unidades montadas, incluindo discos externos; caminhos repetidos são removidos após validação do executável e do pacote.
- Instalador e restaurador normalizam os caminhos encontrados antes da seleção, removendo duplicatas da mesma pasta e preservando opções para instalações em diretórios diferentes.
- Instalador e restaurador procuram `Devin.exe` recursivamente em todas as unidades montadas, além da instalação ativa, locais conhecidos e registro do Windows. Validam `resources\app\package.json`; múltiplas cópias pedem seleção explícita e, sem candidato válido, aceitam caminho manual.
- A restauração usa o backup da versão detectada da instalação selecionada e mantém as verificações de arquivos/configuração e remoção do pacote de idioma.
- Conferidos os rótulos mostrados nos prints anteriores (contexto, conversas, diagnósticos, uso do plano, cotas e saldo): eles já constam em `embedded-ui.json`; 0 traduções novas foram adicionadas nesta rodada para esses textos.
- Revisada a acentuação das mensagens dos scripts; não foi encontrada mensagem visível sem acento que precisasse de correção nesta rodada (0 textos alterados, 0 novas strings).
- Auditado o catálogo da versão 1.126.0: 20.229/21.220 chaves antes desta rodada (95,3%), com 991 itens sem tradução direta. Foram adicionadas 51 traduções ao catálogo-fonte para as áreas de navegação, alternância Agente/Editor, sessões, barra lateral e atualizações; 45 aumentam a cobertura textual e 6 preservam grafias que já são iguais em português ou nomes próprios. No pacote gerado para o mecanismo 1.126.0, a cobertura ficou em 20.274/21.220 (95,5%), com 946 itens sem tradução direta.
- As 946 entradas restantes incluem mensagens de acessibilidade, diagnósticos, placeholders e conteúdo técnico, além de rótulos; a contagem não deve ser interpretada como 946 textos de interface ainda em inglês.

## Ajustes de cobertura - 2026-10-11
- O instalador atualiza os checksums dos bundles traduzidos em `product.json`; o backup original é preservado e restaurado junto aos bundles.
- O instalador agora identifica em qual etapa ocorreu uma falha para facilitar o diagnóstico.
- O restaurador reconhece quando o pacote PT-BR já foi removido e a configuração e os bundles já correspondem aos backups originais; nesse caso informa que o Devin já está no idioma original sem repetir a restauração.
- Corrigida a detecção de uma instalação PT-BR já ativa para que novas execuções não reinstalem o pacote sem necessidade.
- O restaurador compara a configuração e os arquivos com os backups e informa quando o Devin já está no idioma original.

## Correções do instalador - 2026-10-10
- Corrigido o empacotamento para preencher chaves NLS ausentes no pacote-base usando as mensagens da versão instalada do Devin.
- Corrigida a ativação do idioma para assegurar o arquivo de registro de pacotes de idioma e renovar os caches após instalar e configurar o pacote.
- Garantido o encerramento completo dos processos do Devin antes da troca de idioma; a abertura opcional agora inicia explicitamente com `--locale=pt-br`.
- Corrigidas chaves de tradução próprias do Devin que não correspondiam aos identificadores NLS e ampliada a cobertura de menus, comandos, sessões na nuvem e mensagens de interface.
- Textos fixos fora do catálogo de idioma são traduzidos em bundles específicos com backup original por versão.
- Mantidos o console sem `chcp 65001` e o empacotamento por .NET, sem a interface de progresso do `Compress-Archive`.

## [1.0.0] - 2026-10-10

### Lançamento inicial
- Pacote PT-BR adaptado ao Devin Desktop 1.126.0, baseado no pacote oficial Português (Brasil) do VS Code.
- Complementadas traduções dos módulos próprios do Devin/Windsurf, incluindo boas-vindas, configurações, SSH para agentes remotos e comandos da interface.
- Incluído o crédito “Tradução PT-BR: Emerson Teles” no diálogo Sobre somente no catálogo português do Brasil.
- Criados instalador e restaurador inteligentes, com detecção do estado, backup original por versão que não substitui cópias existentes, instalação no perfil do usuário e abertura opcional do Devin com a tecla S.
- O catálogo de idioma é instalado no perfil do usuário; textos fixos do aplicativo são alterados com cópias originais preservadas para restauração.
- Corrigida a exibição de acentos nos scripts do Windows PowerShell: arquivos `.ps1` salvos em UTF-8 com BOM, sem alterar a página de código do console.
- Adicionada renovação reversível dos caches do Electron após a alteração do idioma, renomeando os diretórios antigos para que o Devin crie caches novos na inicialização.
# Correções do instalador — 13/10/2026
- Reconstruído `core/instalar.ps1`, que tinha aspas e literais removidos e não podia ser interpretado pelo PowerShell. A restauração não foi alterada.
- Corrigido o lançamento do Devin em instalações fora do caminho padrão: os metadados NLS do pacote agora são lidos da pasta da versão encontrada, em qualquer unidade.
- Em falhas, o instalador mostra a etapa e o erro; o arquivo `.bat` mantém o CMD aberto para leitura. Nenhuma nova string de interface do Devin foi adicionada nesta correção.

