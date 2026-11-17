# rules/determinismo.md — lida ao mexer em simulação, sorteio ou tempo

**Regra do projeto:** mesma semente do mundo + mesmas ações = mesmo resultado, em qualquer
máquina. Sem isso não existe caso reproduzível, teste estável nem bug que dá para corrigir.

## Aleatoriedade

- A única fonte é `game/core/rng.gd`. Cada sistema pede um **stream com nome próprio**:
  `rng.stream("criaturas")`, `rng.stream("npc:231")`, `rng.stream("caso:%d" % id)`.
- Streams são independentes: criar ou consumir um não muda os outros. Por isso,
  adicionar um sistema novo não altera os sorteios dos sistemas antigos.
- Proibido no núcleo (o teste `tests/arch/` reprova):
  `randi()`, `randf()`, `randi_range()`, `randf_range()`, `randfn()`, `randomize()`, `seed()`,
  e `RandomNumberGenerator.new()` fora de `core/rng.gd`.

## Tempo

- O tempo vem do **relógio do mundo** (calendário do jogo), nunca do relógio da máquina.
- Proibido no núcleo: `Time.get_*` e `OS.get_unix_time/ticks/...`.

## Ordem

- Toda iteração que produz efeito no mundo segue uma **ordem estável**: ordene por id
  antes de percorrer. Não dependa da ordem de chegada de dados externos.
- Nada de threads na simulação, a menos que um teste prove que a ordem não muda o resultado.

## Números

- Dinheiro, estoques e contagens são **inteiros**, nunca `float`.
- Evite somar `float` em ordem variável. Prefira acumular inteiros.

## Registro de eventos

- Todo evento que muda o mundo vai para o registro de eventos com o momento em que ocorreu
  (`docs/10-tecnologia-e-arquitetura.md`). Pistas, testemunhos e relatório saem dele.

## Teste obrigatório de todo sistema novo

```
mesma semente  -> mesmo resultado (ou mesmo hash do estado)
semente diferente -> resultado diferente   (sem este, o primeiro não prova nada)
desligar o sistema -> o hash do mundo muda (prova que ele entrou na conta)
```

## Referência entre plataformas

- `game/tests/baselines/rng.json` guarda os valores do RNG gerados no Windows.
  O CI (Linux) confere os mesmos valores. Se divergir, o determinismo quebrou entre máquinas.
