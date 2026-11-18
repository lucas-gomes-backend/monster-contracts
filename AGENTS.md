# AGENTS.md — Monster Contracts

> Índice para agentes de código. **Não é manual.** As regras detalhadas ficam em `rules/`
> e são lidas sob demanda. `docs/` é o design para humanos: referencie, não copie.

## Limites (prioridade máxima)

**SEMPRE**
- **Leia só o necessário.** Use a tabela "Referência rápida" e abra apenas o arquivo da tarefa.
- Antes de dizer "pronto" ou de commitar: `.\tools\verify.ps1` precisa sair 0.
  Quem decide se está pronto é o portão, não quem escreveu o código.
- Toda aleatoriedade do núcleo vem de `game/core/rng.gd`. Ver `rules/determinismo.md`.
- Conteúdo é dado: criaturas, itens, bairros e rituais em `game/data/` (JSON), nunca fixos no código.
- Arquivos de `rules/`, `AGENTS.md` e `CLAUDE.md`: no máximo 100 linhas.
- Escreva docs e mensagens em português do Brasil.
- Atualize o Diário do Caçador (roadmap interativo) a cada decisão nova e a cada tarefa concluída.

**PERGUNTE ANTES**
- Mudar o escopo ou a ordem de uma fase do `docs/11-roadmap.md`.
- Adicionar dependência nova (plugin, biblioteca, ferramenta).
- Mudar o formato de dados de conteúdo ou de save.
- Mudar valores em `game/tests/baselines/` (muda os mundos já gerados).

**NUNCA**
- `randi()`, `randf()`, `randomize()`, `RandomNumberGenerator.new()` fora de `core/rng.gd`,
  ou `Time.get_*` dentro de `game/core/`.
- Fazer o núcleo (`game/core/`) depender de nós, cenas, `presentation/` ou `ui/`.
- Commitar com o portão vermelho, ou "consertar" o portão para ele passar.
- Escrever teste que passaria com o código apagado.

## Projeto

- **O que é:** jogo 3D em terceira pessoa, estética PS1, de investigação sobrenatural em Santos (SP).
  Casos procedurais nascem da simulação de criaturas e NPCs.
- **Stack:** Godot 4.7 + GDScript, conteúdo em JSON, ferramentas em Python.
- **Arquitetura:** núcleo de simulação puro (`game/core/`) separado da apresentação
  (`game/presentation/`, `game/ui/`). Registro de eventos é a fonte da verdade.

## Comandos

| Preciso… | Rode |
|---|---|
| Portão completo | `.\tools\verify.ps1` |
| Só os testes | `.\tools\run_tests.ps1 [-Filter nome]` |
| Provar que o portão reprova | `.\tools\verify-mutation.ps1` |
| Jogar um caso em texto | `.\tools\jogar.ps1 -Semente 7 [-Comandos roteiro.txt]` |
| Estatísticas do gerador de casos | `.\tools\lote.ps1 [-Casos 500]` |
| Gerador mudou de propósito | `.\tools\lote.ps1 -AtualizarReferencia` (e explique no commit) |
| Abrir o editor | `godot --path game --editor` |
| Reimportar os bairros do mapa real | `python tools/cidade/importar.py` (baixar de novo: `baixar.py`) |
| Andar num bairro do mapa real | `.	oolsairro.ps1 -Bairro valongo [-Semente 3]` |

## Referência rápida: abra só a linha da tarefa

| Tarefa | Leia |
|---|---|
| Escrever ou ajustar testes | `rules/testes.md` |
| Sistema de simulação, sorteio, tempo | `rules/determinismo.md` |
| Critério ou portão de uma fase | `rules/criterios-de-fase.md` |
| Nova funcionalidade, commits | `rules/implementacao.md` |
| O que fazer agora | `docs/11-roadmap.md` (fase atual) |
| Entender um sistema do jogo | `docs/README.md` (índice) → a parte certa |
| Formato de um caso gerado | `docs/casos/caso-01-o-bicho-do-paqueta.md` |
| Folclore de uma criatura | `docs/pesquisa/` |

## Mapa de arquivos

| Caminho | Papel |
|---|---|
| `AGENTS.md`, `CLAUDE.md` | Índice para agentes |
| `rules/*.md` | Regras verificáveis, lidas sob demanda |
| `tools/*.ps1` | Comandos repetíveis (portão, testes, mutação) |
| `docs/` | Design do jogo (humanos) |
| `game/data/` | Conteúdo em JSON (criaturas, esquemas) |
| `game/core/` | Núcleo de simulação (sem nós, sem cenas) |
| `game/tests/` | Framework, executor, testes e referências (`baselines/`) |
| `artifacts/` | Código da página do Diário do Caçador |
