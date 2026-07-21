# Backend Java — Estrutura

> Referência do agente **Tasy HTML5 Developer**. Carregar ao editar código Java do backend (`emr-tasy-backend`).

O backend de cada função segue um padrão fixo de organização em Java com injeção de dependências (Google Guice).

## Estrutura de pacotes

```
corfin/corfinf2/
  CorFinF2Servidor.java          # Ponto de entrada da função (entry point)
  enums/
    CorFinF2ProcEnum.java        # Mapeamento nome → código de procedure (dic_objeto)
    CorFinF2FunctionEnum.java    # Mapeamento nome → código de function (dic_objeto)
    CorFinF2QueryEnum.java       # Mapeamento nome → código de consulta (dic_objeto)
  components/
    wdlg/
      AlteraSaldoWDLGOkClickAction.java  # Lógica de botão OK de um WDLG
      AccountsReceivableOkClick.java
    items/
      checkout/balance/
        CaixaSaldoDiarioWDBPAction.java  # Action de WDBPanel
  shared/
    CorFinF2GenericAction.java   # Action genérica reutilizável
    CheckNegotiationAction.java  # WCPanelAction (filtro dinâmico)
```

---

## Classe Servidor (`CorFinF2Servidor.java`)

É a **classe principal da função**. Anotada com `@TasyFeature("CorFinF2")` e estende `AbstractWhebServidor`. Ela:
- Recebe todas as chamadas vindas do frontend (via nome do método)
- Injeta todas as `Action` classes via `@Inject`
- Injeta os utilitários do framework: `WProcedurePadrao`, `WFunctionPadrao`, `WConsultaPadrao`
- Expõe métodos públicos chamados pelo frontend

```java
@TasyFeature("CorFinF2")
public class CorFinF2Servidor extends AbstractWhebServidor {

    @Inject private WFunctionPadrao function;
    @Inject private WProcedurePadrao procedure;
    @Inject private WConsultaPadrao consulta;
    @Inject private AlteraSaldoWDLGOkClickAction alteraSaldoWDLGOkClkAct;

    // Chamado pelo frontend via executeProcedure('CANCELAR_CAIXA_RECEB', params)
    public HashMap executeProcedure(String id, HashMap params) throws Exception {
        if (CorFinF2ProcEnum.getCodeByDesc(id) > 0) {
            return procedure.executa(CorFinF2ProcEnum.getCodeByDesc(id), params, false);
        }
        return null;
    }

    // Chamado pelo frontend via executeFunction('OBTER_MOEDA_PADRAO_EMPRESA', params)
    public Object executeFunction(String id, HashMap params) throws Exception {
        if (CorFinF2FunctionEnum.getCodeByDesc(id) > 0) {
            return function.executaRetornoObject(CorFinF2FunctionEnum.getCodeByDesc(id), params);
        }
        return null;
    }

    // Chamado pelo frontend via executeQueryAsHash('GET_IE_INTEGRACAO', params)
    public HashMap executeDefaultQuery(String id, HashMap params) throws Exception {
        if (CorFinF2QueryEnum.getCodeByDesc(id) > 0) {
            return consulta.executaAsHashMap(CorFinF2QueryEnum.getCodeByDesc(id), params, false);
        }
        return null;
    }

    // Método customizado chamado pelo frontend via nome do método
    public void alteraSaldoWDLGOkClickAction(HashMap paramsHist, HashMap paramsProc) throws Exception {
        alteraSaldoWDLGOkClkAct.alterarSaldoOkClickWdlg(paramsHist, paramsProc);
    }
}
```

---

## Enums de mapeamento

Cada tipo de chamada tem seu próprio enum que mapeia o **nome string** (usado no frontend) para o **código numérico** do objeto em `dic_objeto`.

```java
// CorFinF2ProcEnum — procedures
CANCELAR_CAIXA_RECEB(5582),
GERAR_CHEQUE_CR_NEGOCIADO(6479),
CLOSE_RECEIPTS_CASH(12346),
// ...

// CorFinF2FunctionEnum — functions
OBTER_MOEDA_PADRAO_EMPRESA(56275),
OBTER_COTACAO_MOEDA_PARALELO(57157),
// ...

// CorFinF2QueryEnum — consultas SELECT
GET_IE_INTEGRACAO(219851),
GET_BALANCES(95320),
GET_NR_SEQ_CAIXA_REC(1211179),
// ...
```

Todos os enums implementam `getCodeByDesc(String desc)` — que busca o enum pelo nome e retorna o código numérico, ou `0` se não encontrado.

