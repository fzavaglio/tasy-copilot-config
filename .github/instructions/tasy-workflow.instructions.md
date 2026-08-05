---
applyTo: "**"
---

## Escolha de Palavras (aplica-se a toda documentaÃ§Ã£o escrita: comments de card, closure, release notes, descriÃ§Ãµes de PR, etc.)

Ao redigir qualquer documentaÃ§Ã£o (nÃ£o apenas os comments do card ADO), preferir a terminologia de negÃ³cio/usuÃ¡rio final e a convenÃ§Ã£o do Tasy em vez de jargÃ£o tÃ©cnico de implementaÃ§Ã£o. Trazer elementos tÃ©cnicos apenas quando **explicitamente solicitado** ou quando forem estritamente necessÃ¡rios para explicar a causa/correÃ§Ã£o.

- Usar a terminologia de convenÃ§Ã£o do Tasy em vez de nomes tÃ©cnicos de estrutura interna. Exemplo: um item de menu de contexto Ã© uma **"opÃ§Ã£o de mouse"** â€” evitar "item de menu de contexto", "menu" ou citar o nÃºmero do `MENUITEM`.
- **NÃ£o citar artefatos de implementaÃ§Ã£o** que nÃ£o ajudam a entender a causa/correÃ§Ã£o em si: nomes de arquivos criados, nomes de mÃ©todos/controllers criados, enums de backend criados para expor consultas, classes internas. Descrever a mudanÃ§a em termos de comportamento (ex: "a correÃ§Ã£o migrou o state da opÃ§Ã£o de mouse para o fonte") em vez de listar os nomes dos artefatos criados.
- Valores/campos de regra de negÃ³cio (ex: `IE_ORIGEM = 'M'`, `IE_SITUACAO = 'A'`) podem ser citados normalmente â€” sÃ£o regras de domÃ­nio, nÃ£o identificadores de implementaÃ§Ã£o.
- Evitar qualificadores tÃ©cnicos desnecessÃ¡rios (ex: "regra estÃ¡tica do schematics" â†’ "regra do schematics").
- Evitar arqueologia histÃ³rica de implementaÃ§Ã£o (nÂº de OS de conversÃ£o, datas de commit, nomes de campos internos de framework legado) quando nÃ£o for o foco especÃ­fico da questÃ£o/seÃ§Ã£o sendo preenchida.

### GlossÃ¡rio de ConvenÃ§Ã£o Tasy

Termos que possuem um significado especÃ­fico dentro da convenÃ§Ã£o do sistema Tasy. Usar o termo de convenÃ§Ã£o (coluna "Termo") em qualquer documentaÃ§Ã£o, e ter em mente o significado real (coluna "Significado") ao interpretar informaÃ§Ãµes do usuÃ¡rio ou do cÃ³digo â€” evitando ambiguidade, principalmente com "Java" e "Tela".

| Termo | Significado na convenÃ§Ã£o Tasy |
|---|---|
| **OpÃ§Ã£o de mouse** | Item de menu de contexto (menu que abre ao clicar com o botÃ£o direito). Preferir este termo a "item de menu", "menu" ou `MENUITEM`. |
| **Java** | Quase sempre uma referÃªncia Ã  **plataforma Java Swing** (cliente desktop legado), nÃ£o ao backend Java do HTML5. Confirmar o contexto antes de assumir que se trata do backend. |
| **Tela** | Geralmente corresponde a um `WCBPanel` ou `WCPanel` no frontend HTML5. |
| **ParÃ¢metro** | Sem outra especificaÃ§Ã£o, refere-se a um **parÃ¢metro da funÃ§Ã£o** (nÃ£o a parÃ¢metro de sistema ou de ambiente). |
| **SanduÃ­che** | BotÃ£o no HTML5 (Ã­cone de "hambÃºrguer") usado para abrir chamadas externas a outras funÃ§Ãµes. |
| **Chamada externa** | AÃ§Ã£o de abrir outra funÃ§Ã£o a partir de dentro da funÃ§Ã£o atual. |
| **LocalizaÃ§Ã£o / Localidade** | Cadastro nas propriedades do usuÃ¡rio que indica o paÃ­s/regiÃ£o de atuaÃ§Ã£o (Brasil, ColÃ´mbia, MÃ©xico, ...). |
| **Schematics** | ReferÃªncia ao framework interno de configuraÃ§Ã£o de telas, seja o **Schematics Legado** (tabelas Oracle) ou o **Schematics DX** (JSON no backend). SÃ£o a mesma coisa conceitualmente, apenas com mudanÃ§a do local de armazenamento (banco â†’ backend). |
| **DicionÃ¡rio de Dados** | FunÃ§Ã£o Tasy que cadastra funÃ§Ãµes, parÃ¢metros, visÃµes, tabelas, etc. |
| **DicionÃ¡rio de Objetos** | FunÃ§Ã£o Tasy que contÃ©m a estrutura do schematics (`DIC_OBJETO` e tabelas relacionadas). |
| **Shift F11** | Atalho tradicional para a funÃ§Ã£o "Cadastros Gerais" â€” tambÃ©m pode ser referenciada apenas como "Cadastro". |
| **Modo grid** | Modo de lista/grade de um WDBPanel (vÃ¡rias linhas). Usar sempre **"modo grid"**, nunca "modo grade". |
| **readOnly** | Estado somente-leitura de um campo ou painel. Usar sempre **"readOnly"**, nunca "somente-leitura" ou "somente leitura". |

---

## PadrÃ£o de DocumentaÃ§Ã£o em Cards ADO

ApÃ³s implementar e testar uma correÃ§Ã£o de Bug, **sempre** registrar quatro comments no work item ADO, **nesta ordem**:

1. **Comment 1 â€” Template de defeito** (postado primeiro)
2. **Comment 2 â€” Release Notes** (postado segundo)
3. **Comment 3 â€” Closure/Resolution** (postado terceiro)
4. **Comment 4 â€” AlteraÃ§Ãµes Realizadas** (postado por Ãºltimo â€” aparece como primeira discussion no ADO, pois o ADO exibe os comentÃ¡rios do mais recente para o mais antigo). Lista os PRs abertos por repositÃ³rio e versÃ£o, e os nÃºmeros de release. Deve possuir tÃ­tulo "AlteraÃ§Ãµes Realizadas" para facilitar identificaÃ§Ã£o.

