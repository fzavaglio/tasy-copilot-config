---
applyTo: "**"
---

## Escolha de Palavras (aplica-se a toda documentação escrita: comments de card, closure, release notes, descrições de PR, etc.)

Ao redigir qualquer documentação (não apenas os comments do card ADO), preferir a terminologia de negócio/usuário final e a convenção do Tasy em vez de jargão técnico de implementação. Trazer elementos técnicos apenas quando **explicitamente solicitado** ou quando forem estritamente necessários para explicar a causa/correção.

- Usar a terminologia de convenção do Tasy em vez de nomes técnicos de estrutura interna. Exemplo: um item de menu de contexto é uma **"opção de mouse"** — evitar "item de menu de contexto", "menu" ou citar o número do `MENUITEM`.
- **Não citar artefatos de implementação** que não ajudam a entender a causa/correção em si: nomes de arquivos criados, nomes de métodos/controllers criados, enums de backend criados para expor consultas, classes internas. Descrever a mudança em termos de comportamento (ex: "a correção migrou o state da opção de mouse para o fonte") em vez de listar os nomes dos artefatos criados.
- Valores/campos de regra de negócio (ex: `IE_ORIGEM = 'M'`, `IE_SITUACAO = 'A'`) podem ser citados normalmente — são regras de domínio, não identificadores de implementação.
- Evitar qualificadores técnicos desnecessários (ex: "regra estática do schematics" → "regra do schematics").
- Evitar arqueologia histórica de implementação (nº de OS de conversão, datas de commit, nomes de campos internos de framework legado) quando não for o foco específico da questão/seção sendo preenchida.

### Glossário de Convenção Tasy

Termos que possuem um significado específico dentro da convenção do sistema Tasy. Usar o termo de convenção (coluna "Termo") em qualquer documentação, e ter em mente o significado real (coluna "Significado") ao interpretar informações do usuário ou do código — evitando ambiguidade, principalmente com "Java" e "Tela".

| Termo | Significado na convenção Tasy |
|---|---|
| **Opção de mouse** | Item de menu de contexto (menu que abre ao clicar com o botão direito). Preferir este termo a "item de menu", "menu" ou `MENUITEM`. |
| **Java** | Quase sempre uma referência à **plataforma Java Swing** (cliente desktop legado), não ao backend Java do HTML5. Confirmar o contexto antes de assumir que se trata do backend. |
| **Tela** | Geralmente corresponde a um `WDBPanel` ou `WCPanel` no frontend HTML5. |
| **Parâmetro** | Sem outra especificação, refere-se a um **parâmetro da função** (não a parâmetro de sistema ou de ambiente). |
| **Sanduíche** | Botão no HTML5 (ícone de "hambúrguer") usado para abrir chamadas externas a outras funções. |
| **Chamada externa** | Ação de abrir outra função a partir de dentro da função atual. |
| **Localização / Localidade** | Cadastro nas propriedades do usuário que indica o país/região de atuação (Brasil, Colômbia, México, ...). |
| **Schematics** | Referência ao framework interno de configuração de telas, seja o **Schematics Legado** (tabelas Oracle) ou o **Schematics DX** (JSON no backend). São a mesma coisa conceitualmente, apenas com mudança do local de armazenamento (banco → backend). |
| **Dicionário de Dados** | Função Tasy que cadastra funções, parâmetros, visões, tabelas, etc. |
| **Dicionário de Objetos** | Função Tasy que contém a estrutura do schematics (`DIC_OBJETO` e tabelas relacionadas). |
| **Shift F11** | Atalho tradicional para a função "Cadastros Gerais" — também pode ser referenciada apenas como "Cadastro" ou "Regra". |
| **Modo grid** | Modo de lista/grade de um WDBPanel (várias linhas). Usar sempre **"modo grid"**, nunca "modo grade". |
| **readOnly** | Estado somente-leitura de um campo ou painel. Usar sempre **"readOnly"**, nunca "somente-leitura" ou "somente leitura". |

---

## Padrão de Documentação em Cards ADO

Após implementar e testar uma correção de Bug, **sempre** registrar quatro comments no work item ADO, **nesta ordem**:

1. **Comment 1 — Template de defeito** (postado primeiro)
2. **Comment 2 — Release Notes** (postado segundo)
3. **Comment 3 — Closure/Resolution** (postado terceiro)
4. **Comment 4 — Alterações Realizadas** (postado por último — aparece como primeira discussion no ADO, pois o ADO exibe os comentários do mais recente para o mais antigo). Lista os PRs abertos por repositório e versão, e os números de release. Deve possuir título "Alterações Realizadas" para facilitar identificação.

> **FORMATAÇÃO DOS COMENTÁRIOS ADO:** A ferramenta MCP de ADO não renderiza Markdown — usar **sempre HTML** ao postar ou atualizar comentários. Regras obrigatórias:
> - Quebras de linha: `<br>` (nunca `\n` solto)
> - Negrito: `<b>texto</b>` (nunca `**texto**`)
> - Parágrafos: envolver o conteúdo em `<div>...</div>`
> - Caracteres especiais: `>` → `&gt;`, `"` → `&quot;`
> - Passar sempre `"format": "html"` na chamada da ferramenta
> - Não usar travessão (—) em meio a frases. Substituir por vírgula ou ponto conforme o contexto.

