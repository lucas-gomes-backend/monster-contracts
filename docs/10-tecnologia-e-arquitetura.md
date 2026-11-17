# 10 — Tecnologia e arquitetura

## Objetivo

Escolher as ferramentas e definir **como o código se organiza**, para que um dev solo consiga construir, testar e manter um jogo com muita simulação e geração procedural.

---

## Escolhas principais

| Área | Escolha recomendada | Por quê |
|---|---|---|
| **Motor** | **Godot 4** (versão estável mais recente) | Leve, gratuito e sem royalties, iteração rápida, bom para sistemas orientados a dados, vários shaders PSX de código aberto |
| **Linguagem do jogo** | **GDScript** | Simples e integrada ao editor. Se alguma parte da simulação ficar lenta, só ela é reescrita em C# ou GDExtension (C++) |
| **Ferramentas offline** | **Python** | Importador do mapa de Santos (OpenStreetMap e relevo), validação de dados, scripts de lote |
| **Dados de conteúdo** | **JSON** com validação por esquema | Fácil de editar em massa, de comparar no git e de gerar por script |
| **Controle de versão** | **Git + GitHub**, com **Git LFS** para arquivos binários | Modelos, texturas e áudio não incham o repositório |
| **Testes** | **Executor próprio** em GDScript, em modo headless, com **portão de 95%** e CI no GitHub Actions (ver "Testes e portão de qualidade") | Testar a simulação, o gerador e o solucionador sem abrir o jogo, sem depender de plugins |
| **Plataforma** | **PC** (Windows e Linux) na Steam | Público de jogos de investigação e terror PSX está lá |
| **Controles** | Teclado e mouse, e controle | Terceira pessoa funciona bem nos dois |
| **Idiomas** | **Português (Brasil)** primeiro, **inglês** depois | Sistema de tradução do Godot (arquivos PO ou CSV) desde o começo |

---

## Princípio central: separar a simulação da apresentação

O jogo é dividido em **duas camadas**:

```
┌───────────────────────────────────────────────────────────┐
│  APRESENTAÇÃO (cenas Godot)                               │
│  3D, câmera, animação, shaders PS1, áudio, interface      │
└──────────────▲─────────────────────────────┬──────────────┘
               │ lê o estado / ouve eventos  │ envia ações do jogador
┌──────────────┴─────────────────────────────▼──────────────┐
│  NÚCLEO (código puro, sem cenas)                          │
│  cidade, tempo, NPCs, criaturas, casos, pistas, caderno,  │
│  economia, condições, consequências, legado               │
└───────────────────────────────────────────────────────────┘
```

**O núcleo não depende de nada visual.** Isso permite:

- **Fase 1 só com texto:** o mesmo núcleo roda com uma interface simples de texto e botões, sem 3D ([11](11-roadmap.md)).
- **Testes automáticos:** gerar 100 casos e validar todos em modo headless.
- **Depuração:** ver "a verdade" de um caso sem precisar jogar.
- **Nenhum trabalho jogado fora:** o protótipo da Fase 1 vira a base do jogo final.

---

## O registro de eventos (fonte da verdade)

Tudo o que acontece no mundo vira um **evento** num **registro**:

```
[Dia 3, 00:14] lobisomem_br#07 atacou galinheiro em Rua X, lote 12
[Dia 3, 00:15] npc#231 (Sr. Zé) ouviu barulho, viu vulto grande (distância 20 m, escuro)
[Dia 3, 00:15] marca depositada: pegadas_cao_grande em Rua X, lote 12 (validade: até chover)
```

Desse registro saem:

- **As pistas** (marcas depositadas).
- **As memórias das testemunhas** (quem estava perto de cada evento).
- **Os registros oficiais** (boletins, prontuários, notícias).
- **As cartas** depois do caso.
- **O relatório do caso**, com toda a verdade ([05](05-investigacao-e-deducao.md)).

Como **tudo vem do mesmo registro**, pistas, testemunhos e relatório são sempre coerentes entre si.