> **FORMATAÃ‡ÃƒO DOS COMENTÃRIOS ADO:** A ferramenta MCP de ADO nÃ£o renderiza Markdown â€” usar **sempre HTML** ao postar ou atualizar comentÃ¡rios. Regras obrigatÃ³rias:
> - Quebras de linha: `<br>` (nunca `\n` solto)
> - Negrito: `<b>texto</b>` (nunca `**texto**`)
> - ParÃ¡grafos: envolver o conteÃºdo em `<div>...</div>`
> - Caracteres especiais: `>` â†’ `&gt;`, `"` â†’ `&quot;`
> - Passar sempre `"format": "html"` na chamada da ferramenta
> - NÃ£o usar travessÃ£o (â€”) em meio a frases. Substituir por vÃ­rgula ou ponto conforme o contexto.

### Comment 1 â€” Template de defeito

Preencher o template abaixo e postar como primeiro comment no card. As informaÃ§Ãµes de PR e histÃ³rico devem ser obtidas via `git log` no repositÃ³rio alterado antes de postar.

> **⚠️ Exceção obrigatória para objetos PL/SQL:** quando o arquivo causador do defeito for um objeto PL/SQL (`emr-tasy-plsql/objects/**`), **nunca usar `git log`/GitHub para rastrear quando a alteração foi introduzida**. O histórico do GitHub não é a fonte confiável para esses objetos — usar **sempre** a tabela `tasy.OBJETO_SISTEMA_HIST` (base Dev), que registra cada revisão do objeto com autor, data (`DT_ATUALIZACAO`), OS (`NR_ORDEM_SERVICO`) e o código-fonte completo daquela revisão (`DS_SCRIPT_CRIACAO`). Ver processo completo (incluindo a técnica de busca binária sobre as revisões) em `plsql-workflow.md`.

**Como obter as informações via git (frontend/backend — não usar para objetos PL/SQL):**
```bash
# PR que introduziu o bug: buscar "Merge pull request" pelo identificador do work item ADO
# O padrÃ£o do repositÃ³rio usa o nÃºmero do ADO na branch (ex: US_605792 ou AB#711619)
git log --all --format="%h %s" | Select-String "Merge pull request.*<NR_ADO>|<NR_ADO>.*pull request"

# PR da correÃ§Ã£o atual: buscar pelo nÃºmero do card atual
git log --all --format="%h %s" | Select-String "Merge pull request.*<NR_CARD>|<NR_CARD>.*pull request"

# HistÃ³rico do arquivo alterado (para identificar quando o bug foi introduzido)
git log --format="%h %ai %s" -- <caminho/do/arquivo.prc>

# Branch atual
git branch --show-current

# Status dos arquivos alterados (confirmar o que foi modificado)
git status --short
```

**InstruÃ§Ãµes de preenchimento do template:**
- **QuestÃ£o 1:** Localizar o PR que introduziu o bug via `git log`. Com o PR em mÃ£os, verificar no GitHub se ele estava vinculado a uma User Story (Feature) ou a um Bug. Caso nÃ£o seja possÃ­vel determinar com certeza, questionar o usuÃ¡rio antes de preencher.
- **QuestÃ£o 2:** Descrever a localizaÃ§Ã£o no sistema como caminho de navegaÃ§Ã£o, sem informar cÃ³digo da funÃ§Ã£o. Exemplo: `Financeiro > Fluxo de Caixa > Caixa de Recebimento > BotÃ£o direito > Cancelar`.
- **QuestÃ£o 4:** Para arquivos PL/SQL, verificar via `tasy.OBJETO_SISTEMA_HIST` (base Dev) se houve alteraÃ§Ã£o recente (aproximadamente Ãºltimo ano) â€” nunca via `git log`/GitHub. Para os demais repositÃ³rios (frontend/backend), verificar via `git log` se houve alteraÃ§Ã£o recente (aproximadamente Ãºltimo ano) nos arquivos envolvidos. Se sim, identificar o PR causador, fazer uma breve descriÃ§Ã£o do que foi alterado e informar o link do PR como **URL crua em linha separada** (ex: `https://github.com/...`), nunca como markdown `[texto](url)`. Referenciar a OS/feature pelo padrÃ£o "OS XXXXXXX" (somente o nÃºmero, sem prefixo). AtenÃ§Ã£o: mensagens de commit do git frequentemente usam os prefixos `[SO-XXXXXXX]` ou `[OS-XXXXXXX]` â€” ambos identificam a mesma Ordem de ServiÃ§o. O prefixo `SO-` Ã© utilizado apenas em mensagens de commit (onde serve de referÃªncia para validaÃ§Ãµes do PR); na documentaÃ§Ã£o do card ADO, usar sempre apenas "OS XXXXXXX". Quando o commit referenciar `AB#XXXXXX`, trata-se de um card do Azure Boards (Bug, User Story, Feature ou Task) â€” nesse caso mencionar como "Card XXXXXX", nÃ£o como OS. Se nÃ£o houve alteraÃ§Ã£o recente, informar que nÃ£o. Em caso de dÃºvida sobre a janela de tempo, questionar o usuÃ¡rio. **Caso o arquivo seja um JSON do Schematics DX** (ex: `cormanos.json`) e o commit causador seja a criaÃ§Ã£o do arquivo (mensagem tipo `ConvertToDX`), **antes de apontar a feature de conversÃ£o DX como causa raiz, consultar o Schematics Legado no banco Oracle** para verificar se o registro problemÃ¡tico jÃ¡ existia lÃ¡ (ver seÃ§Ã£o "Schematics Legado â€” Root Cause" abaixo). Se o registro existia no Legado antes da conversÃ£o, a causa raiz Ã© o Legado (descrever o registro e a data de `dt_atualizacao` da tabela correspondente) e referenciar a feature de conversÃ£o apenas como o veÃ­culo que trouxe o problema para o DX. Se o registro nÃ£o existia no Legado, entÃ£o a causa raiz Ã© de fato a feature de conversÃ£o DX â€” informar o link https://dev.azure.com/emr-cm/EMR/_workitems/edit/570067. **NÃ£o mencionar o nome do usuÃ¡rio** que realizou a alteraÃ§Ã£o no Legado. **Caso o problema seja relacionado a alteraÃ§Ã£o de timezone**, a causa raiz Ã© a feature https://dev.azure.com/emr-cm/EMR/_workitems/edit/667577 â€” informar o link dessa feature na descriÃ§Ã£o da questÃ£o 4.
- **QuestÃ£o 5:** Fazer uma breve descriÃ§Ã£o do que foi corrigido e informar **apenas o link do PR da pre_main** como **URL crua em linha separada** (ex: `https://github.com/...`), nunca como markdown `[texto](url)`. NÃ£o listar todos os PRs de versÃ£o â€” somente o pre_main. Deve ser preenchido apÃ³s abertura do PR no GitHub. Enquanto nÃ£o houver PR, questionar o usuÃ¡rio para abertura do PR.
- **QuestÃ£o 6:** Informar a **data completa** (dia/mÃªs/ano) em que o problema foi introduzido. Para arquivos PL/SQL, obter essa data via `DT_ATUALIZACAO` do registro correspondente em `tasy.OBJETO_SISTEMA_HIST` (nunca via `git log`). Para os demais repositÃ³rios, obter via `git log --format="%ai %s"` no arquivo alterado. Informar tambÃ©m um breve motivo de por que nÃ£o havia sido identificado antes. Usar tom cauteloso quando nÃ£o for possÃ­vel afirmar com certeza (ex: "possivelmente nÃ£o foi executado nos testes" em vez de "nÃ£o era exercido nos testes"). NÃ£o incluir hash de commit. **Para arquivos Schematics DX**, usar `git log --diff-filter=A --format="%ai %s" -- <arquivo>` para obter a data de criaÃ§Ã£o do JSON. Se o registro problemÃ¡tico jÃ¡ existia no Schematics Legado (verificado via Oracle MCP), usar a `dt_atualizacao` do registro no Legado como data de referÃªncia de introduÃ§Ã£o do defeito, pois o problema existia antes da conversÃ£o DX.
- **QuestÃ£o 7:** Sempre preencher com "AnÃ¡lise, Testes exploratÃ³rios."
- **QuestÃ£o 8:** Marcar normalmente apenas uma opÃ§Ã£o â€” a mais comum Ã© "Funcionalidade" ou "Desempenho". Outras opÃ§Ãµes podem ser marcadas em casos excepcionais quando realmente se aplicarem. **Manter sempre todas as opÃ§Ãµes no template** â€” substituir `(  )` por `(X)` nas opÃ§Ãµes aplicÃ¡veis e manter as demais como `(  )`. Nunca remover as opÃ§Ãµes nÃ£o marcadas.
- **QuestÃ£o 9:** Verificar a versÃ£o do card ADO e listar ela mais todas as versÃµes superiores atÃ© a dev. Exemplo: card na versÃ£o 1838 â†’ `1838, 1842, 1845, 1848, dev`.

