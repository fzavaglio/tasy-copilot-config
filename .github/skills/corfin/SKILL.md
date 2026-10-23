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
| corFinF3 | 814 | Controle Bancário (no Java Swing, actions em `CorFin_F3`). Lançamentos manuais da aba Transações validados no backend por `TransactionsGenericAction` (chamado no beforePost de `MovtoTransFinancDBPDBPAction`) |
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

### corFinF3 — Campos da transação e atributos de descrição

- Os campos exibidos num lançamento do Controle Bancário vêm de `TRANS_FINANC_CAMPO` (função "Cadastro de Transações Financeiras", 1120 > aba "Campos da transação"). O combo "Campo" só lista atributos de `MOVTO_TRANS_FINANC` editáveis (`ie_readonly <> 'S'`), então atributos gerados pelo sistema (ex: `NM_PESSOA_CONTA`, `NM_PESSOA_TITULO_RECEBER`) **não podem ser configurados**.
- Na visão 77814 esses `NM_PESSOA_*`/`DS_*` são atributos de descrição (`ie_componente = 'de'`, `nm_atributo_pai` = campo FK, sem grupo). No Java aparecem como descrição do campo pai; no HTML5 o texto ao lado do campo vem do **localizador** e o atributo calculado **não entra no registro** enviado ao backend.
- Correção do card 775128: o frontend envia o nome exibido ao lado de "Conta paciente" como parâmetro adicional `NM_PESSOA_CONTA` (só quando o campo está visível) e a validação da mensagem 108592 ("A conta é inválida, informe novamente!") lê desse parâmetro.

### corFinF3 — Importação de extrato bancário (aba Extrato > opção de mouse "Importar extrato")

- A interface usada é cadastrada por conta em Cadastros Financeiros > Banco > Estabelecimento > Interface (`BANCO_ESTAB_INTERF`, tipo `CB`): interface + tabela (`NM_TABELA`) + procedure (`DS_OBJETO`). A interface padrão é a **1498 - Extrato Banco - Procedure(Padrão)**, que copia a linha inteira do arquivo para `W_INTERF_CONCIL.DS_CONTEUDO` (chave `NR_SEQ_CONTA` = conta bancária).
- No HTML5, se a interface escolhida não tiver tabela **e** procedure, a importação é bloqueada (mensagem 359241). Depois de gravar as linhas na tabela, o backend chama a procedure passando **somente** `NR_SEQ_EXTRATO_P` e, por fim, grava a data de importação no extrato. Por isso toda procedure de importação tem a assinatura `(nr_seq_extrato_p number)`, lê a conta do extrato, interpreta `W_INTERF_CONCIL` e apaga as linhas da conta ao final.
- O Delphi tinha um modo antigo (sem tabela/procedure no cadastro do banco) que lia os campos pelo cadastro de atributos da interface: histórico = `BANCO.CD_SALDO_ANTERIOR` (1ª ocorrência) atualiza data/saldo inicial; histórico = `BANCO.CD_SALDO_FINAL` atualiza data/saldo final; demais linhas D/C viram lançamentos; se `BANCO.IE_IMP_EXTRATO_DUP <> 'S'` e já existe lançamento com mesmo documento/valor/data/D-C (em qualquer conta), a linha não entra e o valor é somado ao saldo inicial. Sem os códigos de saldo no banco, aborta com a mensagem 110491. Esse modo **não existe no HTML5** — a migração é feita criando uma procedure para a interface 1498 (ex: `IMPORTA_EXTRATO_BRASIL_SEPARADOR`, card 776352).
- Arquivos com separador `;` são lidos com `obter_valor_campo_separador(ds_conteudo, <posição>, ';')`.

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

> Resumos de cards já atuados neste módulo (bugs corrigidos, orientações e configurações), para localizar cenários semelhantes em cards futuros. Consultar o link do card para a análise completa.

| Card | Função | Resumo |
|---|---|---|
| [776352](https://dev.azure.com/emr-cm/EMR/_workitems/edit/776352) | corFinF3 (importação de extrato, interface 1498) | User Story · cliente importava no Delphi extrato com campos separados por `;` pelo modo antigo baseado nos atributos da interface (1041), inexistente no HTML5 · criada a procedure padrão `IMPORTA_EXTRATO_BRASIL_SEPARADOR` (tasyfin, disponível para todos os clientes), vinculada à interface 1498 na conta bancária, que lê `W_INTERF_CONCIL` por posição do separador e reproduz a regra do Delphi (saldo anterior/final pelos códigos do banco, duplicidade por `IE_IMP_EXTRATO_DUP`, abort 110491 sem códigos) · reproduzir na base Financial cadastrando a interface na conta 173 (banco 25, códigos 000/999) e importando o arquivo anexado ao card |
| [775128](https://dev.azure.com/emr-cm/EMR/_workitems/edit/775128) | corFinF3 (MovtoTransFinancDBPanel.js / TransactionsGenericAction) | Bug · Lançamento com conta paciente bloqueado no HTML5 com "A conta é inválida, informe novamente!" (msg 108592) para qualquer conta · a validação lia `NM_PESSOA_CONTA` (atributo calculado de descrição) do registro, que nunca chega à action no HTML5 · corrigido enviando o nome exibido ao lado de "Conta paciente" como parâmetro adicional `NM_PESSOA_CONTA` (só com o campo visível) e lendo dele na validação · reproduzir na base Financial com a transação 4360 (campo Conta paciente) + conta 1428094 na conta bancária seq 11 |
| [755539](https://dev.azure.com/emr-cm/EMR/_workitems/edit/755539) | corFinF2 (PayCardWithTef.js) | CCI TPV-11-06-2026 · tipo de tarjeta (Crédito/Débito) do pagamento TPV era só a seleção manual do caixa, número do cartão gravado sem tratamento e banco emissor nunca registrado · corrigido identificando tipo/banco automaticamente via BIN (novas functions `OBTER_TIPO_PRODUTO_TEF`/`OBTER_BANCO_EMISSOR_TEF`, catálogo `ztfi046.xlsx`) e gravando só os últimos 4 dígitos em `NR_CARTAO` · reproduzir pagando via TPV com um BIN cadastrado no catálogo e conferindo `IE_TIPO_CARTAO`/`NR_CARTAO`/`DS_OBSERVACAO` em `MOVTO_CARTAO_CR` |
