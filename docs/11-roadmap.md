# 11 — Roadmap

## Objetivo

Transformar tudo o que foi decidido nas outras partes em **fases realistas para um dev solo**, com **portões de decisão** entre elas: momentos em que o projeto é avaliado antes de investir mais.

## Princípios

1. **O coração primeiro.** Simulação, casos e dedução vêm antes de arte, cidade bonita e sistemas de progressão.
2. **Provar que é divertido antes de crescer.** Cada fase termina com um teste concreto. Se não passar, ajusta antes de seguir.
3. **Nenhum trabalho jogado fora.** O núcleo da Fase 1 é o mesmo do jogo final ([10](10-tecnologia-e-arquitetura.md)).
4. **Arte por último.** Até o corte vertical, tudo é cinza com o shader PS1.
5. **Mostrar cedo.** A página na Steam entra logo depois do corte vertical.

## Acompanhamento

O progresso do roadmap é acompanhado no **Diário do Caçador**, uma página com as fases, as tarefas para riscar e as anotações de cada avanço: <https://claude.ai/artifact/BvVCtFK57qGZSTRzpKa3Qi> (privada). O código da página fica em `artifacts/diario-do-cacador.html`. A página é atualizada a cada nova decisão de design e a cada tarefa ou fase concluída.

## Sobre as estimativas

- As durações supõem **meio período** (cerca de 20 horas por semana). Em tempo integral, o prazo cai para perto da metade.
- São **estimativas de planejamento**, não promessas. Devem ser revisadas a cada portão.

---

## Visão geral

| Fase | Nome | Duração (meio período) | Portão |
|---|---|---|---|
| 0 | Pré-produção | 2 a 4 semanas | Projeto montado e caso escrito à mão |
| 1 | Núcleo em texto | 2 a 3 meses | **Os casos gerados são divertidos em texto?** |
| 2 | Greybox 3D | 2 meses | Um caso completo jogável em 3D cinza |
| 3 | Ferramenta da cidade | 1 a 2 meses | 2 bairros de Santos gerados a partir do mapa |
| 4 | Corte vertical | 4 a 6 meses | **Playtest externo aprova; página na Steam** |
| 5 | Conteúdo | 6 a 9 meses | Cidade e bestiário principais prontos |
| 6 | Meta-jogo | 4 a 6 meses | Uma carreira completa de 10 h jogável |
| 7 | Limbo | 2 a 3 meses | Morte e limbo completos |
| 8 | Polimento e lançamento | 4 a 6 meses | Lançamento |

**Total estimado: cerca de 3 a 4 anos em meio período**, ou perto de 2 anos em tempo integral. O escopo cresceu bastante durante o design, e os cortes possíveis estão listados mais abaixo.

---

## Fase 0 — Pré-produção (2 a 4 semanas)

- [x] Documentação de design (partes 01 a 13).
- [x] Criar o projeto Godot 4 e a estrutura de pastas ([10](10-tecnologia-e-arquitetura.md)).
- [x] Configurar o Git LFS.
- [x] Escrever **um caso completo à mão** (verdade, pistas, testemunhas, desfecho). Ele vira o gabarito do gerador.
- [x] Pesquisar o folclore das criaturas do corte vertical (lobisomem brasileiro, Curupira, corpo-seco ou mula sem cabeça).
- [x] Verificar se os dados do OpenStreetMap de Santos estão completos ([07](07-mundo-cidade-e-npcs.md)).
- [x] Estrutura de testes com **portão de 95%** e CI no GitHub Actions ([10](10-tecnologia-e-arquitetura.md)).

**Portão:** projeto criado, caso escrito à mão e dados do mapa verificados.

---

## Fase 1 — Núcleo em texto (2 a 3 meses)

O teste de fogo: **o jogo inteiro sem 3D**, só com texto e botões.

- [x] Esquemas de dados e validador.
- [x] Fichas de 3 a 4 criaturas e do golpe humano ([03](03-sistema-de-criaturas.md)).
- [x] Tempo: calendário, dia e noite, lua.
- [x] Um bairro abstrato com locais e cerca de 30 NPCs com rotinas, traços e memórias.
- [x] Registro de eventos e barramento de eventos.
- [x] Máquina de estados das criaturas.
- [x] Gerador de casos com pré-simulação de 10 dias, ruído e validade das pistas ([04](04-geracao-de-casos.md)).
- [x] Testemunhas com filtro de percepção e mentiras.
- [x] Solucionador automático e matriz de distinção.
- [x] Gerador em lote com estatísticas.
- [x] Caderno em texto: pistas, pessoas, hipóteses (ligar pistas a características).
- [x] Entrevistas e confronto com provas.
- [x] Testes de campo e confronto **resolvidos por regras**.
- [x] Relatório do caso.
- [x] Janela clicável da investigação (retorno de playtest: comandos no terminal eram cansativos).

