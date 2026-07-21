# Comparação entre Plataformas (HTML5 × Java Swing × Delphi)

> Referência do agente **Tasy HTML5 Developer**. Carregar ao analisar bugs ou implementar funcionalidades no HTML5 que exijam consultar o comportamento equivalente nas plataformas legadas para alinhar a implementação.

O sistema Tasy existe em três plataformas: **HTML5** (atual), **Java Swing** (legado) e **Delphi** (legado).

## Localização dos projetos legados

| Plataforma | Projeto | Caminho base |
|---|---|---|
| Java Swing | `WhebServidorSwing` (backend) | `C:\dev\JAVA SWING\cci-emr-java-swing\` |
| Java Swing | controllers por módulo | ex: `Cor_Man\CorMan_OS\src\br\com\CorMan_OS\` |
| Delphi | `cci-emr-delphi-projetos` | `C:\dev\DELPHI\cci-emr-delphi-projetos\` |
| Delphi | arquivo por módulo | ex: `COR_MAN\CorManF1.pas` |

> O backend Java Swing fica no projeto **`WhebServidorSwing`**. Não confundir com o backend Java do HTML5 (`emr-tasy-backend`), que é um projeto separado.

## Como consultar o Java Swing para comparação

1. **Localizar o módulo:** `C:\dev\JAVA SWING\cci-emr-java-swing\<Modulo>\<Modulo_Funcao>\src\br\com\<Modulo_Funcao>\`
2. **Comportamento de menu (WPUMC):** arquivos `*WPUMC.java` — contêm os handlers dos itens de menu de contexto (equivalentes ao `WPUMC` do HTML5)
3. **Comportamento de formulário/painel:** arquivos `*WJP.java` — contêm eventos do painel como `antesDePerformar` (equivalente ao `onBeforePerform`) e `depoisDePerformar`
4. **Parâmetros de função:** buscar `getParametro(NR_PARAM)` ou `obterParametro(NR_PARAM)` para encontrar onde cada parâmetro é lido

## Como consultar o Delphi para comparação

1. **Localizar o arquivo:** `C:\dev\DELPHI\cci-emr-delphi-projetos\<MOD_NAME>\<ModNome>F1.pas` — cada função tem um único arquivo `.pas` com toda a lógica
2. **Parâmetros de função:** buscar `DMGeral_dm.Lista_Parametros[NR_PARAM]` para ver onde o parâmetro é carregado na inicialização e `Var<NomeParam>` para ver onde é usado nas validações
3. **Equivalente ao `onBeforePerform`:** buscar `BeforePost` ou o evento de antes de gravar do WDBPanel da função
4. **Itens de menu de contexto:** buscar pelo código numérico do menu item (ex: `119721:`) — o Delphi usa uma estrutura `case` com os códigos dos itens