### Comment 1 — Template de defeito

Preencher o template abaixo e postar como primeiro comment no card. As informações de PR e histórico devem ser obtidas via `git log` no repositório alterado antes de postar.

> **⚠️ Exceção obrigatória para objetos PL/SQL:** quando o arquivo causador do defeito for um objeto PL/SQL (`emr-tasy-plsql/objects/**`), **nunca usar `git log`/GitHub para rastrear quando a alteração foi introduzida**. O histórico do GitHub não é a fonte confiável para esses objetos — usar **sempre** a tabela `tasy.OBJETO_SISTEMA_HIST` (base Dev), que registra cada revisão do objeto com autor, data (`DT_ATUALIZACAO`), OS (`NR_ORDEM_SERVICO`) e o código-fonte completo daquela revisão (`DS_SCRIPT_CRIACAO`). Ver processo completo (incluindo a técnica de busca binária sobre as revisões) em `plsql-workflow.md`.

**Como obter as informações via git (frontend/backend — não usar para objetos PL/SQL):**
```bash
# PR que introduziu o bug: buscar "Merge pull request" pelo identificador do work item ADO
# O padrão do repositório usa o número do ADO na branch (ex: US_605792 ou AB#711619)
git log --all --format="%h %s" | Select-String "Merge pull request.*<NR_ADO>|<NR_ADO>.*pull request"

# PR da correção atual: buscar pelo número do card atual
git log --all --format="%h %s" | Select-String "Merge pull request.*<NR_CARD>|<NR_CARD>.*pull request"

# Histórico do arquivo alterado (para identificar quando o bug foi introduzido)
git log --format="%h %ai %s" -- <caminho/do/arquivo.prc>

# Branch atual
git branch --show-current

# Status dos arquivos alterados (confirmar o que foi modificado)
git status --short
```

**Instruções de preenchimento do template:**
- **Questão 1:** Localizar o PR que introduziu o bug via `git log`. Com o PR em mãos, verificar no GitHub se ele estava vinculado a uma User Story (Feature) ou a um Bug. Caso não seja possível determinar com certeza, questionar o usuário antes de preencher.
- **Questão 2:** Descrever a localização no sistema como caminho de navegação, sem informar código da função. Exemplo: `Financeiro > Fluxo de Caixa > Caixa de Recebimento > Botão direito > Cancelar`.
- **Questão 4:** Para arquivos PL/SQL, verificar via `tasy.OBJETO_SISTEMA_HIST` (base Dev) se houve alteração recente (aproximadamente último ano) — nunca via `git log`/GitHub. Para os demais repositórios (frontend/backend), verificar via `git log` se houve alteração recente (aproximadamente último ano) nos arquivos envolvidos. Se sim, identificar o PR causador, fazer uma breve descrição do que foi alterado e informar o link do PR como **URL crua em linha separada** (ex: `https://github.com/...`), nunca como markdown `[texto](url)`. Referenciar a OS/feature pelo padrão "OS XXXXXXX" (somente o número, sem prefixo). Atenção: mensagens de commit do git frequentemente usam os prefixos `[SO-XXXXXXX]` ou `[OS-XXXXXXX]` — ambos identificam a mesma Ordem de Serviço. O prefixo `SO-` é utilizado apenas em mensagens de commit (onde serve de referência para validações do PR); na documentação do card ADO, usar sempre apenas "OS XXXXXXX". Quando o commit referenciar `AB#XXXXXX`, trata-se de um card do Azure Boards (Bug, User Story, Feature ou Task) — nesse caso mencionar como "Card XXXXXX", não como OS. Se não houve alteração recente, informar que não. Em caso de dúvida sobre a janela de tempo, questionar o usuário. **Caso o arquivo seja um JSON do Schematics DX** (ex: `cormanos.json`) e o commit causador seja a criação do arquivo (mensagem tipo `ConvertToDX`), **antes de apontar a feature de conversão DX como causa raiz, consultar o Schematics Legado no banco Oracle** para verificar se o registro problemático já existia lá (ver seção "Schematics Legado — Root Cause" abaixo). Se o registro existia no Legado antes da conversão, a causa raiz é o Legado (descrever o registro e a data de `dt_atualizacao` da tabela correspondente) e referenciar a feature de conversão apenas como o veículo que trouxe o problema para o DX. Se o registro não existia no Legado, então a causa raiz é de fato a feature de conversão DX — informar o link https://dev.azure.com/emr-cm/EMR/_workitems/edit/570067. **Não mencionar o nome do usuário** que realizou a alteração no Legado. **Caso o problema seja relacionado a alteração de timezone**, a causa raiz é a feature https://dev.azure.com/emr-cm/EMR/_workitems/edit/667577 — informar o link dessa feature na descrição da questão 4.
- **Questão 5:** Fazer uma breve descrição do que foi corrigido e informar **apenas o link do PR da pre_main** como **URL crua em linha separada** (ex: `https://github.com/...`), nunca como markdown `[texto](url)`. Não listar todos os PRs de versão — somente o pre_main. Deve ser preenchido após abertura do PR no GitHub. Enquanto não houver PR, questionar o usuário para abertura do PR.
- **Questão 6:** Informar a **data completa** (dia/mês/ano) em que o problema foi introduzido. Para arquivos PL/SQL, obter essa data via `DT_ATUALIZACAO` do registro correspondente em `tasy.OBJETO_SISTEMA_HIST` (nunca via `git log`). Para os demais repositórios, obter via `git log --format="%ai %s"` no arquivo alterado. Informar também um breve motivo de por que não havia sido identificado antes. Usar tom cauteloso quando não for possível afirmar com certeza (ex: "possivelmente não foi executado nos testes" em vez de "não era exercido nos testes"). Não incluir hash de commit. **Para arquivos Schematics DX**, usar `git log --diff-filter=A --format="%ai %s" -- <arquivo>` para obter a data de criação do JSON. Se o registro problemático já existia no Schematics Legado (verificado via Oracle MCP), usar a `dt_atualizacao` do registro no Legado como data de referência de introdução do defeito, pois o problema existia antes da conversão DX.
- **Questão 7:** Sempre preencher com "Análise, Testes exploratórios."
- **Questão 8:** Marcar normalmente apenas uma opção — a mais comum é "Funcionalidade" ou "Desempenho". Outras opções podem ser marcadas em casos excepcionais quando realmente se aplicarem. **Manter sempre todas as opções no template** — substituir `(  )` por `(X)` nas opções aplicáveis e manter as demais como `(  )`. Nunca remover as opções não marcadas.
- **Questão 9:** Verificar a versão do card ADO e listar ela mais todas as versões superiores até a dev. Exemplo: card na versão 1838 → `1838, 1842, 1845, 1848, dev`.

