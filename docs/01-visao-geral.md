# 01 — Visão geral e pilares

## Premissa

Você é um caçador que aceita contratos para resolver casos sobrenaturais. Cada caso é gerado a partir de uma criatura simulada agindo no mundo: ela tem hábitos, necessidades e fraquezas, e deixa rastros. Seu trabalho é investigar, deduzir **o que** está agindo, **por que**, e decidir **o que fazer** a respeito.

## Definições do projeto

- **Perspectiva:** 3D, terceira pessoa.
- **Estética:** PlayStation 1 (poucos polígonos, texturas tremidas, névoa). Ver [09 — Direção de arte](09-direcao-de-arte-camera-e-personagem.md).
- **Personagem:** customizável, e a aparência muda com a idade, as cicatrizes e a condição.
- **Mundo:** **uma única cidade** procedural, dividida em **bairros**. O tipo de bairro define as criaturas que vivem nele. Ver [07 — Mundo](07-mundo-cidade-e-npcs.md).
  - **Ambientação:** uma grande cidade fictícia brasileira com **comunidades de imigrantes** (japonesa, árabe, europeia, entre outras). Isso explica, dentro do mundo, por que criaturas do folclore do mundo inteiro aparecem na mesma cidade. Cada comunidade traz o próprio folclore, datas e rádios.
- **Jogadores:** single-player.
- **Tom:** meio-termo entre terror e aventura — tensão real, com espaço para humor e personagens.
- **Equipe:** desenvolvedor solo.

## Pilares

1. **O monstro é uma simulação, não um roteiro.** Cada criatura é um conjunto de regras (gatilho, alimentação, habitat, marcas, disfarce, fraquezas). O caso nasce do rastro que essa simulação deixa no mundo.
2. **Dedução justa.** Todo caso é resolvível só com as pistas disponíveis. Errar é culpa do raciocínio, não da sorte.
3. **Preparação vence força.** O confronto é um clímax ritual; identificar errado custa caro.
4. **Folclore do mundo inteiro, tratado com respeito.** Criaturas de várias culturas — com destaque para o folclore brasileiro — pesquisadas e apresentadas com cuidado.
5. **Cinza moral.** Nem todo monstro deve morrer; nem todo cliente diz a verdade; às vezes o culpado é humano.
6. **Sensação de evolução.** De caçador improvisado a profissional respeitado: economia, armas, equipamentos, veículo, roupas e base evoluem — ampliando opções, nunca substituindo o raciocínio. Ver [08 — Economia e progressão](08-economia-e-progressao.md).

## Diferenciais

- Falsos positivos: golpes humanos, criaturas parecidas, clientes mentirosos.
- Contratos de negociação, proteção e expulsão — não apenas de caça.
- Bairros com identidade: o tipo de bairro define as criaturas, e variantes culturais da mesma ameaça (lobisomem brasileiro e europeu) são espécies diferentes, com regras diferentes.
- Condições paranormais: o caçador pode virar o que caça (vampiro, lobisomem, pacto) — com poderes, fraquezas, estigma social e outros caçadores investigando **você** com o mesmo sistema de casos.
- Carreira com fim: o tempo passa, o caçador envelhece e o jogo termina na **aposentadoria**, com epílogo montado a partir da carreira. Morrer leva ao **limbo**, onde as criaturas que você matou voltam em hordas.

## Fora do escopo (por enquanto)

- Multiplayer / co-op.
- Combate complexo durante os casos (o confronto é um clímax ritual). O **limbo** é a exceção: um modo próprio com combate físico, planejado para depois do corte vertical.
- Geometria de mundo 100% procedural (usaremos módulos feitos à mão combinados proceduralmente).