> Para adicionar uma nova procedure/function/query acessível pelo frontend, basta incluir a entrada no enum correspondente com o código do objeto em `dic_objeto`.

---

## Classes de Action

Contêm a lógica de negócio complexa que não pode ser expressa apenas por uma procedure SQL. Estendem `WhebAction` e recebem `RequisicaoVO` no construtor.

**Utilitários disponíveis via herança de `WhebAction`:**

| Método | Descrição |
|---|---|
| `getWhebDAO().executaConsultaPadraoAsHashMap(code, params, false)` | Executa consulta pelo código e retorna `HashMap` |
| `executaProcedurePadrao(code, params)` | Executa procedure pelo código numérico |
| `getUsuario().getNmUsuario()` | Nome do usuário logado (via `RequisicaoVO`) |
| `getUsuario().getCdEstabelecimento()` | Estabelecimento do usuário logado |
| `WDAOInjector.textoPadrao().executa(code, ...macros)` | Executa texto de `dic_objeto` com substituição de macros |

**Utilitário `UServPac`** — helper para conversão segura de tipos (null-safe):

```java
UServPac.validaString(params.get("NM_CAMPO"))   // → String, nunca null
UServPac.validaLong(params.get("NR_SEQUENCIA"))  // → long, 0 se null
UServPac.validaInteger(params.get("CD_CODIGO"))  // → int, 0 se null
UServPac.isNull(value)                           // → true se null/vazio
```

**Exemplo de Action:**

```java
public class AlteraSaldoWDLGOkClickAction extends WhebAction {

    @Inject
    public AlteraSaldoWDLGOkClickAction(RequisicaoVO requisicao) {
        super(requisicao);
    }

    public void alterarSaldoOkClickWdlg(HashMap paramsHist, HashMap paramsProc) throws Exception {
        if ((boolean) paramsHist.get("IS_MOEDA_NACIONAL")) {
            String dsHistorico = WDAOInjector.textoPadrao().executa(562346,
                paramsHist.get("DT_SALDO"), paramsHist.get("VL_SALDO_ANTIGO"), ...);
            executaProcedurePadrao(33519, paramsProc);
            // lógica adicional...
        }
    }
}
```

---

## `DataSourceActionParameter` — Actions de WDBPanel

Quando o Schematics DX executa uma Action de WDBPanel (INSERT/UPDATE/DELETE), o backend recebe um `DataSourceActionParameter` que fornece acesso aos `paramsAdicionais` enviados pelo frontend no `onBeforePerform` (ver `frontend-framework.md`):

```java
public HashMap caixaRecebNegOnNewRecord(DataSourceActionParameter action) throws Exception {
    // Acessa paramsAdicionais enviados pelo frontend
    long nrSeqSaldo = UServPac.validaLong(action.getParametroAdicional("NR_SEQUENCIA_SALDO"));
    long nrSeqCaixa = UServPac.validaLong(action.getParametroAdicional("NR_SEQ_CAIXA"));

    HashMap params = new HashMap();
    params.put("NR_SEQ_SALDO", nrSeqSaldo);

    HashMap result = getWhebDAO().executaConsultaPadraoAsHashMap(98348, params, false);
    // ...
    return retornoAction; // campos retornados ficam disponíveis no onAfterPerform do frontend
}
```

---

## `WCPanelAction` com `@NamedAction` — Filtros dinâmicos de CPanel

Usada para montar restrições SQL dinâmicas em painéis de listagem (CPanels/WPicklists). Implementa `build(Map<String, Object> params)` onde as restrições são adicionadas com `addRestricaoFiltro(sql, valor)`.

```java
@NamedAction(name = "ativarChequeNegociationWCPAction", referedInterface = WCPanelAction.class)
public class CheckNegotiationAction extends WCPanelAction {

    public CheckNegotiationAction(RequisicaoVO request, Integer code) {
        super(request, code);
    }

    @Override
    public void build(Map<String, Object> params) {
        if ("S".equalsIgnoreCase(UServPac.validaString(params.get("IE_RESTRINGE_ESTAB_CHEQUE")))) {
            addRestricaoFiltro(" and c.cd_estabelecimento = :cd_estab ",
                UServPac.validaLong(params.get("CD_ESTAB_CHEQUE")));
        }
        if (!UServPac.isNull(params.get("NR_CHEQUE"))) {
            addRestricaoFiltro(" and c.nr_cheque = :nr_cheque ", params.get("NR_CHEQUE"));
        }
        addRestricaoFiltro(" order by c.nr_cheque ");
    }
}
```

O nome declarado em `@NamedAction` é referenciado no Schematics DX JSON do CPanel para ativar o filtro dinâmico.