**Template:**

```
1 - Como o defeito foi inserido?
[ ] Orgânico (Entrou quando a versão foi criada a partir da dev)
[ ] Versionado (Entrou forçado em versão já liberada no mercado)
     (  ) demanda legal
     (  ) customização
     (  ) bug
     Obs:

2 - Onde: Identificação da funcionalidade ou rotina onde o defeito ocorre
R:

3 - Razão: Por que o defeito ocorre?
R:

4 - Causa: Existe alguma alteração no código fonte que causou o problema? Descreva o que causou o problema e adicione o Pull Request
R:

5 - Correção: Descreva como foi corrigido o defeito e quais alterações foram necessárias e informe o Pull Request
R:

6 - Em qual versão o defeito foi gerado/introduzido? Se foi antes da última versão disponibilizada, por que não havia sido identificado até então?
R:

7 - Medida preventiva: O que poderia ter feito para prevenir o problema?
R:

8 - Natureza do problema
(  ) Funcionalidade – comportamento incorreto em relação à especificação.
(  ) Interface / UI / UX – problemas visuais, layout ou navegação.
(  ) Desempenho – lentidão, travamento, consumo excessivo.
(  ) Segurança – vulnerabilidades, falhas de autenticação, exposição de dados.
(  ) Compatibilidade – problemas em navegadores, dispositivos ou versões diferentes.
(  ) Validação / Dados – erros de cálculo, arredondamento, ou inconsistências de banco.
(  ) Integração – falhas em comunicação entre sistemas.
(  ) Usabilidade – confusão de uso, mensagens pouco claras.
(  ) Infraestrutura / Configuração – ambiente, deploy, permissão, servidor, gestão da versão, bloqueios

9 - Em quais versões as alterações foram aplicadas?
R:
```

---

### Comment 2 — Release Notes

O Release Notes do card ADO possui dois campos de texto: **antes** (comportamento incorreto, no passado) e **depois** (comportamento corrigido, no presente). A função impactada já é informada automaticamente pelo sistema — não incluir no texto.

**Regras de escrita:**
- Redigir em linguagem de usuário final, sem termos técnicos (sem nomes de procedures, tabelas ou campos de banco).
- O campo **antes** deve descrever a situação problemática que o usuário experimentava, no tempo passado.
- O campo **depois** deve descrever o comportamento correto após a correção, no tempo presente, iniciando sempre com "Agora, o sistema...".
- Ser objetivo e conciso — uma ou duas frases por campo é suficiente.
- O contexto de navegação (menu, aba, botão) pode ser mencionado quando ajuda a situar o usuário, mas sem informar código de função.

**Exemplo:**

*Antes:*
> No menu "Código de barras", caso houvesse cadastro para obtenção do CNPJ raiz de um código de barras, e que no CNPJ informado no código houvesse a mesma raiz, mas com numeração final diferente, o sistema não vinculava o código de barras ao título corretamente ao executar o processo via Job.

*Depois:*
> Agora, o sistema identifica o CNPJ raiz informado no código de barras e vincula os títulos corretamente.

---

### Comment 3 — Closure/Resolution

Este comment é a **Closure/Resolution** da discussion do card no ADO. Linguagem direta, com algum grau técnico mas sem excessos. Dois parágrafos curtos:
1. Onde ocorria o problema, qual era o comportamento incorreto e o impacto observável (erro no console, dado incorreto, processo interrompido)
2. O que foi alterado para corrigir (objeto/arquivo, mudança específica) e qual o efeito da correção

> **Restrições obrigatórias:** NÃO incluir datas, nomes de usuários, números de PR ou links de PR no texto da Closure. Esses dados pertencem ao Comment 4 (Alterações Realizadas). A Closure deve ser um texto narrativo de causa raiz e correção, sem referências a rastreabilidade de código.