**Portão (o mais importante do projeto):**
- O gerador produz 100 casos e **pelo menos 95%** passam na validação (teste de portão em `game/tests/gates/`).
- A suíte de testes passa no portão do CI: **100% dos testes** e **métricas em pelo menos 95%**.
- Jogar 10 casos em texto é **divertido**: dá vontade de jogar o próximo.
- **Se não for divertido**, o problema está no coração do jogo. Ajustar aqui é barato; depois fica caríssimo.

**Resultado (18/11/2026): portão APROVADO.** 100% dos 100 casos gerados são justos, o CI exige 100% dos testes, e o playtest foi divertido. Retorno do playtest: digitar comandos no terminal era cansativo, o que levou à janela clicável ainda na Fase 1.

---

## Fase 2 — Greybox 3D (2 meses)

- [x] Personagem em terceira pessoa, câmera por cima do ombro.
- [x] **Shader PS1** desde já ([09](09-direcao-de-arte-camera-e-personagem.md)).
- [x] Modo de inspeção, lanterna, fotografar, pegar e girar objetos.
- [x] Interface de diálogo.
- [x] Caderno com **arrastar e soltar**.
- [x] Uma rua, uma casa e um trecho de esgoto em módulos cinza (`tools/greybox.ps1`).
- [x] Ligar o núcleo às cenas: as pistas do caso aparecem no lugar certo (mapa do bairro, tecla M).

**Portão:** um caso gerado, jogado do contrato ao relatório, em 3D cinza.

**Resultado (17/11/2026): portão APROVADO.** O playtest jogou um caso do contrato ao relatório em 3D cinza, e um jogador automático resolve 3 casos só pela cena (`tests/gates/test_gate_caso_em_3d.gd`). Retornos do playtest que viraram correções: o caçador não subia no meio-fio (subida de degrau, com teste de física de verdade). Decisão: a prova de mutação inteira reiniciava o PC; agora roda só os mutantes novos, em lotes com pausa.

---

## Fase 3 — Ferramenta da cidade (1 a 2 meses)

Pode ser feita **em paralelo** com o fim da Fase 2.

- [ ] Importador em Python: OpenStreetMap e relevo, simplificação, escala 1:3, corte por bairro ([07](07-mundo-cidade-e-npcs.md)). *(ruas, limites, marcos e saídas prontos para Valongo e Monte Serrat; falta o relevo.)*
- [ ] Gerador de lotes no Godot, preenchendo com módulos.
- [ ] Subterrâneo gerado seguindo as ruas.
- [ ] Transição entre bairros pelo mapa.

**Portão:** os 2 bairros do corte vertical (um morro e Paquetá ou Valongo) gerados a partir do mapa real.

---

## Fase 4 — Corte vertical (4 a 6 meses)

Uma fatia **completa e polida** do jogo, que prova a ideia para jogadores de fora.

**Mundo**
- [ ] 2 bairros com o subterrâneo ligando os dois.
- [ ] Cerca de 30 NPCs com rotina em cada bairro.
- [ ] Pontos-chave: delegacia, biblioteca, igreja, benzedeira, cemitério, motel, mecânico, lan house.
- [ ] Suspeita e polícia básicas, maré básica.

**Casos**
- [ ] 3 a 4 criaturas e o golpe humano.
- [ ] Estruturas: caça simples, culpado humano, golpe.
- [ ] **Todos os testes de campo** ([05](05-investigacao-e-deducao.md)).
- [ ] Cartas e presentes depois do caso.

**Confronto** ([06](06-confronto-e-rituais.md))
- [ ] Estados da criatura, ferimentos localizados, medo.
- [ ] Espingarda de sal, revólver, faca. Menu radial, proteções de sal.
- [ ] 2 a 3 rituais com teste de reflexo.
- [ ] Negociação e apaziguamento (Curupira).

**Progressão**
- [ ] Mochila em grade, porta-malas.
- [ ] Dinheiro, uma reputação, 3 níveis de qualidade, motel, carro fixo.
- [ ] 2 a 3 árvores de habilidades humanas com poucas habilidades.
- [ ] Condição **Sensitivo** (opcional).
- [ ] Interlúdio com pulo de tempo (curto, médio, longo).

**Personagem e apresentação**
- [ ] Criação de personagem com sliders (corpo, rosto, pele, cabelo) e 1 a 2 roupas por parte, com disfarce de agente.
- [ ] Primeira passada de arte e áudio nos 2 bairros.

**Introdução**
- [ ] Caso tutorial com mentor aleatório.

**Morte**
- [ ] Versão simples: volta com custo, **sem a arena do limbo**.

**Portão:**
- Playtest com **5 a 10 pessoas de fora**. Observar onde se perdem e se querem jogar mais.
- **Página na Steam** e início das *wishlists*.
- Decidir se o projeto segue para a produção completa.

