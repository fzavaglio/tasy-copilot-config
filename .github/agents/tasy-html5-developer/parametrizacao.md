# Parametrização por Função (Regras de Negócio)

> Referência do agente **Tasy HTML5 Developer**. Carregar sempre que encontrar `isParameter`/`getParameter` (frontend), `UGenericServidor.obterParametroUsuario` (backend) ou `OBTER_PARAMETRO_FUNCAO` (PL/SQL).
>
> Exemplos concretos de parâmetros de uma função específica (número, descrição, comportamento) ficam na skill do módulo correspondente (ex: `corfin`, `corcpa`) — este arquivo cobre apenas o padrão genérico, válido para qualquer função.

O Sistema Tasy permite que cada função seja configurada por **parâmetros de função**, cadastrados via interface administrativa (corSis). Cada parâmetro possui um número (`NR_PARAMETRO`) e um valor definido pelo cliente/instalação. Os parâmetros controlam comportamentos de negócio que variam por cliente, país ou configuração do hospital.

A implementação da regra pode ocorrer no **frontend**, no **backend** ou no **PL/SQL**, dependendo do contexto.

---

## Hierarquia de resolução do parâmetro

O framework resolve o valor do parâmetro seguindo esta ordem de prioridade, parando na primeira que retornar um valor não nulo:

```
1. Parâmetro por Usuário      (configurado para o usuário logado)
        ↓ null
2. Parâmetro por Perfil       (configurado para o perfil do usuário)
        ↓ null
3. Parâmetro por Estabelecimento  (configurado para o estabelecimento do usuário)
        ↓ null
4. Valor padrão do parâmetro  (valor default cadastrado na definição do parâmetro)
```

> Nunca assuma qual nível está sendo lido em uma instalação específica. O valor efetivo depende do que foi configurado no ambiente do cliente.

---

## Uso no Frontend (JavaScript)

Qualquer controller que herda de um componente base (`WDBPanel`, `WPUMC`, etc.) tem acesso direto aos parâmetros da função. O framework já aplica automaticamente a hierarquia acima ao resolver o valor.

**`this.isParameter(nr)`** — retorna `true` se o parâmetro tem valor "verdadeiro" (geralmente `'S'` ou valor numérico > 0):

```js
onReady() {
  if (!this.isParameter(29)) {
    this.handler.getDetailHandler().events.addAttribBlur(['CD_PESSOA_FISICA'], () => { ... });
  }
  this.getAttribute('CD_PESSOA_FISICA').attributeInfo.setReadOnly(this.isParameter(4));
}

onSelectionChange() {
  this.handler.setReadOnly(!this.isParameter(9));
}
```

**`this.getParameter(nr)`** — retorna o valor bruto do parâmetro (`'S'`, `'N'`, número, string):

```js
onBeforePerform(schematics, dbPanel, event) {
  if (this.getParameter(14) == 'S') {
    if (this.getParameter(15) == 'S') {
      // rotina alternativa
    }
  }
}

// Via schematics (fora do contexto de um componente específico)
if (schematics.getParameter(1) == 'N') {
  cdEstabField.setReadOnly(true);
}
```

**Usos comuns no frontend:**
- Exibir/ocultar abas ou campos (`setVisible`, `setReadOnly`)
- Habilitar/desabilitar componentes (`setEnabled`)
- Alterar fluxo de execução no `onBeforePerform` / `action()`
- Controlar permissão de CRUD (`handler.setAccessPermission`)

---

## Uso no Backend (Java)

No backend, o parâmetro é acessado via `UGenericServidor.obterParametroUsuario`, que recebe a requisição, o código da função (`cd_funcao`) e o número do parâmetro. A hierarquia de resolução é aplicada internamente pelo framework:

```java
private Object getParameter(int nrParam) throws Exception {
    return UGenericServidor.obterParametroUsuario(getRequisicao(), 813, nrParam);
}

public HashMap auditDailyBalance(HashMap parameters) throws Exception {
    boolean iePermiteEdit = "S".equalsIgnoreCase((String) getParameter(91));

    if (!iePermiteEdit) {
        HashMap paramIn = new HashMap();
        paramIn.put("CD_ESTABELECIMENTO", parameters.get("CD_ESTABELECIMENTO"));
        iePermiteEdit = "S".equalsIgnoreCase(
            (String) executaConsultaPadraoCampo(122175, paramIn)
        );
    }
    // ...
}
```

**Usos comuns no backend:**
- Selecionar qual procedure executar (fluxos diferentes por parâmetro)
- Validar/consistir dados antes de persistir
- Incluir ou omitir parâmetros de retorno para o frontend
- Controlar auditoria, log ou integrações externas

---

## Uso no PL/SQL

No repositório PL/SQL, a função utilitária padrão para ler parâmetros é geralmente `OBTER_PARAMETRO_FUNCAO` (ou similar), chamada diretamente dentro das procedures:

```sql
v_param := OBTER_PARAMETRO_FUNCAO(cd_funcao => 813, nr_parametro => 27);

IF v_param = 'S' THEN
  -- permite alteração de cartão
ELSE
  RAISE_APPLICATION_ERROR(-20001, 'Alteração não permitida por parâmetro.');
END IF;
```

**Usos comuns no PL/SQL:**
- Consistências de negócio antes de INSERT/UPDATE/DELETE
- Controle de geração de lotes, contabilização, integração
- Seleção de algoritmos de cálculo distintos por configuração

---

## Regras críticas para manutenção de parâmetros

> **ATENÇÃO:** Nenhuma alteração em lógica de parâmetro deve ser feita sem uma instrução clara e explícita descrevendo o comportamento esperado. Parâmetros são configurações de negócio sensíveis e erros aqui afetam todos os clientes/instalações.

**Erros comuns a evitar:**

1. **Número de parâmetro incorreto** — Verificar sempre se o número do parâmetro utilizado no código corresponde exatamente à descrição cadastrada em `parametro_funcao`. Não confiar apenas no número; validar a descrição do parâmetro no banco antes de usar.

2. **Lógica invertida** — O erro mais frequente: o parâmetro está definido como *"Exibir aba X com valor S"*, mas o código implementa a exibição quando o valor é `'N'`. Antes de alterar, confirmar:
   - Qual valor (`S`/`N`, `1`/`0`, string específica) ativa o comportamento
   - Se `isParameter` é adequado (truthy) ou se é necessário comparar o valor bruto com `getParameter`
   - Exemplo de lógica invertida a evitar:
     ```js
     // ERRADO: parâmetro 27 com valor 'S' deveria PERMITIR, mas está bloqueando
     if (this.isParameter(27)) {
       this.handler.setReadOnly(true); // ← invertido
     }

     // CORRETO
     if (!this.isParameter(27)) {
       this.handler.setReadOnly(true);
     }
     ```

3. **Manutenção em comportamento existente** — Ao modificar um trecho que já lê um parâmetro, verificar se a lógica atual está correta antes de alterar. Não assumir que o código legado está certo — pode já existir um bug de lógica invertida ou número errado.

4. **Valor `null` não tratado** — Se nenhum nível da hierarquia tiver o parâmetro configurado, o retorno será `null`. Comparações como `getParameter(x) == 'S'` são seguras (retornam `false`), mas comparações numéricas ou acesso a propriedades de `null` causam erros.

5. **Não implementar parâmetro novo sem especificação** — Caso seja necessário criar ou registrar um novo parâmetro, questionar o usuário sobre: número, descrição, valores possíveis, comportamento esperado para cada valor e camada de implementação.

---

## Verificação obrigatória de parâmetros ao analisar lógica de negócio

Sempre que encontrar **qualquer chamada de parâmetro de função** em qualquer repositório, executar os passos abaixo **antes** de qualquer alteração ou análise da lógica.

**Padrões de chamada por repositório:**