> **Não incluir arqueologia histórica:** narrativa sobre quando/como o schematics legado foi convertido para DX (número da OS de conversão, data do commit, nome de campos internos como `jsConditions`) pertence exclusivamente à Questão 4 do Comment 1 (Template de defeito), não à Closure. A Closure descreve apenas a causa atual e a correção aplicada — não a história de como o defeito chegou até ali.

**Nível de detalhe esperado:**
- Mencionar a tela/evento/local no sistema onde o problema ocorria (ex: "evento onLoad da tela X", "processo de geração de nota fiscal")
- Citar os campos/valores de negócio diretamente envolvidos na causa (ex: `ref.getValue('CD_CGC')`, `IE_ORIGEM = 'M'`) sem detalhar toda a cadeia de chamadas internas
- Descrever o sintoma observável (erro no console, dado sobrescrito, processo não concluído)
- Na correção, indicar o que foi trocado/ajustado e o efeito resultante — sem listar nomes de queries, procedures auxiliares ou detalhes de implementação interna

> **Escolha de palavras:** seguir a diretriz geral em "Escolha de Palavras" no topo deste arquivo — preferir termos de negócio/usuário final (ex: "opção de mouse") e citar artefatos de implementação (arquivos, métodos, enums criados) apenas quando estritamente necessário.

**Exemplo de tom e tamanho esperado (frontend):**

> Verificado que o problema ocorria no evento onLoad da tela de Nota Fiscal. Após o sistema consultar os dados da pessoa do título e setar o campo `CD_CGC`, a linha subsequente verificava se o campo estava vazio utilizando `ref.getValue('CD_CGC')`. O método `getValue` retornava erro no console, impactando na finalização do processo e não selecionando a forma de pagamento corretamente.
>
> A correção substituiu `ref.getValue('CD_CGC')` por `ref.get('CD_CGC')`, desta forma o processo segue sem erros e o sistema seleciona corretamente a informação de forma de pagamento na nota fiscal.

**Exemplo de tom e tamanho esperado (PL/SQL):**

> Verificado que o erro ocorria pois a procedure `OBTER_TITULO_REGRA_BARRAS` tentava obter o CNPJ raiz via variável local que só é populada quando um parâmetro específico não é nulo. Como a JOB que dispara o processo sempre passa esse parâmetro como null, a variável permanecia nula e o título nunca era localizado.
>
> Realizado ajuste para obter o CNPJ raiz diretamente do parâmetro de entrada, que sempre chega populado independente da origem da chamada. Com isso, o vínculo do boleto ao título passa a funcionar corretamente também pela execução via JOB.

**Exemplo de tom e tamanho esperado (schematics/opção de mouse — evitar citar artefatos de implementação):**

> Verificado que o problema ocorria na opção de mouse "Cancelar nota de crédito" da função Controle de Notas de Crédito a Pagar. O sistema fazia com que a condição de exibição dependesse exclusivamente da regra do schematics, que exigia `IE_ORIGEM = 'M'` (origem Manual). Com isso, a opção não era exibida para notas de origens diferentes de Manual, independentemente do parâmetro 17 (origens permitidas para cancelamento), e também não avaliava a situação da nota nem a existência de baixas.
>
> A correção foi migrar o state da opção de mouse para o fonte, que avalia o parâmetro 17 para verificar se a origem da nota está entre as origens permitidas para cancelamento, além de checar a situação da nota (`IE_SITUACAO = 'A'`) e a ausência de baixas. Com isso, a opção de mouse passou a ser exibida corretamente para todas as origens configuradas no parâmetro 17.

---

### Comment 4 — Alterações Realizadas

Este comment é postado por último e lista todos os PRs abertos por repositório e versão, além dos números de release de cada versão corrigida. Deve ter o título "Alterações Realizadas".

**Regras de preenchimento:**
- Listar apenas os repositórios que foram efetivamente alterados no card. Omitir seções de repositórios sem alteração.
- Informar os links dos PRs como URLs cruas (sem markdown), um por linha, precedidos da versão correspondente.
- Labels de versão do frontend e backend incluem o prefixo completo (ex: `5.06.1848`); no PL/SQL usar apenas o número (ex: `1848`).
- Na seção **RELEASES**, listar os números de release de cada versão corrigida, obtidos via consulta na tabela `AJUSTE_VERSAO` (base Dev). **O identificador do release é sempre o `NR_SEQUENCIA` do registro** — nunca a coluna `NR_RELEASE` (que é apenas um contador interno auxiliar e não corresponde ao número usado para aprovação/rastreio do release). Listar todos os releases da versão (HTML5 e Java/Delphi) separados por vírgula em uma única linha, sem identificar o tipo. O formato facilita cópia direta para aprovação.
- Informar também o status do conjunto de releases de cada versão conforme a seguinte lógica:
  - `DT_LIBERACAO` nula → "Criado"
  - `DT_LIBERACAO` preenchida e `IE_COMPILANDO = 'N'` → "Liberado"
  - `IE_COMPILANDO = 'A'` → "Aprovado"
