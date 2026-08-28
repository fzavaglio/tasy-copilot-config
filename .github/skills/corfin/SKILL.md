---
name: corfin
description: Business knowledge for corFin module functions (Financeiro, Fluxo de Caixa, Tesouraria). Activates: When testing, navigating or developing any corFin function — corFinF2, corFinF3, or other corFin functions.
---

# corFin — Módulo Financeiro

> Skill de módulo. Para funções específicas, criar skills individuais (ex: `corfin-f2\SKILL.md`).

---

## Funções do módulo

| Função | cd_funcao | Descrição |
|---|---|---|
| corFinF2 | (verificar) | Caixa de Recebimento / Fluxo de Caixa |
| corFinF3 | (verificar) | (verificar) |
| *(outras)* | — | *(a documentar)* |

---

## Conhecimento de Negócio

### corFinF2 — Exemplos de Parâmetros de Função

Exemplos concretos de parâmetros já identificados nesta função (número, comportamento e efeito). Ver a skill/regra geral de parametrização (arquivo `parametrizacao.md` do agente Tasy HTML5 Developer) para a hierarquia de resolução e regras críticas genéricas.

| Parâmetro | Descrição | Efeito |
|---|---|---|
| `1` | Permitir ou bloquear edição por estabelecimento | `schematics.getParameter(1) == 'N'` → campo `CD_ESTABELECIMENTO` fica somente leitura |
| `4` | Tornar campo `CD_PESSOA_FISICA` somente leitura | `this.isParameter(4)` → `setReadOnly` no campo |
| `9` | Painel somente leitura para determinado perfil | `this.isParameter(9)` → `handler.setReadOnly` no `onSelectionChange` |
| `14` | Define fluxo de aprovação | `getParameter(14) == 'S'` → avalia parâmetro 15 para decidir rotina alternativa |
| `15` | Sub-fluxo de aprovação (depende do parâmetro 14) | `getParameter(15) == 'S'` → aciona rotina alternativa |
| `27` | Permite alterar cartões após registrados na aba Recebimentos | `'S'` → permite edição; `'N'`/ausente → bloqueia (cuidado com lógica invertida) |
| `29` | Desabilita o bloco de `CD_PESSOA_FISICA` | `!this.isParameter(29)` → adiciona blur handler no campo |
| `91` | Define quem pode editar o saldo diário (auditoria) | `'S'` → usuário atual pode editar; caso contrário, verifica permissão por perfil (consulta 122175) |

*(demais seções a preencher conforme cards trabalhados)*

## Dados de Teste

*(a preencher conforme cards trabalhados)*

---

## Integração TPV/TEF (`PayCardWithTef.js`, param 49='T')

> Integração baseada em **troca de arquivos** (não WebSocket como o Banregio), usada por clientes que integram via Monitor Banamex/TIE. Fluxo em `PayCardWithTef.js` (venda), `CancelarPagamentoTefTie.js` (cancelamento), `LotClosingT.js` (devolução no fechamento de lote).

### Mecanismo de troca de arquivos

- Config de pastas vem de `GET_EMPRESA_INTEGR_DADOS` (tabela `EMPRESA_INTEGR_DADOS`, agrupada por `NR_SEQ_EMPRESA_INTEGR` → `EMPRESA_INTEGRACAO.NM_EMPRESA`; para TPV/Banamex o nome é `"Terminal de Punto de Ventas"`).
- O Tasy **escreve** o pedido (`TERMINAL.OUT` + `TERMINAL.FLG`) na pasta de saída (`DS_CAMINHO_SAIDA`) e faz **polling** (a cada ~100ms) na pasta de entrada (`DS_CAMINHO_ENTRADA`) esperando a resposta aparecer.
- **Nunca configurar a mesma pasta para saída e entrada** — o Tasy acaba relendo o próprio pedido como se fosse resposta (erro genérico "formato incorreto", quase instantâneo, sem nunca reamente aguardar o timeout).
- Pode haver **múltiplos registros ativos** (`IE_SITUACAO='A'`) competindo para o mesmo `CD_ESTABELECIMENTO`/grupo de integração — conferir todos antes de assumir qual está valendo.
- Parâmetro **49='T'** habilita o modo TPV; **220** também precisa ser configurado no TasyNative (perfil do Tasy Native, não só do usuário) para as opções de cartão aparecerem no menu "Tarjetas".

### Identificação da bandeira via BIN (não via código Sitef direto)

> **Atenção — formato do retorno confirmado via CCI oficial (TPV-11-06-2026):** o retorno de uma Venda tem **13 campos** separados por `|` (não 12): `status|timestamp|documento|sociedad|episodio|campus|seguimientoOrig|seguimientoResp|autorizacion|monto|mensagem|BIN|últimos4dígitos`. O **BIN** (6 dígitos) e os **últimos 4 dígitos** da tarjeta são **dois campos separados no final**, não um campo único `"BIN*últimos4"` combinado com asterisco — essa suposição (baseada num comentário antigo em `OBTER_DADOS_PAGTO_TEF`) estava **errada** e já foi corrigida em `PayCardWithTef.js` (`handleTefResult` faz `const [..., bin, ultimosDigitos] = campos.split('|')`). Um manual antigo do TPV (Revisão 01) também documentava só 12 campos com o BIN sozinho — **a CCI é a fonte de verdade mais atual**, não o manual antigo.

A resolução da bandeira acontece assim:

1. Frontend chama a query `GET_BANDEIRA_TRANSACAO` (achada via `OBJ_SCHEMATIC_EVENTO` — ver técnica em `plsql-workflow.md`), que executa `OBTER_DADOS_PAGTO_TEF(nr_cartao, ie_tipo_cartao, qt_parcelas, null, cd_estabelecimento, 'SB'|'TFC'|'TFD'|'FP')`, passando o **BIN** (não mais a string combinada) como `nr_cartao`.
2. Essa function pega só os 6 primeiros dígitos (`substr(nr_cartao_p,1,6)`) e chama `OBTER_NUMERO_CARTAO_TEF(bin)`, que traduz o BIN num código numérico via um `CASE` gigante com faixas reais de BIN (ex: `400000-499999` → VISA, `510000-559999`/`222100-272099` → MasterCard, `340000-349999`/`370000-379999` → AMEX).
3. Esse código numérico é comparado via `to_char()` contra `BANDEIRA_CARTAO_CR.CD_SITEF` — **por isso `CD_SITEF` precisa ser um número puro, sem zero à esquerda** (ex: `'18'` funciona, `'05'`/`'00002'` nunca batem, pois `to_char()` de um número nunca gera zeros à esquerda).
4. Depois de achar a bandeira (`nr_seq_bandeira_w`), busca `NR_SEQ_TRANS_TEF_CREDITO`/`DEBITO` primeiro em `BANDEIRA_CARTAO_ESTAB` (override por estabelecimento) e, se nulo, cai para o valor global em `BANDEIRA_CARTAO_CR`.
5. A forma de pagamento (`'FP'`) vem de `OBTER_FORMA_PAGTO_TEF`, que exige uma linha em `FORMA_PAGTO_TEF` para aquela bandeira específica (**sem fallback entre bandeiras**) — `IE_TIPO_CARTAO='A'` funciona como coringa para Crédito/Débito.
6. Depois disso, `FORMA_PAGTO_REGRA` também precisa ter uma linha para a bandeira + forma de pagamento + estabelecimento, senão o insert final falha com *"Não foi possível gerar as parcelas... Verifique o cadastro de regras da forma de pagamento"*.

**Identificação automática de tipo de tarjeta e banco emissor (CCI TPV-11-06-2026, resolvido):** o tipo de tarjeta (Crédito/Débito) e o banco emissor agora são identificados automaticamente a partir do BIN, usando um catálogo fornecido pelo cliente (arquivo `ztfi046.xlsx`, colunas "Prefijo Tarjetas Bancarias"/"Tipo de Producto"/"Emisor (Banco)"). Seguindo o mesmo padrão hardcoded de `OBTER_NUMERO_CARTAO_TEF` (CASE/BETWEEN por faixa de BIN), foram criadas `OBTER_TIPO_PRODUTO_TEF` (retorna `'C'`/`'D'`) e `OBTER_BANCO_EMISSOR_TEF` (retorna o nome do banco), chamadas como colunas adicionais na query `GET_BANDEIRA_TRANSACAO` (`ie_tipo_produto`, `ds_banco_emissor`). O tipo identificado **prevalece sobre a seleção manual do caixa** (fallback só quando o BIN não está no catálogo); o banco emissor é gravado em `DS_OBSERVACAO`; e apenas os **últimos 4 dígitos** (campo separado, não mais a string bruta) são gravados em `NR_CARTAO`.

### Ambiente de teste local (sem terminal TPV físico)

- Não existe mock pronto para TPV (diferente do Banregio, que tem `pinpadService.js`) — criado um mock de arquivo (`emr-tasy-native/modules/tpv-integration/resources/mockTpvService.js`, **não commitado**, uso local apenas) que observa a pasta de saída e responde na pasta de entrada, simulando o terminal. Roda com `node mockTpvService.js [inputDir] [readDir]`; não tem hot-reload, precisa reiniciar o processo após editar. Tem uma constante `CUSTOM_VENDA_RESPONSE` para forçar uma resposta específica (linha única, formato pipe-delimited completo) em vez de ciclar os cenários automáticos.
- Para testar uma bandeira específica sem mexer em bandeiras reais, o mais seguro é criar uma **bandeira de teste isolada** com `CD_SITEF` numérico limpo (ex: `'1'`) e um BIN real da faixa correspondente (ex: `340000` para cair no código AMEX=1), com linhas completas em `BANDEIRA_CARTAO_CR`, `BANDEIRA_CARTAO_ESTAB`, `FORMA_PAGTO_TEF` e `FORMA_PAGTO_REGRA` (copiando os valores de uma bandeira real já completa, como AMEX, como template).

---

## Cards já resolvidos

> Resumos de bugs já corrigidos neste módulo, para localizar cenários semelhantes em cards futuros. Consultar o link do card para a análise completa.

| Card | Função | Resumo |
|---|---|---|
| [755539](https://dev.azure.com/emr-cm/EMR/_workitems/edit/755539) | corFinF2 (PayCardWithTef.js) | CCI TPV-11-06-2026 · tipo de tarjeta (Crédito/Débito) do pagamento TPV era só a seleção manual do caixa, número do cartão gravado sem tratamento e banco emissor nunca registrado · corrigido identificando tipo/banco automaticamente via BIN (novas functions `OBTER_TIPO_PRODUTO_TEF`/`OBTER_BANCO_EMISSOR_TEF`, catálogo `ztfi046.xlsx`) e gravando só os últimos 4 dígitos em `NR_CARTAO` · reproduzir pagando via TPV com um BIN cadastrado no catálogo e conferindo `IE_TIPO_CARTAO`/`NR_CARTAO`/`DS_OBSERVACAO` em `MOVTO_CARTAO_CR` |