---

## Fase 5 — Conteúdo (6 a 9 meses)

- [ ] Zonas de Santos, **uma por vez**. Ordem sugerida:
  1. Central e portuária.
  2. Orla e intermediária.
  3. Morros.
  4. Noroeste.
  5. Área continental.
- [ ] Definir bairros **principais** (com marcos próprios) e **secundários** (só kit da zona).
- [ ] Kits de módulos por zona.
- [ ] Bestiário: criaturas típicas de cada tipo de bairro e as coringas, cobrindo as 8 famílias ([03](03-sistema-de-criaturas.md)).
- [ ] Variantes culturais (lobisomem brasileiro e europeu).
- [ ] Estruturas de caso restantes: cliente mentiroso, criatura errada.
- [ ] Condições **Vampirismo** e **Licantropia**, com estigma básico ([12](12-habilidades-e-condicoes.md)).
- [ ] Mais rituais, armas e roupas.

**Portão:** a cidade e o bestiário principal prontos; casos variados em todas as zonas.

---

## Fase 6 — Meta-jogo (4 a 6 meses)

- [ ] Economia completa: lojas, mercado negro, moedas por espécie ([08](08-economia-e-progressao.md)).
- [ ] Base evolutiva (motel, casa, base completa) e crafting.
- [ ] Todas as árvores de habilidades e todas as condições.
- [ ] Estigma, reputação dupla e **caçada com caso reverso**.
- [ ] Idade, envelhecimento visual, cicatrizes ([13](13-tempo-morte-e-finais.md)).
- [ ] Aposentadoria e epílogo procedural.
- [ ] Legado: carro, bestiário e mentor ([02](02-loop-de-jogo.md)).
- [ ] Estado dos bairros ao longo dos anos.

**Portão:** uma carreira completa de cerca de 10 horas, dos 20 anos à aposentadoria.

---

## Fase 7 — Limbo (2 a 3 meses)

- [ ] Combate físico corpo a corpo.
- [ ] Hordas a partir do histórico: uma criatura a cada 10 segundos, no máximo 5 ao mesmo tempo ([13](13-tempo-morte-e-finais.md)).
- [ ] Custos de voltar e marca do limbo.

**Portão:** a morte tem peso e o limbo é tenso, sem ser frustrante.

---

## Fase 8 — Polimento e lançamento (4 a 6 meses)

- [ ] Arte final (compra ou encomenda de assets onde fizer sentido), áudio, rádio por estação.
- [ ] Tradução para o inglês.
- [ ] Acessibilidade: efeitos PS1, testes de reflexo, modos de ajuda.
- [ ] Balanceamento: cerca de 4,5 anos de jogo por hora, 20 a 30 minutos por caso.
- [ ] Demo em evento da Steam (como o Next Fest).
- [ ] Lançamento, ou **Acesso Antecipado** depois da Fase 6.

---

## Prioridades e cortes possíveis

Se o projeto atrasar, esta lista diz **o que cortar primeiro**:

| Prioridade | Sistemas |
|---|---|
| **Essencial** | Gerador de casos, dedução, caderno, testes de campo, confronto, Santos (pelo menos 2 zonas), mochila, interlúdio |
| **Importante** | Todas as zonas, condições, economia completa, cartas, envelhecimento, aposentadoria, legado |
| **Desejável** | Caso reverso, mercado negro por espécie, base completa, envelhecimento visual detalhado |
| **Cortável** | Arena do limbo (manter a versão simples), área continental, bairros secundários detalhados, quadro de cortiça |

---

## Riscos

| Risco | Como reduzir |
|---|---|
| **A dedução não é divertida** | Portão da Fase 1, antes de qualquer 3D |
| **Casos injustos ou repetitivos** | Solucionador, matriz de distinção e gerador em lote desde a Fase 1 |
| **Escopo grande demais** | Portões, lista de cortes, desenvolvimento zona por zona |
| **Volume de arte** | Estética PS1, kits por zona, compra de assets |
| **Cidade real** | Pessoas e empresas fictícias, não estigmatizar bairros, pesquisa local ([07](07-mundo-cidade-e-npcs.md)) |
| **Folclore de tradições vivas** | Pesquisa e cuidado com cada criatura ([03](03-sistema-de-criaturas.md)) |
| **Dados do mapa incompletos** | Verificar na Fase 0, plano B com mapas da prefeitura |
| **Esgotamento (burnout)** | Metas por fase, mostrar o jogo cedo, aceitar cortes |

---

## Próximos passos imediatos

1. Criar o projeto Godot 4 com a estrutura de pastas.
2. Escrever o caso à mão.
3. Começar a Fase 1 pelos esquemas de dados e pela primeira ficha de criatura.