---

## Módulos do núcleo

| Módulo | Responsabilidade | Documento |
|---|---|---|
| **Cidade** | Bairros, lotes, pontos-chave, estado do bairro, subterrâneo | [07](07-mundo-cidade-e-npcs.md) |
| **Tempo** | Calendário, dia e noite, lua, marés, clima, datas, pulos de tempo | [13](13-tempo-morte-e-finais.md) |
| **NPCs** | Identidade, rotinas, relações, traços, memórias, simulação por nível de detalhe | [07](07-mundo-cidade-e-npcs.md) |
| **Criaturas** | Fichas, máquina de estados, variação por semente | [03](03-sistema-de-criaturas.md) |
| **Gerador de casos** | Pipeline completo, pré-simulação de 10 dias, ruído, validação | [04](04-geracao-de-casos.md) |
| **Pistas** | Objetos de pista, detecção, validade e expiração | [04](04-geracao-de-casos.md) |
| **Conhecimento** | Caderno, bestiário com níveis de conhecimento, ligações e hipóteses | [05](05-investigacao-e-deducao.md) |
| **Diálogo** | Entrevistas, temas, mentiras, confronto com provas | [05](05-investigacao-e-deducao.md) |
| **Confronto** | Estados da criatura, ferimentos, medo, rituais | [06](06-confronto-e-rituais.md) |
| **Inventário** | Mochila em grade, bolsos, porta-malas, desgaste | [08](08-economia-e-progressao.md) |
| **Economia** | Dinheiro, moedas por espécie, lojas, reputação, suspeita | [08](08-economia-e-progressao.md) |
| **Personagem** | Habilidades, condições, idade, cicatrizes | [12](12-habilidades-e-condicoes.md), [13](13-tempo-morte-e-finais.md) |
| **Consequências** | Cartas, presentes, efeitos nos bairros, casos futuros | [04](04-geracao-de-casos.md) |
| **Legado** | Passagem do carro e do bestiário, mentor | [02](02-loop-de-jogo.md) |

Os módulos conversam por um **barramento de eventos**: um módulo publica ("criatura atacou"), e os interessados reagem (pistas, NPCs, bairro, polícia).

---

## Determinismo e sementes

- O mundo tem uma **semente principal**.
- Cada sistema usa o **seu próprio gerador aleatório**, derivado da semente principal e de um identificador (ex.: semente do mundo + número do caso).
- **Mesma semente gera o mesmo resultado.** Isso é essencial para:
  - Reproduzir bugs ("o caso 4821 travou").
  - Testes automáticos estáveis.
  - Ferramenta de depuração que recria um caso exato.

---

## Simulação e desempenho

### Ritmo da simulação

| Situação | Passo da simulação |
|---|---|
| **Bairro atual** | Contínuo: NPCs andando, criaturas agindo em tempo real |
| **Outros bairros** | Resumido: um passo por hora de jogo, só com eventos importantes |
| **Pré-simulação do caso** (10 dias) | Rápida e resumida, na hora de gerar o caso |
| **Pulo de tempo** | Rápido e resumido: semanas ou meses simulados em segundos |

### Orçamento de desempenho (alvo)

| Item | Alvo |
|---|---|
| Quadros por segundo | 60 em PCs modestos |
| Triângulos na tela | Até ~150 mil (com névoa limitando a distância) |
| NPCs com simulação completa | ~60 por bairro |
| NPCs visíveis animados | ~20 a 30 ao mesmo tempo |
| Tempo de carregamento de um bairro | Poucos segundos |
| Tamanho do jogo instalado | Pequeno (estimativa: menos de 2 GB) |

---

## Pipeline da cidade