**Template:**

```
1 - Como o defeito foi inserido?
[ ] OrgÃ¢nico (Entrou quando a versÃ£o foi criada a partir da dev)
[ ] Versionado (Entrou forÃ§ado em versÃ£o jÃ¡ liberada no mercado)
     (  ) demanda legal
     (  ) customizaÃ§Ã£o
     (  ) bug
     Obs:

2 - Onde: IdentificaÃ§Ã£o da funcionalidade ou rotina onde o defeito ocorre
R:

3 - RazÃ£o: Por que o defeito ocorre?
R:

4 - Causa: Existe alguma alteraÃ§Ã£o no cÃ³digo fonte que causou o problema? Descreva o que causou o problema e adicione o Pull Request
R:

5 - CorreÃ§Ã£o: Descreva como foi corrigido o defeito e quais alteraÃ§Ãµes foram necessÃ¡rias e informe o Pull Request
R:

6 - Em qual versÃ£o o defeito foi gerado/introduzido? Se foi antes da Ãºltima versÃ£o disponibilizada, por que nÃ£o havia sido identificado atÃ© entÃ£o?
R:

7 - Medida preventiva: O que poderia ter feito para prevenir o problema?
R:

8 - Natureza do problema
(  ) Funcionalidade â€“ comportamento incorreto em relaÃ§Ã£o Ã  especificaÃ§Ã£o.
(  ) Interface / UI / UX â€“ problemas visuais, layout ou navegaÃ§Ã£o.
(  ) Desempenho â€“ lentidÃ£o, travamento, consumo excessivo.
(  ) SeguranÃ§a â€“ vulnerabilidades, falhas de autenticaÃ§Ã£o, exposiÃ§Ã£o de dados.
(  ) Compatibilidade â€“ problemas em navegadores, dispositivos ou versÃµes diferentes.
(  ) ValidaÃ§Ã£o / Dados â€“ erros de cÃ¡lculo, arredondamento, ou inconsistÃªncias de banco.
(  ) IntegraÃ§Ã£o â€“ falhas em comunicaÃ§Ã£o entre sistemas.
(  ) Usabilidade â€“ confusÃ£o de uso, mensagens pouco claras.
(  ) Infraestrutura / ConfiguraÃ§Ã£o â€“ ambiente, deploy, permissÃ£o, servidor, gestÃ£o da versÃ£o, bloqueios

9 - Em quais versÃµes as alteraÃ§Ãµes foram aplicadas?
R:
```

---

### Comment 2 â€” Release Notes

O Release Notes do card ADO possui dois campos de texto: **antes** (comportamento incorreto, no passado) e **depois** (comportamento corrigido, no presente). A funÃ§Ã£o impactada jÃ¡ Ã© informada automaticamente pelo sistema â€” nÃ£o incluir no texto.

**Regras de escrita:**
- Redigir em linguagem de usuÃ¡rio final, sem termos tÃ©cnicos (sem nomes de procedures, tabelas ou campos de banco).
- O campo **antes** deve descrever a situaÃ§Ã£o problemÃ¡tica que o usuÃ¡rio experimentava, no tempo passado.
- O campo **depois** deve descrever o comportamento correto apÃ³s a correÃ§Ã£o, no tempo presente, iniciando sempre com "Agora, o sistema...".
- Ser objetivo e conciso â€” uma ou duas frases por campo Ã© suficiente.
- O contexto de navegaÃ§Ã£o (menu, aba, botÃ£o) pode ser mencionado quando ajuda a situar o usuÃ¡rio, mas sem informar cÃ³digo de funÃ§Ã£o.