- Se `NR_SERVICE_PACK` ou `NR_SERVICE_PACK_JAVA` já estiverem preenchidos, informar o número do SP gerado.
- **Sempre consultar `AJUSTE_VERSAO` antes de postar o Comment 4** — não deixar releases como "aguardando" se já foram criados.
- **Se a consulta não retornar nenhum registro para o card**, omitir completamente a seção **RELEASES** do Comment 4. Não incluir a seção com texto como "aguardando criação" ou similar.
- **Sempre consultar `log_data` (base Financial) antes de postar o Comment 4** — verificar se houve alterações de dicionário vinculadas ao card. Se a query retornar resultados, incluir a seção **ALTERAÇÕES DE DICIONÁRIO** ao final do comment. Se não retornar, omitir a seção completamente. Regra de schema (Dev × Financial) e queries de `log_data` documentadas em `.github/agents/tasy-html5-developer/oracle-queries-log-data.md`.

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
> **ATENÇÃO:** o valor a ser usado no comment é sempre o `NR_SEQUENCIA` de cada linha retornada — não o `NR_RELEASE`. A coluna `nr_release` foi incluída na consulta apenas como referência interna, não para uso na documentação.
- Prefixo `5.xx.YYYY` no `CD_VERSAO` → release **HTML5**
- Prefixo `4.xx.YYYY` no `CD_VERSAO` → release **Java/Delphi** da mesma versão numérica `YYYY`
- **Não existe release para a branch DEV** — somente versões de mercado possuem releases.

**Estrutura do comment:**

```
Alterações realizadas:

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


ALTERAÇÕES DE DICIONÁRIO:
<TABELA> (<PK>):
  <CAMPO>: '<valor_anterior>' -> '<valor_final>'
```

> A seção **ALTERAÇÕES DE DICIONÁRIO** só deve ser incluída quando a consulta ao `log_data` retornar resultados. Omitir completamente quando não houver alterações de dicionário registradas para o card. Usar a query de estado final documentada em `.github/agents/tasy-html5-developer/oracle-queries-log-data.md` para obter as informações.

---

## Schematics Legado — Root Cause

Quando um bug envolve uma configuração incorreta no Schematics DX (legenda, campo, layout) e o commit causador é a criação do arquivo JSON (mensagem tipo `ConvertToDX` ou `chore(corXxxFY): Convert function`), **antes de apontar a feature de conversão DX como causa raiz, consultar o Schematics Legado no banco Oracle** para verificar se o registro problemático já existia lá.

**Como verificar:**
```sql
-- Legenda e data de última alteração
SELECT nr_sequencia, ds_legenda, dt_atualizacao
FROM tasy_legenda WHERE nr_sequencia = <nr_seq_legenda>;

-- Itens de cor e datas
SELECT nr_sequencia, ds_item, dt_atualizacao
FROM tasy_padrao_cor WHERE nr_seq_legenda = <nr_seq_legenda>;

-- Vínculo com o painel
SELECT nr_seq_objeto, ie_forma_apres, ie_situacao
FROM objeto_schematic_legenda WHERE nr_seq_legenda = <nr_seq_legenda>;
```

Se o registro existir no Legado com `dt_atualizacao` anterior à conversão DX:
- A causa raiz é o Legado — descrever o registro e a data da `dt_atualizacao`
- **Não mencionar o nome do usuário** que realizou a alteração no Legado
- Referenciar a feature de conversão DX https://dev.azure.com/emr-cm/EMR/_workitems/edit/570067 apenas como o veículo que trouxe o problema para o DX

### Processo de alteração do Schematics Legado

O Schematics Legado reside nas tabelas Oracle (`TASY_LEGENDA`, `TASY_PADRAO_COR`, `REGRA_CONDICAO`, `REGRA_CONDICAO_ITEM`, `OBJETO_SCHEMATIC_LEGENDA`, etc.).

**NÃO é possível alterar essas tabelas diretamente via SQL em banco local.** O trigger `BL$<TABELA>` bloqueia qualquer DML com:
```
ORA-20001: Base tables can't be updated on local databases.
```

**Fluxo correto para alterar o Legado:**
1. Setar o contexto de usuário e OS (para rastreabilidade — os comandos abaixo servem como referência, a execução real acontece via interface):
   ```sql
   BEGIN
       wheb_usuario_pck.set_nm_usuario('<nm_usuario>');
       tasy_dict_integration_pck.set_so(<nr_card_ado>);
   END;
   ```
2. **Fazer as alterações pela interface do Tasy** (Schematics Builder ou função correspondente). O framework executa internamente com o flag `g_updating_base_table = true` via `tasy_dict_integration_pck`, bypassing o trigger. As alterações são gravadas na tabela `LOG_DATA`.
3. Na função **"Manutenção do Dicionário"** do Tasy, enviar o logset para a base DEV.
4. Na base DEV, integrar as alterações — esse é o "commit" no Schematics Legado.

**Packages envolvidos:**
- `wheb_usuario_pck.set_nm_usuario(nm_usuario)` — define o usuário da sessão
- `tasy_dict_integration_pck.set_so(nr_so)` — define o número do card vinculado às alterações (**OBRIGATÓRIO SER O NUMERO DO CARD ADO**)

