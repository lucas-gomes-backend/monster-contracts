# rules/testes.md — lida ao escrever ou ajustar testes

Quem decide "pronto" é o portão (`.\tools\verify.ps1`), não quem escreveu o código.

## Regras

- Todo comportamento novo ou alterado entra com teste, na mesma tarefa.
- Nome descreve o comportamento: `test_<unidade>_<condição>_<resultado>`.
  Ex.: `test_rng_sementes_diferentes_geram_sequencias_diferentes`.
- Uma ideia por teste. Vários asserts só quando conferem a mesma ideia.
- Bug corrigido entra com teste de regressão que **falha sem a correção**. Prove rodando antes.
- Sem relógio da máquina, sem rede, sem espera real. Use o relógio e o RNG do mundo.
- Rode sempre pelos scripts de `tools/`. Não monte comandos do Godot à mão.

## Onde cada teste fica

| Pasta | O que cobre | Custo |
|---|---|---|
| `game/tests/unit/` | Uma regra isolada (RNG, ficha, pista, preço) | barato |
| `game/tests/arch/` | Regras de arquitetura do núcleo (símbolos proibidos, dependências) | barato |
| `game/tests/gates/` | Portões de fase (ex.: 95% dos casos gerados válidos) | médio |

## Framework (`game/tests/framework/test_case.gd`)

- Arquivo `test_*.gd` estende o `test_case.gd`; cada método `test_*` roda numa instância nova.
- Asserções: `assert_true/false/eq/ne/almost_eq/gte/has`, `fail()`.
- `skip("motivo")` para sistema que ainda não existe. Pulado não conta no portão.
- `record_metric("nome", taxa)` registra uma taxa de 0 a 1 que precisa ficar no portão.
- `assert_eq` compara tipo também: `1` e `1.0` são diferentes.
- **Todo teste precisa passar (100%).** Nenhuma falha é tolerada.
- O **portão de 95%** vale só para **métricas** (`record_metric`), como a fração de casos
  gerados válidos, que varia de semente para semente.

## Testes de propriedade (gerador de casos, simulação)

Não teste valor exato ("o caso tem 11 pistas"). Teste o que precisa valer sempre:

```
para 100 sementes:
  todo caso tem 2 caminhos independentes para "o quê", "quem" e "por quê"
  toda pista aponta para um evento real do registro
  nenhuma pista de ruído completa a assinatura de outra espécie
  toda mentira contradiz pelo menos um fato verificável
```

Valor exato muda a cada ajuste de regra e só gera teste que reclama à toa.

## Referências (`game/tests/baselines/`)

- Valores de referência (golden) ficam em JSON, não soltos no teste.
- Inteiros acima de 2^53 vão como texto no JSON (perdem precisão como número).
- Mudar uma referência exige commit explícito explicando o motivo.

## O portão reprova de verdade

- Erros de script ou de parse no log reprovam a suíte (`tools/run_tests.ps1`).
- Mudou o portão ou uma regra? Rode `.\tools\verify-mutation.ps1`: todos os mutantes
  precisam ser "mortos" (o portão precisa falhar em cada um).

## Nunca

- Teste que passaria com o código apagado (`assert_true(true)` disfarçado).
- Afrouxar o portão ou pular um teste para "fazer passar".