**Exemplo:**

*Antes:*
> No menu "CÃ³digo de barras", caso houvesse cadastro para obtenÃ§Ã£o do CNPJ raiz de um cÃ³digo de barras, e que no CNPJ informado no cÃ³digo houvesse a mesma raiz, mas com numeraÃ§Ã£o final diferente, o sistema nÃ£o vinculava o cÃ³digo de barras ao tÃ­tulo corretamente ao executar o processo via Job.

*Depois:*
> Agora, o sistema identifica o CNPJ raiz informado no cÃ³digo de barras e vincula os tÃ­tulos corretamente.

---

### Comment 3 â€” Closure/Resolution

Este comment Ã© a **Closure/Resolution** da discussion do card no ADO. Linguagem direta, com algum grau tÃ©cnico mas sem excessos. Dois parÃ¡grafos curtos:
1. Onde ocorria o problema, qual era o comportamento incorreto e o impacto observÃ¡vel (erro no console, dado incorreto, processo interrompido)
2. O que foi alterado para corrigir (objeto/arquivo, mudanÃ§a especÃ­fica) e qual o efeito da correÃ§Ã£o

> **RestriÃ§Ãµes obrigatÃ³rias:** NÃƒO incluir datas, nomes de usuÃ¡rios, nÃºmeros de PR ou links de PR no texto da Closure. Esses dados pertencem ao Comment 4 (AlteraÃ§Ãµes Realizadas). A Closure deve ser um texto narrativo de causa raiz e correÃ§Ã£o, sem referÃªncias a rastreabilidade de cÃ³digo.

> **NÃ£o incluir arqueologia histÃ³rica:** narrativa sobre quando/como o schematics legado foi convertido para DX (nÃºmero da OS de conversÃ£o, data do commit, nome de campos internos como `jsConditions`) pertence exclusivamente Ã  QuestÃ£o 4 do Comment 1 (Template de defeito), nÃ£o Ã  Closure. A Closure descreve apenas a causa atual e a correÃ§Ã£o aplicada â€” nÃ£o a histÃ³ria de como o defeito chegou atÃ© ali.

**NÃ­vel de detalhe esperado:**
- Mencionar a tela/evento/local no sistema onde o problema ocorria (ex: "evento onLoad da tela X", "processo de geraÃ§Ã£o de nota fiscal")
- Citar os campos/valores de negÃ³cio diretamente envolvidos na causa (ex: `ref.getValue('CD_CGC')`, `IE_ORIGEM = 'M'`) sem detalhar toda a cadeia de chamadas internas
- Descrever o sintoma observÃ¡vel (erro no console, dado sobrescrito, processo nÃ£o concluÃ­do)
- Na correÃ§Ã£o, indicar o que foi trocado/ajustado e o efeito resultante â€” sem listar nomes de queries, procedures auxiliares ou detalhes de implementaÃ§Ã£o interna

> **Escolha de palavras:** seguir a diretriz geral em "Escolha de Palavras" no topo deste arquivo â€” preferir termos de negÃ³cio/usuÃ¡rio final (ex: "opÃ§Ã£o de mouse") e citar artefatos de implementaÃ§Ã£o (arquivos, mÃ©todos, enums criados) apenas quando estritamente necessÃ¡rio.

**Exemplo de tom e tamanho esperado (frontend):**

> Verificado que o problema ocorria no evento onLoad da tela de Nota Fiscal. ApÃ³s o sistema consultar os dados da pessoa do tÃ­tulo e setar o campo `CD_CGC`, a linha subsequente verificava se o campo estava vazio utilizando `ref.getValue('CD_CGC')`. O mÃ©todo `getValue` retornava erro no console, impactando na finalizaÃ§Ã£o do processo e nÃ£o selecionando a forma de pagamento corretamente.
>
> A correÃ§Ã£o substituiu `ref.getValue('CD_CGC')` por `ref.get('CD_CGC')`, desta forma o processo segue sem erros e o sistema seleciona corretamente a informaÃ§Ã£o de forma de pagamento na nota fiscal.

**Exemplo de tom e tamanho esperado (PL/SQL):**

> Verificado que o erro ocorria pois a procedure `OBTER_TITULO_REGRA_BARRAS` tentava obter o CNPJ raiz via variÃ¡vel local que sÃ³ Ã© populada quando um parÃ¢metro especÃ­fico nÃ£o Ã© nulo. Como a JOB que dispara o processo sempre passa esse parÃ¢metro como null, a variÃ¡vel permanecia nula e o tÃ­tulo nunca era localizado.
>
> Realizado ajuste para obter o CNPJ raiz diretamente do parÃ¢metro de entrada, que sempre chega populado independente da origem da chamada. Com isso, o vÃ­nculo do boleto ao tÃ­tulo passa a funcionar corretamente tambÃ©m pela execuÃ§Ã£o via JOB.

**Exemplo de tom e tamanho esperado (schematics/opÃ§Ã£o de mouse â€” evitar citar artefatos de implementaÃ§Ã£o):**

> Verificado que o problema ocorria na opÃ§Ã£o de mouse "Cancelar nota de crÃ©dito" da funÃ§Ã£o Controle de Notas de CrÃ©dito a Pagar. O sistema fazia com que a condiÃ§Ã£o de exibiÃ§Ã£o dependesse exclusivamente da regra do schematics, que exigia `IE_ORIGEM = 'M'` (origem Manual). Com isso, a opÃ§Ã£o nÃ£o era exibida para notas de origens diferentes de Manual, independentemente do parÃ¢metro 17 (origens permitidas para cancelamento), e tambÃ©m nÃ£o avaliava a situaÃ§Ã£o da nota nem a existÃªncia de baixas.
>
> A correÃ§Ã£o foi migrar o state da opÃ§Ã£o de mouse para o fonte, que avalia o parÃ¢metro 17 para verificar se a origem da nota estÃ¡ entre as origens permitidas para cancelamento, alÃ©m de checar a situaÃ§Ã£o da nota (`IE_SITUACAO = 'A'`) e a ausÃªncia de baixas. Com isso, a opÃ§Ã£o de mouse passou a ser exibida corretamente para todas as origens configuradas no parÃ¢metro 17.