```
OFFLINE (Python, uma vez)                   NO JOGO (Godot)
────────────────────────────                ───────────────────────────────────
OpenStreetMap + relevo                      Criação do mundo (semente)
   │                                           │
   ▼                                           ▼
Simplificar, aplicar escala 1:3      ──►   Preencher lotes com módulos da zona
Cortar por bairro                          Gerar subterrâneo seguindo as ruas
Marcar lotes, marcos, canais               Gerar NPCs, casas, rotinas
   │                                           │
   ▼                                           ▼
Arquivos de dados por bairro               Salvar cada bairro gerado em cache
(ruas, lotes, marcos, altura)              Carregar o bairro ao entrar nele
```

Ver [07](07-mundo-cidade-e-npcs.md).

---

## Renderização PS1

- **Resolução interna baixa:** o jogo é desenhado num *viewport* pequeno (ex.: 320×240 ou 640×480) e ampliado sem suavização.
- **Shaders:** *vertex snapping*, mapeamento de textura afim, *dithering*, névoa, iluminação por vértice.
- **Pós-processamento opcional:** CRT, scanlines, ruído.
- **Todos os efeitos com opção de reduzir ou desligar** (acessibilidade) ([09](09-direcao-de-arte-camera-e-personagem.md)).

## Personagens

- **Esqueleto único** para todos os humanos.
- **Sliders** com *blend shapes* e escala de ossos.
- **Roupas** como malhas modulares, **variação de cor** por troca de paleta.
- **O mesmo gerador** cria o jogador e os NPCs ([09](09-direcao-de-arte-camera-e-personagem.md)).

---

## Salvamento

| Arquivo | Conteúdo |
|---|---|
| **Mundo** | Semente, cidade gerada, estado dos bairros, NPCs, registro de eventos resumido |
| **Carreira** | Personagem, inventário, carro, base, dinheiro, reputação, caso atual |
| **Legado** | Histórico de carreiras, carro e bestiário herdados, caçador aposentado (mentor) |

- O jogo salva no **motel, no carro ou na base** ([09](09-direcao-de-arte-camera-e-personagem.md)).
- **Morte definitiva** encerra o arquivo de carreira, mas o **mundo** e o **legado** continuam.
- Arquivos com **número de versão**, para atualizar saves antigos quando o jogo mudar.

---

## Ferramentas de desenvolvimento

| Ferramenta | Para que serve |
|---|---|
| **Visão da verdade** | Mostra a criatura, o culpado, todas as pistas e a origem de cada uma |
| **Gerador em lote** | Gera centenas de casos e mostra estatísticas (quantos passam na validação, distribuição de criaturas e estruturas) |
| **Solucionador** | Joga o caso automaticamente para verificar se é justo ([04](04-geracao-de-casos.md)) |
| **Teste da matriz de distinção** | Verifica se as criaturas de cada tipo de bairro são distinguíveis ([03](03-sistema-de-criaturas.md)) |
| **Validador de dados** | Confere todas as fichas de criaturas, itens e bairros contra o esquema |
| **Importador do mapa** | OpenStreetMap e relevo para arquivos de bairro ([07](07-mundo-cidade-e-npcs.md)) |
| **Console de depuração** | Pular tempo, teleportar, gerar caso por semente, mudar valores |

---

## Testes e portão de qualidade

O projeto tem um **executor de testes próprio**, sem plugins, que roda o Godot em modo headless.

### Estrutura

```
game/tests/
├── framework/test_case.gd   # base dos testes: asserções, skip(), record_metric()
├── run_tests.gd             # executor com o portão
├── unit/                    # testes de unidade (test_*.gd)
└── gates/                   # testes de portão por fase (ex.: gerador de casos)
```

- Cada arquivo `test_*.gd` estende `test_case.gd`. Cada método `test_*` é um teste, executado numa instância nova.
- `skip("motivo")` marca testes de sistemas que ainda não existem. **Pulados não contam** no portão.
- `record_metric("nome", taxa)` registra uma taxa de 0 a 1, como a fração de casos gerados que passam na validação.

### O portão de 95%

A suíte só passa se todas as regras valerem:

1. **Pelo menos 95%** dos testes executados passam.
2. **Toda métrica** registrada fica em pelo menos 95%.
3. **Pelo menos um** teste foi executado.
4. **Testes obrigatórios não falham nenhuma vez:** tudo em `tests/arch/` (regras do núcleo) e todo arquivo com `const OBRIGATORIO := true` (como o determinismo do RNG).
5. **Nenhum erro de script ou de parse** aparece no log.

Se alguma regra falhar, o processo sai com código 1, e o CI fica vermelho. Um relatório em JSON é salvo em `user://test_report.json`.

### Portão único e regras de qualidade

Inspirado nas regras de qualidade do projeto [LivingWorld](https://github.com/AlanEdward19/LivingWorld):

- **`tools/verify.ps1`** é o portão único: confere o tamanho dos arquivos de regras (até 100 linhas) e roda os testes. Precisa sair 0 antes de qualquer commit.
- **`tools/verify-mutation.ps1`** prova que o portão reprova de verdade: cria falhas de propósito (teste quebrado, `randi()` no núcleo, núcleo dependendo de cena, erro de parse, métrica baixa, regra longa demais) e exige que o portão fique vermelho em todas.
- **Regras do núcleo verificadas por teste** (`tests/arch/`): nada de aleatoriedade sem semente, relógio da máquina, nós, cenas ou referências à apresentação dentro de `game/core/`.
- **`game/core/rng.gd`** é a única fonte de aleatoriedade, com streams independentes por nome. Os valores de referência em `tests/baselines/rng.json` são conferidos no CI (Linux), o que garante o mesmo resultado em Windows e Linux.
- **`AGENTS.md` e `rules/`** guardam as regras para agentes de código, lidas sob demanda.

### Como rodar

- **Portão completo:** `.\tools\verify.ps1`
- **Só os testes:** `.\tools\run_tests.ps1` (aceita `-Gate 0.95` e `-Filter nome`).
- **No GitHub:** o workflow `.github/workflows/testes.yml` roda o `verify.ps1` em todo push na `main` e em todo pull request.

### Limitação conhecida

O GDScript não tem `try/catch`. Um erro de execução dentro de um teste aparece no log como `SCRIPT ERROR`, e o `run_tests.ps1` reprova a suíte quando encontra essa marca.

---

## Estrutura de pastas

```
monster-contracts/
├── AGENTS.md, CLAUDE.md   # índice para agentes de código
├── rules/                 # regras verificáveis (testes, determinismo, critérios, implementação)
├── docs/                  # documentação de design
├── tools/                 # portão (verify.ps1), testes, mutação; ferramentas em Python
├── artifacts/             # código da página do Diário do Caçador
├── game/                  # projeto Godot
│   ├── data/              # conteúdo em JSON (dentro do projeto, para o Godot ler por res://)
│   │   ├── creatures/     # fichas de criaturas
│   │   ├── neighborhoods/ # bairros importados de Santos
│   │   ├── items/         # armas, equipamentos, roupas
│   │   ├── rituals/       # rituais e testes de campo
│   │   └── schemas/       # esquemas de validação
│   ├── core/              # NÚCLEO: simulação, sem cenas (rng, dados, criaturas…)
│   ├── presentation/      # cenas 3D, câmera, personagens, shaders
│   ├── ui/                # caderno, menus, mochila
│   ├── assets/            # modelos, texturas, áudio (Git LFS)
│   └── tests/             # framework, executor, testes (unit/, arch/, gates/) e baselines/
└── README.md
```

A pasta `data/` fica **dentro** de `game/` porque o Godot só lê arquivos do próprio projeto (`res://`). Ao exportar o jogo, incluir `*.json` no filtro de exportação.

---

## Decisões

- **Motor:** Godot 4.
- **Linguagem:** GDScript. Partes lentas podem ir para C# ou GDExtension depois, se for preciso.
- **Conteúdo:** JSON com validação por esquema.

## Questões em aberto

- O GitHub tem limite de armazenamento para **Git LFS** no plano gratuito. Avaliar o espaço necessário quando os assets começarem a entrar.
