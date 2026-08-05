# Frontend Framework — Componentes e Integração com Backend

> Referência do agente **Tasy HTML5 Developer**. Carregar ao editar/entender código JavaScript de tela (controllers, WDBPanels, dialogs, filtros).

## Principais Componentes do Framework (Frontend)

Todos os componentes são classes ES6 decoradas com `@Controller` (ou `@Feature`) e importadas de `odin-utils/controllers` ou `@philips/odin-ext`. Cada componente possui um `code` numérico único que o referencia no schematics.

### WFeature
Ponto de entrada de uma função (tela). Decorado com `@Feature`. É o controller raiz que carrega o `schematic` da função. Eventos: `onAfterActivate`.

### WDBPanel
Componente de tabela/grid. Permite CRUD de registros, exibição em modo Grid e modo Detalhe, inclusão de opções de menu de contexto, tratamento de campos (ocultar, desabilitar, tornar obrigatório), painéis filhos e visões (views). As visões permitem que um mesmo WDBPanel exiba conjuntos de campos diferentes, geralmente variando por localização do sistema (Brasil, México, Colômbia...). Eventos principais: `onReady`, `onBeforePerform`, `onSelectionChange`. Acesso via `this.schematics.get(code)`.

### WPUMC
Menu item de contexto (botão de ação em grid ou toolbar). Implementa a lógica de uma ação do usuário. O método principal é `action()`. Costuma chamar `executeProcedure`, abrir dialogs via `tasyWdlgPanel.show(code, schematics)` ou `tasyWdialogbox`. Referenciado no decorator com `parent` apontando para o WDBPanel pai.

### WDLGPanel
Painel de diálogo (WDLG). Container de um dialog aberto via `tasyWdlgPanel.show(code, schematics)`. Pode conter campos, WDBPanels filhos e botões.

### WDLGPanelButton
Botão de confirmação (OK) dentro de um WDLG. Implementa o método `onClick(schematics, dlg)` com a lógica de validação e execução ao confirmar o dialog. Herda de `WDLGPanelButton`.

### WPicklist
Componente de dois slots (esquerdo/direito) para mover itens entre listas. Eventos: `onLeftToRightClick`, `onRightToLeftClick`. Acesso aos slots via `this.handler.getLeftSlot().handler` e `this.handler.getRightSlot().handler`. Costuma chamar `executeProcedure` para persistir as mudanças e `this.handler.reactivateSlots()` para recarregar.

### WFilter
Componente de filtro de pesquisa. Implementa `onFilter(schematics)` que é chamado quando o usuário dispara a busca. Normalmente executa uma procedure ou query para popular um WDBPanel associado. Acesso ao formulário de filtro via `this.handler.getFilterHandler().getValue(campo)`.

### WTabPanel
Componente de abas (tabs). Permite navegação entre grupos de conteúdo. Eventos: `onLoad`. Métodos: `handler.setVisibleByCode(code, bool)` para mostrar/ocultar abas dinamicamente, `selectTab(value)` para selecionar uma aba por valor.

---

## Integração Frontend ↔ Backend

O frontend se comunica com o backend Java por meio de métodos herdados dos componentes base (`WDBPanel`, `WPUMC`, etc.). Todos os métodos são assíncronos e retornam Promises.

### `executeProcedure(nome, params)`
Chama uma PL/SQL procedure mapeada no backend pelo nome declarado no Schematics. Retorna uma Promise com o resultado. Os parâmetros são passados como objeto chave/valor com sufixo `_P` (convenção dos parâmetros de entrada da procedure).

```js
this.executeProcedure('GERENCIAR_VIAGEM', { NR_SEQUENCIA_P: 123, IE_ACAO_P: 'F' })
  .then(retorno => { /* retorno contém parâmetros de saída */ });
```

### `executeQueryAsHash(nome, params)`
Executa uma query (SELECT) declarada no Schematics pelo nome. Retorna um hash (objeto) com os campos do primeiro registro encontrado, ou uma Promise com esse hash. Usada para buscar valores pontuais sem popular um WDBPanel.

```js
this.executeQueryAsHash('SELECT_784576', {}).then(response => {
  if (response.IE_FUNCIONARIO == 'N') { ... }
});
```

### `executeFunction(nome, params)`
Chama uma function PL/SQL declarada no Schematics. Similar ao `executeProcedure`, mas adequado para funções que retornam um valor escalar. Retorna Promise com `{ dados: valor }`.

```js
this.executeFunction('GET_MOEDA_PADRAO_EMPRESA', {}).then(result => {
  this.cdMoedaEmpresa = result.dados;
});
```

---