---

### Comment 4 â€” AlteraÃ§Ãµes Realizadas

Este comment Ã© postado por Ãºltimo e lista todos os PRs abertos por repositÃ³rio e versÃ£o, alÃ©m dos nÃºmeros de release de cada versÃ£o corrigida. Deve ter o tÃ­tulo "AlteraÃ§Ãµes Realizadas".

**Regras de preenchimento:**
- Listar apenas os repositÃ³rios que foram efetivamente alterados no card. Omitir seÃ§Ãµes de repositÃ³rios sem alteraÃ§Ã£o.
- Informar os links dos PRs como URLs cruas (sem markdown), um por linha, precedidos da versÃ£o correspondente.
- Labels de versÃ£o do frontend e backend incluem o prefixo completo (ex: `5.06.1848`); no PL/SQL usar apenas o nÃºmero (ex: `1848`).
- Na seÃ§Ã£o **RELEASES**, listar os nÃºmeros de release de cada versÃ£o corrigida, obtidos via consulta na tabela `AJUSTE_VERSAO` (base Dev). **O identificador do release Ã© sempre o `NR_SEQUENCIA` do registro** â€” nunca a coluna `NR_RELEASE` (que Ã© apenas um contador interno auxiliar e nÃ£o corresponde ao nÃºmero usado para aprovaÃ§Ã£o/rastreio do release). Listar todos os releases da versÃ£o (HTML5 e Java/Delphi) separados por vÃ­rgula em uma Ãºnica linha, sem identificar o tipo. O formato facilita cÃ³pia direta para aprovaÃ§Ã£o.
- Informar tambÃ©m o status do conjunto de releases de cada versÃ£o conforme a seguinte lÃ³gica:
  - `DT_LIBERACAO` nula â†’ "Criado"
  - `DT_LIBERACAO` preenchida e `IE_COMPILANDO = 'N'` â†’ "Liberado"
  - `IE_COMPILANDO = 'A'` â†’ "Aprovado"
- Se `NR_SERVICE_PACK` ou `NR_SERVICE_PACK_JAVA` jÃ¡ estiverem preenchidos, informar o nÃºmero do SP gerado.
- **Sempre consultar `AJUSTE_VERSAO` antes de postar o Comment 4** â€” nÃ£o deixar releases como "aguardando" se jÃ¡ foram criados.
- **Se a consulta nÃ£o retornar nenhum registro para o card**, omitir completamente a seÃ§Ã£o **RELEASES** do Comment 4. NÃ£o incluir a seÃ§Ã£o com texto como "aguardando criaÃ§Ã£o" ou similar.
- **Sempre consultar `log_data` (base Financial) antes de postar o Comment 4** â€” verificar se houve alteraÃ§Ãµes de dicionÃ¡rio vinculadas ao card. Se a query retornar resultados, incluir a seÃ§Ã£o **ALTERAÃ‡Ã•ES DE DICIONÃRIO** ao final do comment. Se nÃ£o retornar, omitir a seÃ§Ã£o completamente. Regra de schema (Dev Ã— Financial) e queries de `log_data` documentadas em `.github/agents/tasy-html5-developer/oracle-queries-log-data.md`.

**Como obter os releases do card (base Dev):**
```sql
SELECT
    nr_sequencia,
    cd_versao,
    nr_release,
    ie_compilando,
    nr_service_pack,
    nr_service_pack_java,
    nr_service_pack_delphi,
    dt_liberacao,
    dt_liberacao_service_pack
FROM tasy.AJUSTE_VERSAO
WHERE nr_work_item = <NR_CARD_ADO>
ORDER BY cd_versao, nr_sequencia;
```
> **ATENÃ‡ÃƒO:** o valor a ser usado no comment Ã© sempre o `NR_SEQUENCIA` de cada linha retornada â€” nÃ£o o `NR_RELEASE`. A coluna `nr_release` foi incluÃ­da na consulta apenas como referÃªncia interna, nÃ£o para uso na documentaÃ§Ã£o.
- Prefixo `5.xx.YYYY` no `CD_VERSAO` â†’ release **HTML5**
- Prefixo `4.xx.YYYY` no `CD_VERSAO` â†’ release **Java/Delphi** da mesma versÃ£o numÃ©rica `YYYY`
- **NÃ£o existe release para a branch DEV** â€” somente versÃµes de mercado possuem releases.

**Estrutura do comment:**

```
AlteraÃ§Ãµes realizadas:

Frontend:
5.06.1848:
https://github.com/.../pull/XXXX

5.04.1845:
https://github.com/.../pull/XXXX


Backend:
5.06.1848:
https://github.com/.../pull/XXXX

5.04.1845:
https://github.com/.../pull/XXXX


PL/SQL:
1848:
https://github.com/.../pull/XXXX

1845:
https://github.com/.../pull/XXXX


RELEASES:
1848: <NR_SEQUENCIA_1>, <NR_SEQUENCIA_2> (Liberado)
1845: <NR_SEQUENCIA_1>, <NR_SEQUENCIA_2> (Liberado)


ALTERAÃ‡Ã•ES DE DICIONÃRIO:
<TABELA> (<PK>):
  <CAMPO>: '<valor_anterior>' -> '<valor_final>'
```

> A seÃ§Ã£o **ALTERAÃ‡Ã•ES DE DICIONÃRIO** sÃ³ deve ser incluÃ­da quando a consulta ao `log_data` retornar resultados. Omitir completamente quando nÃ£o houver alteraÃ§Ãµes de dicionÃ¡rio registradas para o card. Usar a query de estado final documentada em `.github/agents/tasy-html5-developer/oracle-queries-log-data.md` para obter as informaÃ§Ãµes.

---

## Schematics Legado â€” Root Cause

Quando um bug envolve uma configuraÃ§Ã£o incorreta no Schematics DX (legenda, campo, layout) e o commit causador Ã© a criaÃ§Ã£o do arquivo JSON (mensagem tipo `ConvertToDX` ou `chore(corXxxFY): Convert function`), **antes de apontar a feature de conversÃ£o DX como causa raiz, consultar o Schematics Legado no banco Oracle** para verificar se o registro problemÃ¡tico jÃ¡ existia lÃ¡.

