# Contribuindo

Este repositório é a **fonte da verdade** da configuração compartilhada do Copilot da equipe Tasy.

## Regras

- Edite os arquivos diretamente em `.github/` (agents, skills, instructions) e abra PR.
- **Nunca** commite segredos (PATs, senhas). O `mcp.json` real é ignorado pelo `.gitignore`; use apenas `mcp.json.example` com placeholders.
- **Não** regenere o repo a partir de um `~/.copilot` pessoal — isso sobrescreve o trabalho dos outros. O script `scripts/package-customizations.ps1` serve apenas ao seed inicial.
- Mantenha caminhos relativos ao repo (`.github/...`), nunca caminhos absolutos de usuário.
- Não inclua identidade pessoal fixa; refira-se sempre ao "usuário atual".

## Uso

Clone o repo e adicione-o como pasta no seu workspace do VS Code (multi-root), junto dos repositórios do Tasy. As customizações são descobertas automaticamente.