## Actions (Ações do WDBPanel)

As **Actions** são operações de CRUD (`INSERT`, `UPDATE`, `DELETE`, `NEW_RECORD`, `EDIT`, `DELET`) que o próprio framework executa automaticamente ao salvar/excluir um registro em um WDBPanel. O backend executa a procedure/action mapeada no Schematics para aquele WDBPanel automaticamente — sem que o frontend precise chamar nada explicitamente.

O frontend pode interceptar essas ações por meio dos eventos:

### `onBeforePerform(schematics, dbPanel, event)`
Executado **antes** de o framework enviar a action ao backend. Permite:
- Inspecionar `event.acao` (`'INSERT'`, `'UPDATE'`, `'DELETE'`, `'NEW_RECORD'`, `'EDIT'`, `'DELET'`) para aplicar lógica condicional.
- Adicionar parâmetros extras via `event.paramsAdicionais` — objeto cujas chaves serão enviadas junto ao request da action e estarão disponíveis na procedure do backend.
- Abortar a operação (via `event.abort()` ou lançando um erro).

```js
onBeforePerform(schematics, dbPanel, event) {
  event.paramsAdicionais = {
    VL_SALDO: this.outroDBP.handler.getValue('VL_SALDO'),
    CD_MOEDA: this.outroDBP.handler.getValue('CD_MOEDA')
  };
  if (event.acao == 'DELETE' && this.getValue('IE_ETAPA') == 6) {
    this.tasyWdialogbox({ type: 'Abort', message: 114192 });
  }
}
```

### `onAfterPerform(schematics, dbPanel, event)`
Executado **após** o backend processar a action com sucesso. Permite recarregar painéis relacionados, atualizar estado da tela ou ler parâmetros de retorno via `event.paramsAdicionais` (o backend pode popular esses parâmetros no retorno).

```js
onAfterPerform(schematics, dbPanel, event) {
  if (event.acao == 'INSERT' || event.acao == 'UPDATE') {
    if (event.paramsAdicionais.reactivate == 'S') {
      this.outroPainel.handler.reloadSelectedRecords();
    }
  }
}
```

> **Resumo do fluxo de uma Action:**
> `usuário confirma salvar` → `onBeforePerform` (frontend) → `request HTTP ao backend` → `procedure PL/SQL` → `onAfterPerform` (frontend)

---

## Read-only de atributos: `readOnly` × `internalReadOnly`

Cada atributo de um WDBPanel (`dbPanel.getDetailHandler().getAttribute('CAMPO').attributeInfo`) possui **dois flags de read-only independentes**, e o estado efetivo do widget é `readOnly || internalReadOnly`:

| Flag | Métodos | Significado |
|---|---|---|
| **readOnly (lógico)** | `setReadOnly(bool)` / `isReadOnly()` | Read-only de regra de negócio/permissão. É o que os controllers normalmente controlam. |
| **internalReadOnly (framework)** | `setInternalReadOnly(bool)` / `isInternalReadOnly()` | Read-only interno do framework, usado principalmente pelo comportamento de grid (preview). |

### Comportamento master-detail em modo grid (preview)

Em um WDBPanel **master-detail** (grid em cima + formulário de detalhe embaixo), enquanto a lista está em **modo grid**, o framework marca **todos** os atributos do formulário de detalhe como `internalReadOnly=true` — o detalhe abaixo do grid é um **preview somente-leitura**. Ao entrar no registro (duplo-clique → modo detalhe) o `internalReadOnly` é limpo e permanece `false` ao voltar ao grid.

Consequências:
- Definir apenas `setReadOnly(false)` (lógico) **não** torna o campo editável em grid — o `internalReadOnly=true` do preview continua bloqueando.
- Para permitir a edição de **um campo específico** direto no grid, é preciso limpar também o interno: `attributeInfo.setInternalReadOnly(false)` naquele campo (mantendo os demais campos do detalhe como preview read-only). Inversamente, `setInternalReadOnly(true)` força um campo a ficar read-only em grid.
- Painéis "flat" (sem preview de detalhe master-detail), onde a edição ocorre na própria linha do grid, **não** sofrem esse read-only interno — o campo é editável em grid sem tratamento algum.

---

## Manipulação de atributos em runtime (WDBPanel)

O acesso a um atributo do detalhe é feito via `dbPanel.getDetailHandler().getAttribute('NM_ATRIBUTO')`. O wrapper retornado expõe métodos para alterar o estado do campo em tempo de execução:

| Método | Efeito |
|---|---|
| `setVisible(bool)` | Mostra/oculta o campo |
| `setLabel(texto)` | Altera o label exibido (passar o **texto já resolvido**, não o código da expressão) |
| `setMandatory(bool)` | Torna obrigatório/opcional |
| `setReadOnly(bool)` | Read-only lógico (ver seção anterior) |
| `setEnabled(bool)` | Habilita/desabilita |

Para limpar o valor de um campo, usar `this.clearValue('NM_ATRIBUTO')` no controller.

### Não existe API de reposicionamento em runtime

O framework **não** possui API para reordenar/reposicionar campos em tempo de execução. O wrapper do atributo só tem `setVisible/setLabel/setMandatory/setReadOnly/setEnabled` — **não** há `setOrdem` nem método de reorder. Alterar `metaAttribute.ordem` e forçar `$apply` **não** reordena o DOM.

> A ordem/posição dos campos é fixada pelo Schematics (propriedades `ordem`/`nrSeqGrupo` no JSON do dbpanel). Para mover um campo de posição, **editar o JSON do schematic** — não é possível fazê-lo por código no controller. Como o dbpanel é escolhido por visão (localidade), o reposicionamento precisa ser replicado em **todas as visões** da função (ver `schematics-dx.md`).

### `setLabel` — usar o wrapper `getAttribute`, não o `attributeInfo`

`getDetailHandler().getAttribute(nome).setLabel(TEXTO)` atualiza o label exibido corretamente. Já `attributeInfo.setLabel(codigo)` grava um valor cru e **não** atualiza o que aparece na tela — não usar essa via para trocar o label.

### `clearValue` durante navegação no grid suja o registro

Chamar `clearValue` enquanto a lista está em **modo grid** (navegando/pré-visualizando linhas) marca o registro como alterado, disparando o diálogo de descarte ao trocar de linha. Ao ocultar campos condicionalmente e querer limpar seus valores, **guardar a limpeza com `this.isEditing()`** — só limpar em modo de edição, nunca durante a navegação/preview do grid:

```js
applyLayoutCondicional(condicao) {
  const detail = this.handler.getDetailHandler();
  const podeLimpar = condicao && this.isEditing();
  ['CD_PESSOA_CONTRATANTE', 'CD_PACIENTE', 'CD_MEDICO_RESP'].forEach(nmAtributo => {
    if (podeLimpar) {
      this.clearValue(nmAtributo);
    }
    detail.getAttribute(nmAtributo).setVisible(!condicao);
  });
}
```

### Layout condicional dirigido por consulta ao backend

Quando a visibilidade/estado de campos depende de uma regra de negócio (ex: o tipo selecionado num LCB), consultar o backend via `executeAction`/`executeQueryAsHash` e aplicar o layout nos eventos relevantes — tipicamente no `onSelectionChange` (troca de registro no grid) e no evento de alteração do campo que dispara a regra (ex: `alterNrSeqTipoContrato`). Reaplicar o layout em ambos evita estado inconsistente ao navegar entre registros.

---

## Boas práticas de código (padrões de revisão)

Convenções recorrentes cobradas em revisão de PR e/ou pelo SonarQube neste frontend:

### Não usar helpers do `angular` para lógica simples

Evitar `angular.equals(a, b)` e afins para comparações triviais — preferir operadores nativos do JS. Reservar `angular.*` para casos em que realmente se precisa da semântica do framework (ex: deep-equal de objetos complexos).

| ❌ Evitar | ✅ Preferir |
|---|---|
| `return angular.equals(true, res?.dados);` | `return res?.dados === true;` |
| `if (angular.equals('S', valor))` | `if (valor === 'S')` |

### Não passar `await` diretamente como argumento

Extrair o resultado de um `await` para uma **variável nomeada** antes de usá-lo como parâmetro. Facilita leitura, manutenção e debug (permite inspecionar o valor). Também evita `await` aninhado dentro de chamada.

```js
// ❌ Evitar
this.applyArrendamentoLayout(await this.isTipoArrendamento());

// ✅ Preferir
const isArrendamento = await this.isTipoArrendamento();
this.applyArrendamentoLayout(isArrendamento);
```

### `await` só sobre Promises; usar optional chaining

- Não usar `await` sobre método **síncrono** (que não retorna Promise) — o SonarQube reprova (regra S4123, "redundant await on non-promise"). Só marcar um método como `async`/aguardá-lo quando ele realmente faz trabalho assíncrono.
- Preferir **optional chaining** a `x && x.prop` (SonarQube S6582): usar `res?.dados` em vez de `res && res.dados`.

> Verificar essas violações localmente com o SonarQube MCP (`analyze_code_snippet`) **antes** de abrir/atualizar o PR, para não depender do ciclo lento dos checks do pipeline.