**Hierarquia de FK para DELETE de legenda (ordem correta):**
1. `REGRA_CONDICAO_ITEM` (WHERE nr_seq_regra IN (...))
2. `REGRA_CONDICAO` (WHERE nr_sequencia IN (...))
3. `TASY_PADRAO_COR` (WHERE nr_sequencia IN (...))
4. `OBJETO_SCHEMATIC_LEGENDA` (WHERE nr_seq_legenda = X AND nr_seq_objeto = Y)
5. `TASY_LEGENDA` (WHERE nr_sequencia = X)

---

## Processo de Commit e Versionamento

### Versões ativas

O sistema Tasy possui múltiplas versões com política de manutenção ativa. As versões atualmente conhecidas são:

| Branch | Versão |
|--------|--------|
| `pre_main` | desenvolvimento (próxima versão, ex: 5.07.1851) |
| `5.06.1848` | versão atual em mercado |
| `5.04.1845` | manutenção ativa |
| `5.03.1842` | manutenção ativa |
| `5.02.1838` | manutenção ativa |

### Branches de integração

- **`pre_main`** — branch intermediária para desenvolvimento. Commits não vão diretamente para `dev`; a `pre_main` atualiza a `dev` diariamente de forma automática.
- **`qa`** — branch paralela à `pre_main`, usada para validação de testes sistêmicos internos. Nem todo commit de `qa` vai para cliente — apenas os que passarem pela `pre_main`.
- **`dev`** — branch de desenvolvimento consolidada. Não recebe commits diretos.

> **Sempre questionar o usuário se é necessário abrir PR para a `qa`.** Nem sempre é necessário.

---

### Fluxo de commit (por repositório)

O processo deve ser executado **separadamente para cada repositório** (frontend, backend, PL/SQL). Para cada repositório com alterações, seguir os passos abaixo.

#### Passo 1 — Verificar estado da branch `pre_main`

```bash
git checkout pre_main
git status
```

A branch deve conter as alterações realizadas.

> **Atenção (backend):** Podem existir dois arquivos modificados usados apenas para subir ambiente local que **não devem ser incluídos no commit**:
> - `TasyAppServer/configuration.yml`
> - `TasyAppServer/context.xml`
>
> Se precisar trocar de branch e houver conflito nesses arquivos, fazer o stash **somente** desses dois arquivos:
> ```bash
> git stash push -- TasyAppServer/configuration.yml TasyAppServer/context.xml
> ```
> **NUNCA usar `git stash` sem path específico** — isso stasha todos os arquivos modificados no repositório, misturando com outros cards e poluindo o stash. Se houver outros arquivos modificados que não devem ser commitados (ex: `ManutOrdemServicoAction.java` de outro card), descartá-los com `git checkout -- <arquivo>` antes de trocar de branch.

#### Passo 2 — Criar branch de trabalho

```bash
# PR para pre_main (ou qa)
git checkout -b {tipo}/{NR_CARD}

# PR para uma versão
git checkout -b {tipo}/{NR_CARD}/{versao}
```

- `{tipo}` é definido pelo tipo do work item no ADO: **`feature`** para Feature/User Story, **`bug`** para Bug.
- `{versao}` é o número da versão, sempre **sem o prefixo `5.xx.`** (ex: `1848`, `1845`, `1842`, `1838`), em todos os repositórios.
- A branch de `pre_main` (e de `qa`) **não recebe sufixo de versão**.
- **Nunca usar ponto** no nome da branch.
- Exemplos: `feature/732567`, `feature/732567/1848`, `bug/700920`, `bug/700920/1845`

#### Passo 3 — Adicionar apenas os arquivos alterados

```bash
git add caminho/do/arquivo.extensao
```

Adicionar somente os arquivos relevantes à alteração. Nunca usar `git add .` sem revisar o que está sendo incluído.

#### Passo 4 — Commit

```bash
git commit -n -m 'fix(modulo) Descrição resumida AB#{NR_CARD}'
```

- **NUNCA usar `git commit --amend`.** Se uma revisão de código exigir ajuste após um commit já feito, criar um segundo commit na mesma branch. O PR ficará com múltiplos commits, o que é correto e rastreável.
- A flag `-n` ignora hooks de pre-commit.
- O módulo deve ser o prefixo da função alterada (ex: `corCreF1`, `corFinF2`, `corCpaF8`).
- **Repositório PL/SQL (`emr-tasy-plsql`):** o módulo não é tão evidente quanto no frontend/backend. Derivar pelo prefixo do nome do objeto alterado:
  - `man_` → `tasyMan` (Manutenção Hospitalar)
  - `ctb_` → `tasyCtb` (Contabilidade)
  - `fin_` → `tasyFin` (Financeiro)
  - `cpa_` → `tasyFin` (Contas a Pagar — usa `tasyFin` por convenção)
  - Demais casos (prefixo não identifica área de negócio) → `tasyFin` (padrão)
- A descrição deve ser curta e objetiva.
- O sufixo `AB#{NR_CARD}` vincula o commit ao work item no Azure DevOps.

Exemplos:
```bash
git commit -n -m 'fix(corCreF1) Ajuste abort valor negativo AB#700920'
git commit -n -m 'fix(corFinF2) Correção cálculo saldo diário AB#712345'
git commit -n -m 'fix(tasyFin) Aumenta ds_erro_w para evitar estouro de buffer AB#718040'
git commit -n -m 'fix(tasyMan) Ajuste em man_ordem_servico AB#700000'
```