| Repositório | Padrão identificável |
|---|---|
| **Frontend (JS)** | `this.isParameter(N)`, `this.getParameter(N)`, `schematics.getParameter(N)` |
| **Backend (Java)** | `UGenericServidor.obterParametroUsuario(getRequisicao(), CD_FUNCAO, N)` |
| **PL/SQL** | `OBTER_PARAMETRO_FUNCAO(cd_funcao => X, nr_parametro => N)` ou similar |

### Passo 1 — Confirmar que o parâmetro está habilitado para HTML5

Consultar na base **Dev** (`mcp_oracle_*`, ver `oracle-queries-log-data.md` para a regra de schema):

```sql
SELECT nr_sequencia, ds_parametro, ie_situacao_html5, cd_funcao
FROM tasy.parametro_funcao
WHERE cd_funcao = <CD_FUNCAO>
  AND nr_sequencia = <NR_PARAMETRO>
```

- `IE_SITUACAO_HTML5 = 'A'` → parâmetro ativo no HTML5, pode ser usado normalmente
- `IE_SITUACAO_HTML5 = 'I'` → parâmetro inativo no HTML5 → executar o Passo 2

### Passo 2 — Verificar release notes de depreciação

Se o parâmetro estiver inativo (`IE_SITUACAO_HTML5 = 'I'`), verificar se existe um release note de depreciação registrado:

```sql
SELECT nr_seq_parametro, cd_funcao_param, si_type, si_alternative, ds_reason
FROM tasy.function_release_note
WHERE nr_seq_parametro = <NR_PARAMETRO>
  AND cd_funcao_param  = <CD_FUNCAO>
  AND si_type          = 'D'
```

**Interpretação do resultado:**

| Campo | Valor | Significado |
|---|---|---|
| `SI_TYPE` | `D` | Release note de depreciação |
| `SI_ALTERNATIVE` | `CR` | Substituído por Regra de Configuração de Utilização (Administração do Sistema) |
| `DS_REASON` | texto | Motivo da depreciação — ler e considerar antes de qualquer alteração |

**Ação com base no resultado:**

- **Com release note de depreciação:** informar ao usuário que o parâmetro foi depreciado, exibir `DS_REASON` e `SI_ALTERNATIVE`. Não manter lógica baseada no parâmetro sem alinhamento explícito do usuário.
- **Sem release note:** o parâmetro está inativo mas sem justificativa registrada — sinalizar ao usuário e aguardar orientação antes de prosseguir.
- **Parâmetro ativo (`A`):** prosseguir normalmente com a análise da lógica.

> **Aplicação prática:** ao abrir um arquivo como `CancelarNotaCreditoWJMI.js` que usa `this.schematics.getParameter(17)`, verificar `parametro_funcao` para `nr_sequencia = 17` e o `cd_funcao` da função pai antes de qualquer análise do comportamento.

---

## Alteração de parâmetro por usuário durante testes — é necessário relogar

Ao alterar um valor em `funcao_param_usuario` diretamente no banco (ex: via `UPDATE ... WHERE nm_usuario_param = '<usuario>'`) para fins de teste, **um simples reload da página (F5 / `page.reload()`) não é suficiente** para o frontend refletir o novo valor. O backend (Java) resolve e mantém os parâmetros da função em cache por **sessão HTTP do usuário**, então `schematics.getFeatureParameter(cd_funcao, nr_parametro)` continua retornando o valor antigo mesmo após reload completo da SPA.

**Procedimento correto para validar mudança de parâmetro em teste:**
1. Alterar o valor em `funcao_param_usuario` (base correspondente ao ambiente testado)
2. Solicitar ao usuário (ou realizar, se houver credenciais) **logout completo e login novamente** — isso força nova sessão no backend e reprocessa a hierarquia de resolução do parâmetro
3. Só então reabrir a função e validar o novo comportamento

> Reload de página sozinho reinicializa o Angular app, mas reaproveita a sessão/cookie existente no backend — o cache de parâmetros por sessão não é invalidado. Confirmado no card 731440 (parâmetro 181 do corManOS).