**Como verificar:**
```sql
-- Legenda e data de Ãºltima alteraÃ§Ã£o
SELECT nr_sequencia, ds_legenda, dt_atualizacao
FROM tasy_legenda WHERE nr_sequencia = <nr_seq_legenda>;

-- Itens de cor e datas
SELECT nr_sequencia, ds_item, dt_atualizacao
FROM tasy_padrao_cor WHERE nr_seq_legenda = <nr_seq_legenda>;

-- VÃ­nculo com o painel
SELECT nr_seq_objeto, ie_forma_apres, ie_situacao
FROM objeto_schematic_legenda WHERE nr_seq_legenda = <nr_seq_legenda>;
```

Se o registro existir no Legado com `dt_atualizacao` anterior Ã  conversÃ£o DX:
- A causa raiz Ã© o Legado â€” descrever o registro e a data da `dt_atualizacao`
- **NÃ£o mencionar o nome do usuÃ¡rio** que realizou a alteraÃ§Ã£o no Legado
- Referenciar a feature de conversÃ£o DX https://dev.azure.com/emr-cm/EMR/_workitems/edit/570067 apenas como o veÃ­culo que trouxe o problema para o DX

### Processo de alteraÃ§Ã£o do Schematics Legado

O Schematics Legado reside nas tabelas Oracle (`TASY_LEGENDA`, `TASY_PADRAO_COR`, `REGRA_CONDICAO`, `REGRA_CONDICAO_ITEM`, `OBJETO_SCHEMATIC_LEGENDA`, etc.).

**NÃƒO Ã© possÃ­vel alterar essas tabelas diretamente via SQL em banco local.** O trigger `BL$<TABELA>` bloqueia qualquer DML com:
```
ORA-20001: Base tables can't be updated on local databases.
```

**Fluxo correto para alterar o Legado:**
1. Setar o contexto de usuÃ¡rio e OS (para rastreabilidade â€” os comandos abaixo servem como referÃªncia, a execuÃ§Ã£o real acontece via interface):
   ```sql
   BEGIN
       wheb_usuario_pck.set_nm_usuario('<nm_usuario>');
       tasy_dict_integration_pck.set_so(<nr_card_ado>);
   END;
   ```
2. **Fazer as alteraÃ§Ãµes pela interface do Tasy** (Schematics Builder ou funÃ§Ã£o correspondente). O framework executa internamente com o flag `g_updating_base_table = true` via `tasy_dict_integration_pck`, bypassing o trigger. As alteraÃ§Ãµes sÃ£o gravadas na tabela `LOG_DATA`.
3. Na funÃ§Ã£o **"ManutenÃ§Ã£o do DicionÃ¡rio"** do Tasy, enviar o logset para a base DEV.
4. Na base DEV, integrar as alteraÃ§Ãµes â€” esse Ã© o "commit" no Schematics Legado.

**Packages envolvidos:**
- `wheb_usuario_pck.set_nm_usuario(nm_usuario)` â€” define o usuÃ¡rio da sessÃ£o
- `tasy_dict_integration_pck.set_so(nr_so)` â€” define o nÃºmero do card vinculado Ã s alteraÃ§Ãµes (**OBRIGATÃ“RIO SER O NUMERO DO CARD ADO**)

**Hierarquia de FK para DELETE de legenda (ordem correta):**
1. `REGRA_CONDICAO_ITEM` (WHERE nr_seq_regra IN (...))
2. `REGRA_CONDICAO` (WHERE nr_sequencia IN (...))
3. `TASY_PADRAO_COR` (WHERE nr_sequencia IN (...))
4. `OBJETO_SCHEMATIC_LEGENDA` (WHERE nr_seq_legenda = X AND nr_seq_objeto = Y)
5. `TASY_LEGENDA` (WHERE nr_sequencia = X)

---

## Processo de Commit e Versionamento

### VersÃµes ativas

O sistema Tasy possui mÃºltiplas versÃµes com polÃ­tica de manutenÃ§Ã£o ativa. As versÃµes atualmente conhecidas sÃ£o:

| Branch | VersÃ£o |
|--------|--------|
| `pre_main` | desenvolvimento (prÃ³xima versÃ£o, ex: 5.07.1851) |
| `5.06.1848` | versÃ£o atual em mercado |
| `5.04.1845` | manutenÃ§Ã£o ativa |
| `5.03.1842` | manutenÃ§Ã£o ativa |
| `5.02.1838` | manutenÃ§Ã£o ativa |

### Branches de integraÃ§Ã£o

- **`pre_main`** â€” branch intermediÃ¡ria para desenvolvimento. Commits nÃ£o vÃ£o diretamente para `dev`; a `pre_main` atualiza a `dev` diariamente de forma automÃ¡tica.
- **`qa`** â€” branch paralela Ã  `pre_main`, usada para validaÃ§Ã£o de testes sistÃªmicos internos. Nem todo commit de `qa` vai para cliente â€” apenas os que passarem pela `pre_main`.
- **`dev`** â€” branch de desenvolvimento consolidada. NÃ£o recebe commits diretos.

> **Sempre questionar o usuÃ¡rio se Ã© necessÃ¡rio abrir PR para a `qa`.** Nem sempre Ã© necessÃ¡rio.

---

### Fluxo de commit (por repositÃ³rio)

O processo deve ser executado **separadamente para cada repositÃ³rio** (frontend, backend, PL/SQL). Para cada repositÃ³rio com alteraÃ§Ãµes, seguir os passos abaixo.

#### Passo 1 â€” Verificar estado da branch `pre_main`

```bash
git checkout pre_main
git status
```

A branch deve conter as alteraÃ§Ãµes realizadas.

> **AtenÃ§Ã£o (backend):** Podem existir dois arquivos modificados usados apenas para subir ambiente local que **nÃ£o devem ser incluÃ­dos no commit**:
> - `TasyAppServer/configuration.yml`
> - `TasyAppServer/context.xml`
>
> Se precisar trocar de branch e houver conflito nesses arquivos, fazer o stash **somente** desses dois arquivos:
> ```bash
> git stash push -- TasyAppServer/configuration.yml TasyAppServer/context.xml
> ```
> **NUNCA usar `git stash` sem path especÃ­fico** â€” isso stasha todos os arquivos modificados no repositÃ³rio, misturando com outros cards e poluindo o stash. Se houver outros arquivos modificados que nÃ£o devem ser commitados (ex: `ManutOrdemServicoAction.java` de outro card), descartÃ¡-los com `git checkout -- <arquivo>` antes de trocar de branch.