#### Passo 5 — Push e abertura de PR

```bash
git push origin {tipo}/{NR_CARD}
```

Após o push, abrir Pull Request para a branch de destino (`pre_main`, `qa` ou versão), preenchendo o template abaixo e adicionando a **label** correspondente à branch de destino:

- `pre_main` → label `pre_main`
- `5.06.1848` → label `5.06.1848`
- `5.04.1845` → label `5.04.1845`
- etc.

> **Repositório PL/SQL:** as labels de versão não possuem prefixo — usar apenas o número da versão (`1848`, `1845`, `1842`, `1838`). A label `pre_main` permanece igual em todos os repositórios.

**Adicionando labels via GitHub CLI (`gh`):**

O MCP do GitHub não suporta adição de labels. Usar o `gh` CLI (instalado em `C:\Program Files\GitHub CLI`):

```bash
# Adicionar label em um PR
gh pr edit {NR_PR} --repo philips-internal/{repositorio} --add-label "{label}"

# Exemplo
gh pr edit 109921 --repo philips-internal/emr-tasy-backend --add-label "pre_main"
```

Para usar o `gh` numa sessão PowerShell nova, incluir o PATH antes:
```powershell
$env:Path += ";C:\Program Files\GitHub CLI"
```

**Label `KEEP_OPEN`:** versões que estão em período de verificação (aguardando aprovação para merge) devem receber a label `KEEP_OPEN` além da label de versão. Aplicar nos PRs de frontend e backend dessas versões para sinalizar que não devem ser mergeados ainda. Atualmente a versão em verificação é a 1851.

> **O nome da label é exatamente `KEEP_OPEN`** — maiúsculas e underscore. Variações como `KEEP OPEN`, `keep open`, `keep_open` ou `Keep Open` **não têm efeito nenhum** em manter o PR aberto. Sempre aplicar a label com essa grafia exata, mesmo que o usuário a mencione de outra forma na conversa (ex: "adiciona a keep open"). Se o comando `gh` falhar informando que a label não existe, **não criar** uma label nova nem tentar variações — verificar as labels disponíveis no repositório com `gh label list --repo philips-internal/{repositorio} --search KEEP`.

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
<descrever o que foi alterado no código>

- How did you test it?
<forma de teste: "Tested in system", "attached video", etc.>

- Any other relevant information to reviewer?
no

- Changed PL/SQL Objects:
<listar objetos PL/SQL alterados, ou "no">

- Backend/Frontend/tasy-plsql-objects PR Link:
<links dos PRs dos outros repositórios envolvidos na mesma alteração, ou "no" se apenas um repositório foi alterado>




#### Tasy HTML5 - Definition of Done (DoD) - Reviewer checklist
##### As a reviewer I have checked _all_ the items mentioned below:

- [ ] All the gated checks are passing 
- [ ] The code has been reviewed observing the business requirements and best practices
- [ ] The code has propper code abstraction
- [ ] No micro code duplication has been found in this pull request
- [ ] Any By-pass for this PR? If Yes, please provide the details here - Failure and Rationale
```

> **"Backend/Frontend/tasy-plsql-objects PR Link":** informar apenas quando houver PRs em outros repositórios envolvidos na mesma alteração. Regra: no PR de cada repositório, listar os links dos PRs dos demais repositórios alterados. Exemplo: se foram abertos PRs de PL/SQL e Backend, no PR do Backend informar o link do PR de PL/SQL, e vice-versa. Se apenas um repositório foi alterado, preencher com `no`.

---

### Versionamento (cherry-pick para versões anteriores)

Após abrir o PR para `pre_main`, verificar no card ADO qual é a versão do bug. A versão deve ser lida no **campo "Versão"** do work item no Azure DevOps — não se basear pelo título do card, pois pode não refletir a versão correta. O commit deve ser aplicado na versão do card **e em todas as versões superiores** até a `pre_main`.

**Exemplo:** card na versão `1842` → commits em `5.03.1842`, `5.04.1845`, `5.06.1848` e `pre_main` (e `qa` se necessário).

> **PROIBIDO:** Nunca aplicar cherry-pick em versões **inferiores** à versão do card. A versão mínima é sempre a versão lida no campo "Versão" do ADO. Exemplo: card na versão `1845` → PRs apenas em `5.04.1845`, `5.06.1848` e `pre_main`. Versões `1842` e `1838` **não devem receber PR**.

> **OBRIGATÓRIO:** Nunca pular versões intermediárias **entre a versão do card e a `pre_main`**. Todas as versões nesse intervalo devem receber o cherry-pick e ter PR aberto. A única exceção permitida é quando o arquivo alterado não existe na versão de destino — situação comum em arquivos JSON do **Schematics DX** quando a função ainda não foi convertida naquela versão.

**Como obter o hash do commit para o cherry-pick:**

```bash
git log --format="%h %s" -5
```

O hash é o código curto (ex: `fa0f786c181`) exibido à esquerda na linha do commit correspondente.
> **Repositório PL/SQL (`emr-tasy-plsql`):** os nomes das **branches de versão** também não possuem o prefixo `5.xx.` usado no frontend/backend — usar apenas o número (`git checkout 1848`, não `git checkout 5.06.1848`). Confirmar com `git branch -r | Select-String "<numero>"` antes de assumir o nome da branch.
Para cada versão, repetir o fluxo abaixo. O hash do commit deve ser o gerado no PR da `pre_main`.

```bash
git checkout 5.06.1848
git pull origin 5.06.1848
git checkout -b {tipo}/{NR_CARD}/{versao}
git cherry-pick {HASH_COMMIT}
git push origin {tipo}/{NR_CARD}/{versao}
```

Exemplos de nome de branch: `feature/732567/1848`, `bug/700920/1845`, `bug/700920/1842`.

> **REGRA CRÍTICA — branches de versão sempre usam barra:** branches de versão devem seguir obrigatoriamente o padrão `{tipo}/{NR_CARD}/{versao}` (ex: `bug/755539/1851`, `bug/755539/1848`). **Nunca substituir a barra por hífen** em branch de versão (ex: não usar `bug/755539-1851` ou `bug/755539-1848`). Se já existir uma branch `{tipo}/{NR_CARD}` que cause colisão de namespace no Git, **parar antes de criar a branch de versão** e solicitar orientação do usuário para remover, renomear ou recriar a branch conflitante. Não prosseguir com alternativa fora do padrão.
>
> **⚠️ Sempre validar a branch atual logo após `checkout -b`, como comando separado:** em uma cadeia de comandos PowerShell (`git checkout X; git pull; git checkout -b Y; git cherry-pick ...`), se um comando intermediário falhar (ex: por causa da colisão de nome acima, ou por estado de prompt corrompido), os comandos seguintes da mesma cadeia podem executar silenciosamente **contra a branch errada** (uma branch de versão compartilhada, ex: `1851` ou `1842`) em vez de abortar. Isso já causou commits diretos acidentais em branches de versão compartilhadas nesta convenção. Antes de qualquer comando git que altere o repositório (`cherry-pick`, `commit`, `push`) após um `checkout -b`, rodar **como comando separado**:
> ```bash
> git branch --show-current
> ```
> e confirmar que o nome corresponde exatamente à branch esperada. Se algo já foi commitado na branch errada por engano, reverter com `git reset --hard origin/<branch>` antes de prosseguir (nunca fazer push nesse estado).

> **Conflitos ao trocar de branch:** pode ocorrer conflito com arquivos locais modificados (ex: `configuration.yml`, `context.xml` no backend) ao executar o `checkout`. Neste caso, fazer stash somente dos arquivos de configuração local:
> ```bash
> git stash push -- TasyAppServer/configuration.yml TasyAppServer/context.xml
> ```
> Após finalizar o versionamento de **todas** as versões, voltar para a `pre_main` e executar `git stash pop` para restaurar apenas esses arquivos.
>
> Se houver outros arquivos locais modificados sem relação com o card atual (arquivos de outro card, dependências temporárias), descartá-los com `git checkout -- <arquivo>` ou `git clean -fd` **antes** do stash — para garantir que o `git stash pop` só restaure `configuration.yml` e `context.xml`.

> **Conflitos no cherry-pick:** se o cherry-pick gerar conflitos em arquivos que estamos alterando (porque a versão de destino possui código diferente), **questionar o usuário antes de prosseguir**.
>
> **Princípio de resolução quando a versão de destino tem estrutura divergente:** quando o conflito ocorre porque a branch de versão antiga tem uma estrutura de código mais antiga/diferente da `pre_main` (ex: `pre_main` já passou por um refactor que a versão antiga não recebeu), **preservar a estrutura já existente na versão de destino** e aplicar apenas as linhas estritamente necessárias para o fix atual — não propagar o refactor não relacionado para a versão antiga. Perguntar ao usuário quando não estiver claro se a divergência é relevante ou não para o fix.

> Sempre abrir PR separado para cada versão.

#### PR de versão já possui commit anterior do mesmo card

Quando a branch de versão já tem um commit do card (ex: fix original) e é necessário incluir um **ajuste complementar** vindo de um novo PR da `pre_main`, **não usar `git reset --hard`**. Fazer o cherry-pick diretamente sobre o commit existente:

```bash
git checkout {tipo}/{NR_CARD}/{versao}
git cherry-pick {HASH_NOVO_COMMIT}
git push origin {tipo}/{NR_CARD}/{versao}
```

O cherry-pick é aplicado sobre o estado pós-commit-antigo, que já corresponde ao contexto do novo commit — evitando conflitos. O PR ficará com **2 commits**, o que é correto e rastreável.

Usar `git reset --hard` + cherry-pick apenas quando o commit antigo **não deve constar** no histórico (estava errado e deve ser substituído). Nesse caso conflitos são esperados pois o contexto da base diverge.

> **REGRA CRÍTICA — Um único PR por card por versão:** Nunca abrir um segundo PR para a mesma versão e mesmo card. Se já existe um PR aberto (ex: `bug/723247/1848` → PR #109922), todos os commits complementares devem ser adicionados à branch existente via cherry-pick — sem abrir nova branch ou novo PR. Isso vale mesmo quando o ajuste vem de uma contexto diferente (ex: correção de outro cenário do mesmo card). Antes de abrir qualquer PR de versão, verificar se já existe um PR aberto para aquela versão e card. Só abrir um segundo PR se o PR original já tiver sido mergeado.
