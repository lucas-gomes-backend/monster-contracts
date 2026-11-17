# rules/criterios-de-fase.md — lida ao escrever ou revisar o portão de uma fase

Um critério de fase é um **teste que roda no CI e pode falhar**. Se não roda nem pode falhar,
é opinião, não critério. Os portões de fase ficam em `game/tests/gates/`.

## C1 — Não teste o que o tipo já garante

Se a estrutura de dados já impede o estado, o teste é da estrutura, não da fase.
O critério testa a **ação rejeitada**: a operação inválida falha **e** o mundo não muda.
> Ruim: "nenhum dinheiro negativo". Bom: "gastar além do saldo falha e o hash do mundo não muda".

## C2 — Invariante a cada passo, em horizonte curto

Conferir só no fim é lento e acha o erro tarde. No portão: horizonte curto (ex.: 30 dias de
jogo), com o invariante checado **a cada passo**. Horizontes longos ficam fora do portão diário.

## C3 — Nada de número mágico (com uma exceção decidida)

- Limiares vêm de **parâmetros do jogo** ou de **referências medidas** em `game/tests/baselines/`
  a partir de **20 sementes**, atualizadas só por commit explícito.
- **Exceção decidida (produto):** o portão de **95%** (testes aprovados e métricas como
  "casos válidos") é uma decisão do projeto, não um número mágico.
> Ruim: "o caso tem em média 11 pistas". Bom: "a média de pistas fica dentro da faixa
> medida nas 20 sementes de referência".

## C4 — Efeito causal exige grupo de controle

Para provar que um sistema **causa** algo, rode pares base/tratamento **com a mesma semente**,
em 10 ou mais sementes, e conte acertos (10/10, 18/20). Afirme a direção, não o tamanho.
> Ex.: "com chuva, pegadas expiram antes do que sem chuva, em 20/20 sementes".

## C5 — Zero ação humana

"Revisar o código", "abrir o jogo e conferir" não rodam no CI. Transforme em teste:
varredura de código (como `tests/arch/`), comparação com referência, enumeração que
**falha se algum item ficar de fora** (ex.: toda criatura tem ficha válida).

## Mutação para portões de proteção

Critério que protege uma regra (determinismo, validação de caso, separação núcleo/visual)
precisa de um mutante em `tools/verify-mutation.ps1` que desliga a proteção e exige que o
portão **falhe**. Se não falhar, o critério não media nada.

## Checklist antes de escrever o critério de uma fase

- [ ] cada item pode falhar
- [ ] nenhum número sem origem (parâmetro, referência ou a decisão dos 95%)
- [ ] efeito causal tem grupo de controle
- [ ] nada depende de pessoa
- [ ] horizonte curto no portão
- [ ] o que o tipo já garante ficou de fora