#### Passo 2 â€” Criar branch de trabalho

```bash
git checkout -b {NR_CARD}_{versao}
```

- **Nunca usar ponto** no nome da branch.
- PadrÃ£o: nÃºmero do card + versÃ£o resumida, separados por underline.
- Exemplos: `700920_premain`, `700920_1848`, `700920_1845`

#### Passo 3 â€” Adicionar apenas os arquivos alterados

```bash
git add caminho/do/arquivo.extensao
```

Adicionar somente os arquivos relevantes Ã  alteraÃ§Ã£o. Nunca usar `git add .` sem revisar o que estÃ¡ sendo incluÃ­do.

#### Passo 4 â€” Commit

```bash
git commit -n -m 'fix(modulo) DescriÃ§Ã£o resumida AB#{NR_CARD}'
```

- **NUNCA usar `git commit --amend`.** Se uma revisÃ£o de cÃ³digo exigir ajuste apÃ³s um commit jÃ¡ feito, criar um segundo commit na mesma branch. O PR ficarÃ¡ com mÃºltiplos commits, o que Ã© correto e rastreÃ¡vel.
- A flag `-n` ignora hooks de pre-commit.
- O mÃ³dulo deve ser o prefixo da funÃ§Ã£o alterada (ex: `corCreF1`, `corFinF2`, `corCpaF8`).
- **RepositÃ³rio PL/SQL (`emr-tasy-plsql`):** o mÃ³dulo nÃ£o Ã© tÃ£o evidente quanto no frontend/backend. Derivar pelo prefixo do nome do objeto alterado:
  - `man_` â†’ `tasyMan` (ManutenÃ§Ã£o Hospitalar)
  - `ctb_` â†’ `tasyCtb` (Contabilidade)
  - `fin_` â†’ `tasyFin` (Financeiro)
  - `cpa_` â†’ `tasyFin` (Contas a Pagar â€” usa `tasyFin` por convenÃ§Ã£o)
  - Demais casos (prefixo nÃ£o identifica Ã¡rea de negÃ³cio) â†’ `tasyFin` (padrÃ£o)
- A descriÃ§Ã£o deve ser curta e objetiva.
- O sufixo `AB#{NR_CARD}` vincula o commit ao work item no Azure DevOps.

Exemplos:
```bash
git commit -n -m 'fix(corCreF1) Ajuste abort valor negativo AB#700920'
git commit -n -m 'fix(corFinF2) CorreÃ§Ã£o cÃ¡lculo saldo diÃ¡rio AB#712345'
git commit -n -m 'fix(tasyFin) Aumenta ds_erro_w para evitar estouro de buffer AB#718040'
git commit -n -m 'fix(tasyMan) Ajuste em man_ordem_servico AB#700000'
```

#### Passo 5 â€” Push e abertura de PR

```bash
git push origin {NR_CARD}_{versao}
```

ApÃ³s o push, abrir Pull Request para a branch de destino (`pre_main`, `qa` ou versÃ£o), preenchendo o template abaixo e adicionando a **label** correspondente Ã  branch de destino:

- `pre_main` â†’ label `pre_main`
- `5.06.1848` â†’ label `5.06.1848`
- `5.04.1845` â†’ label `5.04.1845`
- etc.

> **RepositÃ³rio PL/SQL:** as labels de versÃ£o nÃ£o possuem prefixo â€” usar apenas o nÃºmero da versÃ£o (`1848`, `1845`, `1842`, `1838`). A label `pre_main` permanece igual em todos os repositÃ³rios.

**Adicionando labels via GitHub CLI (`gh`):**

O MCP do GitHub nÃ£o suporta adiÃ§Ã£o de labels. Usar o `gh` CLI (instalado em `C:\Program Files\GitHub CLI`):

```bash
# Adicionar label em um PR
gh pr edit {NR_PR} --repo philips-internal/{repositorio} --add-label "{label}"

# Exemplo
gh pr edit 109921 --repo philips-internal/emr-tasy-backend --add-label "pre_main"
```

Para usar o `gh` numa sessÃ£o PowerShell nova, incluir o PATH antes:
```powershell
$env:Path += ";C:\Program Files\GitHub CLI"
```

**Label `KEEP_OPEN`:** versÃµes que estÃ£o em perÃ­odo de verificaÃ§Ã£o (aguardando aprovaÃ§Ã£o para merge) devem receber a label `KEEP_OPEN` alÃ©m da label de versÃ£o. Aplicar nos PRs de frontend e backend dessas versÃµes para sinalizar que nÃ£o devem ser mergeados ainda. Atualmente a versÃ£o em verificaÃ§Ã£o Ã© a 1848.

```bash
gh pr edit {NR_PR} --repo philips-internal/{repositorio} --add-label "KEEP_OPEN"
```

```
### Tasy HTML5 
##### Pull request information

###### Quality Checks
- What is the feature or problem that this PR address?
<descrever o problema ou funcionalidade>

- What has been done in the source code to address this?
<descrever o que foi alterado no cÃ³digo>

- How did you test it?
<forma de teste: "Tested in system", "attached video", etc.>

- Any other relevant information to reviewer?
no

- Changed PL/SQL Objects:
<listar objetos PL/SQL alterados, ou "no">

- Backend/Frontend/tasy-plsql-objects PR Link:
<links dos PRs dos outros repositÃ³rios envolvidos na mesma alteraÃ§Ã£o, ou "no" se apenas um repositÃ³rio foi alterado>




#### Tasy HTML5 - Definition of Done (DoD) - Reviewer checklist
##### As a reviewer I have checked _all_ the items mentioned below:

- [ ] All the gated checks are passing 
- [ ] The code has been reviewed observing the business requirements and best practices
- [ ] The code has propper code abstraction
- [ ] No micro code duplication has been found in this pull request
- [ ] Any By-pass for this PR? If Yes, please provide the details here - Failure and Rationale
```

