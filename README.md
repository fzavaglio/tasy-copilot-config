# Tasy Copilot Config

Configuração compartilhada do GitHub Copilot para a equipe Tasy: o agente **Tasy HTML5 Developer**, suas skills de módulo, arquivos de referência técnica e as instruções de workflow.

Este repositório é a **fonte da verdade** da configuração. Foi portabilizado (sem caminhos absolutos de usuário, sem identidade fixa e sem segredos) para poder ser clonado e evoluído pela equipe.

## Estrutura

```
.github/
  agents/
    Tasy HTML5 Developer.agent.md      # o agente
    tasy-html5-developer/              # arquivos de referência (lazy-loaded pelo agente)
  instructions/
    tasy-workflow.instructions.md      # convenções de commit/PR/documentação (applyTo **)
  skills/                              # conhecimento de domínio (auto-descoberto por descrição)
    corcpa/ corcre/ corctb/ corfin/
    corman-f1/ corman-go/ corman-os/ fatact/
    tasy-playwright/ azure-devops/ oracle/
mcp.json.example                       # template dos MCP servers (SEM segredos)
scripts/package-customizations.ps1     # seed inicial a partir de ~/.copilot (uso pontual)
```

## Como usar

1. **Clone** este repositório. Pode ser em qualquer lugar — inclusive dentro da mesma pasta pai onde você já tem os repos do Tasy (`emr-tasy-backend`, `emr-tasy-frontend`, `emr-tasy-plsql`).
2. **Adicione esta pasta ao seu workspace do VS Code (multi-root)**: menu `File` > `Add Folder to Workspace...` e selecione a pasta `tasy-copilot-config`, junto dos repos do Tasy que você já tiver aberto. A partir do momento em que ela vira uma raiz (root) do workspace, o VS Code descobre automaticamente o agente, as skills e as instruções deste `.github/` — sem precisar mexer em nenhuma configuração (`settings.json`).

   > **Atenção:** apenas clonar o repositório dentro da mesma pasta onde você já tem os outros repositórios (por exemplo, como subpasta de uma pasta pai que você abre como single-root) **não é suficiente**. O VS Code só descobre customizações (`.github/agents`, `.github/instructions`, `.github/skills`) em pastas que são raiz explícita do workspace — ele não varre subpastas arbitrárias procurando por `.github`. É sempre necessário usar `Add Folder to Workspace` apontando diretamente para esta pasta, esteja ela aninhada dentro de outra pasta ou não.

   > **Dica:** se quiser que essa combinação de pastas seja lembrada entre sessões, salve o workspace localmente como um arquivo `.code-workspace` (`File` > `Save Workspace As...`) — isso é pessoal, não precisa (nem deve) ser commitado no repositório, já que os caminhos das pastas variam de máquina para máquina.
3. **Configure os MCP servers**: copie `mcp.json.example` para o seu `~/.copilot/mcp.json` e defina as variáveis de ambiente (PATs e senhas Oracle). Nunca commite valores reais.
4. O MCP do **Playwright** (usado pela skill `tasy-playwright`) é configurado à parte, fora deste template.
5. Selecione o agente **Tasy HTML5 Developer** no Copilot Chat.

## Variáveis de ambiente (MCP)

| Variável | Descrição |
|---|---|
| `TASY_AZURE_DEVOPS_PAT` | PAT pessoal do Azure DevOps |
| `AZURE_DEVOPS_USER` | Usuário do ADO |
| `AZURE_DEVOPS_AREA_PATH` | Area path do ADO |
| `TASY_GITHUB_PAT` | PAT pessoal do GitHub |
| `ORACLE_PASSWORD_FINANCIAL` | Senha do schema Oracle (base Financial) |
| `ORACLE_PASSWORD_DEV` | Senha do schema Oracle (base Dev) |
| `HTTP_PROXY` / `HTTPS_PROXY` | Proxy corporativo, se aplicável |

## Contribuindo

Veja o `CONTRIBUTING.md`. Em resumo: edite os arquivos em `.github/` e abra PR. Nunca commite segredos. Não regenere o repo a partir de um `~/.copilot` pessoal.