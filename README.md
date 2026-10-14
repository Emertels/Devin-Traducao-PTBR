# 🤖 Devin AI Desktop — Tradução para Português do Brasil (PT-BR) 🇧🇷

![Versão](https://img.shields.io/badge/Versão-v1.0.0-blue?style=for-the-badge)
![Idioma](https://img.shields.io/badge/Idioma-Português%20(Brasil)-green?style=for-the-badge)

Pacote portátil de localização oficial do **Devin Desktop (Devin AI)** para Português do Brasil (PT-BR), desenvolvido e preparado por **Emerson Teles**.

O pacote usa como base o pacote oficial Português (Brasil) da Microsoft para VS Code e adiciona as strings específicas e exclusivas do Devin/Windsurf (módulos de agente, editor, sessões em nuvem, alternâncias, SSH e painéis integrados).

---

## 📋 Sumário

1. [Apresentação & Cobertura](#-apresentação--cobertura)
2. [Download da Tradução](#-download-da-tradução)
3. [Instalação Passo a Passo](#-instalação-passo-a-passo)
4. [Como Restaurar o Original](#-como-restaurar-o-original)
5. [Créditos e Autoria](#-créditos-e-autoria)
6. [Licenças](#-licenças)

---

## 🌟 Apresentação & Cobertura

- **Versão Base:** Devin Desktop 1.126.0 (mecanismo 3.10.48).
- **Cobertura NLS:** Mais de **20.276 mensagens NLS traduzidas** diretamente (95,6% de cobertura), cobrindo menus, comandos, boas-vindas, configurações, atalhos, SSH e interface principal.
- **Detecção Inteligente:** O instalador detecta automaticamente a instalação do Devin, remonta o catálogo PT-BR compatível e ativa o locale nativo.
- **Totalmente Reversível:** Cria backup seguro e imutável dos arquivos originais antes de qualquer modificação.

---

## 📥 Download da Tradução

### [⬇️ Baixar Devin AI PT-BR v1.0.0 (ZIP Portátil)](https://github.com/Emertels/Devin-Traducao-PTBR/releases/download/v1.0.0/Devin-Traducao-PTBR-v1.0.0-Portable.zip)

---

## 🛠️ Instalação Passo a Passo

1. Baixe o pacote portátil `Devin-Traducao-PTBR-v1.0.0-Portable.zip` e extraia para qualquer pasta.
2. Execute **`Instalar-Traducao.bat`** com dois cliques.
3. O instalador detecta a versão do Devin, remonta o catálogo PT-BR para os índices NLS, salva a configuração original em `_backups/<versão>` e registra o pacote de idioma em Português.
4. Ao final da instalação, pressione **S** para abrir o Devin Desktop já em Português do Brasil!

---

## 🔄 Como Restaurar o Original

1. Execute **`Restaurar-Original.bat`**.
2. O restaurador desinstala o pacote PT-BR, recupera `argv.json` e restaura os bundles originais salvos no backup.
3. Pressione **S** para abrir o Devin no idioma padrão de fábrica.

---

## 👤 Créditos e Autoria

- **Localização e Tradução PT-BR:** **Emerson Teles** (crédito oficial visível na caixa Sobre do aplicativo).
- **Devin AI Desktop:** Cognition AI / Autores originais.

---

## 📄 Licenças

O catálogo base Português (Brasil) deriva do pacote oficial de localização do VS Code (Microsoft Corporation, licença MIT). Consulte `LICENSE-MICROSOFT.md` e `THIRD-PARTY-NOTICES.md` para mais informações sobre as licenças de terceiros.