> **"Backend/Frontend/tasy-plsql-objects PR Link":** informar apenas quando houver PRs em outros repositÃ³rios envolvidos na mesma alteraÃ§Ã£o. Regra: no PR de cada repositÃ³rio, listar os links dos PRs dos demais repositÃ³rios alterados. Exemplo: se foram abertos PRs de PL/SQL e Backend, no PR do Backend informar o link do PR de PL/SQL, e vice-versa. Se apenas um repositÃ³rio foi alterado, preencher com `no`.

---

### Versionamento (cherry-pick para versÃµes anteriores)

ApÃ³s abrir o PR para `pre_main`, verificar no card ADO qual Ã© a versÃ£o do bug. A versÃ£o deve ser lida no **campo "VersÃ£o"** do work item no Azure DevOps â€” nÃ£o se basear pelo tÃ­tulo do card, pois pode nÃ£o refletir a versÃ£o correta. O commit deve ser aplicado na versÃ£o do card **e em todas as versÃµes superiores** atÃ© a `pre_main`.

**Exemplo:** card na versÃ£o `1842` â†’ commits em `5.03.1842`, `5.04.1845`, `5.06.1848` e `pre_main` (e `qa` se necessÃ¡rio).

> **PROIBIDO:** Nunca aplicar cherry-pick em versÃµes **inferiores** Ã  versÃ£o do card. A versÃ£o mÃ­nima Ã© sempre a versÃ£o lida no campo "VersÃ£o" do ADO. Exemplo: card na versÃ£o `1845` â†’ PRs apenas em `5.04.1845`, `5.06.1848` e `pre_main`. VersÃµes `1842` e `1838` **nÃ£o devem receber PR**.

> **OBRIGATÃ“RIO:** Nunca pular versÃµes intermediÃ¡rias **entre a versÃ£o do card e a `pre_main`**. Todas as versÃµes nesse intervalo devem receber o cherry-pick e ter PR aberto. A Ãºnica exceÃ§Ã£o permitida Ã© quando o arquivo alterado nÃ£o existe na versÃ£o de destino â€” situaÃ§Ã£o comum em arquivos JSON do **Schematics DX** quando a funÃ§Ã£o ainda nÃ£o foi convertida naquela versÃ£o.

**Como obter o hash do commit para o cherry-pick:**

```bash
git log --format="%h %s" -5
```

O hash Ã© o cÃ³digo curto (ex: `fa0f786c181`) exibido Ã  esquerda na linha do commit correspondente.
> **RepositÃ³rio PL/SQL (`emr-tasy-plsql`):** os nomes das **branches de versÃ£o** tambÃ©m nÃ£o possuem o prefixo `5.xx.` usado no frontend/backend â€” usar apenas o nÃºmero (`git checkout 1848`, nÃ£o `git checkout 5.06.1848`). Confirmar com `git branch -r | Select-String "<numero>"` antes de assumir o nome da branch.
Para cada versÃ£o, repetir o fluxo abaixo. O hash do commit deve ser o gerado no PR da `pre_main`.

```bash
git checkout 5.06.1848
git pull origin 5.06.1848
git checkout -b {NR_CARD}_{versao}
git cherry-pick {HASH_COMMIT}
git push origin {NR_CARD}_{versao}
```

Exemplos de nome de branch: `700920_1848`, `700920_1845`, `700920_1842`.

> **Conflitos ao trocar de branch:** pode ocorrer conflito com arquivos locais modificados (ex: `configuration.yml`, `context.xml` no backend) ao executar o `checkout`. Neste caso, fazer stash somente dos arquivos de configuraÃ§Ã£o local:
> ```bash
> git stash push -- TasyAppServer/configuration.yml TasyAppServer/context.xml
> ```
> ApÃ³s finalizar o versionamento de **todas** as versÃµes, voltar para a `pre_main` e executar `git stash pop` para restaurar apenas esses arquivos.
>
> Se houver outros arquivos locais modificados sem relaÃ§Ã£o com o card atual (arquivos de outro card, dependÃªncias temporÃ¡rias), descartÃ¡-los com `git checkout -- <arquivo>` ou `git clean -fd` **antes** do stash â€” para garantir que o `git stash pop` sÃ³ restaure `configuration.yml` e `context.xml`.

> **Conflitos no cherry-pick:** se o cherry-pick gerar conflitos em arquivos que estamos alterando (porque a versÃ£o de destino possui cÃ³digo diferente), **questionar o usuÃ¡rio antes de prosseguir**.

> Sempre abrir PR separado para cada versÃ£o.

#### PR de versÃ£o jÃ¡ possui commit anterior do mesmo card

Quando a branch de versÃ£o jÃ¡ tem um commit do card (ex: fix original) e Ã© necessÃ¡rio incluir um **ajuste complementar** vindo de um novo PR da `pre_main`, **nÃ£o usar `git reset --hard`**. Fazer o cherry-pick diretamente sobre o commit existente:

```bash
git checkout {NR_CARD}_{versao}
git cherry-pick {HASH_NOVO_COMMIT}
git push origin {NR_CARD}_{versao}
```

O cherry-pick Ã© aplicado sobre o estado pÃ³s-commit-antigo, que jÃ¡ corresponde ao contexto do novo commit â€” evitando conflitos. O PR ficarÃ¡ com **2 commits**, o que Ã© correto e rastreÃ¡vel.

Usar `git reset --hard` + cherry-pick apenas quando o commit antigo **nÃ£o deve constar** no histÃ³rico (estava errado e deve ser substituÃ­do). Nesse caso conflitos sÃ£o esperados pois o contexto da base diverge.

> **REGRA CRÃTICA â€” Um Ãºnico PR por card por versÃ£o:** Nunca abrir um segundo PR para a mesma versÃ£o e mesmo card. Se jÃ¡ existe um PR aberto (ex: `723247_1848` â†’ PR #109922), todos os commits complementares devem ser adicionados Ã  branch existente via cherry-pick â€” sem abrir nova branch ou novo PR. Isso vale mesmo quando o ajuste vem de uma contexto diferente (ex: correÃ§Ã£o de outro cenÃ¡rio do mesmo card). Antes de abrir qualquer PR de versÃ£o, verificar se jÃ¡ existe um PR aberto para aquela versÃ£o e card. SÃ³ abrir um segundo PR se o PR original jÃ¡ tiver sido mergeado.
