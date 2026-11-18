# 09 — Direção de arte, câmera e personagem

## Resumo

- **Câmera:** terceira pessoa.
- **Estética:** **PlayStation 1**: poucos polígonos, texturas tremidas, névoa, sons comprimidos.
- **Personagem:** totalmente customizável, e o corpo **conta a história da carreira** (idade, cicatrizes, condição, roupas).

A estética de PS1 combina com o projeto por três motivos:

1. **Clima:** o visual "imperfeito" do PS1 já é associado a terror e mistério (*Silent Hill*, *Resident Evil*, a cena atual de terror PSX). Ele esconde detalhes e deixa a imaginação do jogador trabalhar.
2. **Escopo:** modelos de baixa contagem de polígonos e texturas pequenas são **muito mais rápidos de produzir** para um dev solo.
3. **Procedural:** módulos simples e texturas pequenas facilitam montar a cidade e os bairros proceduralmente sem que a falta de detalhe pareça erro.

---

## Câmera e controles

- **Câmera de terceira pessoa por cima do ombro**, livre, com colisão para não atravessar paredes.
- **Controles modernos** (andar relativo à câmera). *Tank controls* ficam como **opção** para quem quiser a sensação clássica.
- **Modo de mira e inspeção:** a câmera aproxima por cima do ombro para mirar, fotografar ou usar equipamento (UV, câmera térmica).
- **Inspeção de pistas:** ao pegar um objeto, ele aparece em close e pode ser girado, como em *Resident Evil*.
- **Ângulos fixos:** câmeras fixas cinematográficas aparecem de duas formas:
  - **Momentos roteirizados:** o jogo usa ângulos fixos em cenas de tensão e em interiores marcantes, como o necrotério ou a casa do caso.
  - **Opção do jogador:** nos interiores, o jogador pode ligar o modo de câmeras fixas no estilo *Resident Evil* clássico.
  - Como a cidade é montada com módulos, **cada módulo de interior já vem com os seus pontos de câmera fixa**, então o modo funciona também em lugares gerados proceduralmente.

---

## Especificação visual PS1

| Elemento | Regra |
|---|---|
| **Resolução interna** | Baixa (por volta de 320×240 a 640×480), escalada sem suavização. Opção no menu. |
| **Vértices** | *Vertex snapping*: os vértices "pulam" para uma grade, gerando o tremor característico. |
| **Texturas** | Mapeamento afim (distorção da textura), filtro *nearest* (sem suavizar), tamanhos de 64 a 256 px. |
| **Cor** | Paleta reduzida com *dithering*. |
| **Iluminação** | Por vértice, com poucas luzes dinâmicas. Sombras simples (*blob shadows*) ou nenhuma. |
| **Névoa** | Névoa e escuridão para limitar a distância de visão. **É um recurso de clima**, não só de desempenho. |
| **Polígonos** | Personagens com cerca de 500 a 1500 triângulos. Cenários simples, com detalhe nas texturas. |
| **Animação** | Poucos quadros-chave, sem *blending* exagerado, para dar a sensação "dura" da época. |
| **Pós-processamento** | Filtro CRT/scanlines **opcional**, ruído e leve aberração. |

### Acessibilidade

Todos os efeitos fortes podem ser **reduzidos ou desligados**: tremor de vértice, distorção de textura, filtro CRT e *dithering*. Isso evita enjoo e cansaço visual.

---

## Customização do personagem

### Criação

| Categoria | Opções |
|---|---|
| **Corpo** | Sliders de tipo de corpo, altura, compleição e proporções |
| **Rosto** | Sliders de formato (mandíbula, nariz, olhos, testa, boca) combinados com texturas de rosto no estilo PS1 |
| **Pele** | Tons de pele variados |
| **Cabelo e barba** | Cortes, cores, barba e bigode |
| **Marcas** | Tatuagens (inclusive **tatuagem de proteção contra possessão**, que tem efeito no jogo), pintas, marcas de nascença |
| **Voz** | Conjuntos de **sons** (grunhidos, respiração, reações de dor e susto), no estilo da época. **Sem falas dubladas.** Os diálogos são em texto. |
| **Origem** (opcional) | Comunidade de origem: afeta o conhecimento inicial do folclore daquela cultura e algumas reações de NPCs |

### O corpo conta a história

A aparência **muda sozinha** ao longo da carreira, ligada aos sistemas das outras partes:

- **Idade** ([13](13-tempo-morte-e-finais.md)): cabelo grisalho, rugas, postura. Por ser PS1, isso se faz trocando texturas e alguns ajustes de modelo.
- **Cicatrizes e sequelas** ([13](13-tempo-morte-e-finais.md)): aparecem no corpo e no rosto, e é possível ver de qual caso veio cada uma.
- **Condição** ([12](12-habilidades-e-condicoes.md)): palidez e olhos de vampiro, pelos e olhar animal do lobisomem, marcas do pacto, a marca do limbo.
  - Os **sinais podem ser escondidos** com maquiagem, lentes, roupas e amuletos, ligados ao sistema de estigma.

### Roupas e equipamento visíveis

Tudo o que o jogador veste e carrega **aparece no modelo**:

- **Partes de roupa:** cabeça, rosto (óculos, máscara), tronco, jaqueta ou casaco, mãos, pernas, pés.
- **Acessórios:** amuletos, coldres, cinto e **mochila visível**, cujo tamanho reflete a mochila equipada ([08](08-economia-e-progressao.md)).
- **Disfarces** (terno de agente, jaleco, macacão) mudam a silhueta e são **lidos pelos NPCs**: a aparência faz parte da credibilidade.
- **Desgaste visual:** roupas sujas, rasgadas ou ensanguentadas depois de um confronto **chamam atenção** e aumentam a suspeita até você se trocar.

### Técnica

- **Esqueleto único** compartilhado por todos os corpos, e roupas como **malhas modulares** encaixadas nele.
- **Sliders por blend shapes** (morph targets) e escala de ossos. Em modelos de poucos polígonos isso é barato, e as roupas precisam acompanhar as mesmas formas.
- **Troca de paleta e textura** para variar cores e materiais com poucos arquivos.
- O **mesmo sistema monta os NPCs** proceduralmente, para gerar a população da cidade com variedade e quase sem custo extra.

---

## Tom visual

- **Meio-termo:** o horror vem da névoa, dos sons e do que não se vê com clareza. O humor e o calor humano vêm de personagens, diálogos, do carro e das músicas no rádio.
- **Paleta por bairro:** cada tipo de bairro tem cores, luz e névoa próprias, como a mata verde-escura e úmida, o centro com neon e luz de poste alaranjada, o bairro antigo cinza e desbotado, ou a orla azulada e enevoada.
- **Noite é perigosa e bonita:** luz de poste, faróis do carro, lanterna e lua.

## Interface

- **Menus com visual da época:** fontes pixeladas, transições simples e sons de menu marcantes.
- **Caderno do caçador:** o caderno de pistas e o bestiário são desenhados como um caderno físico, com recortes de jornal, fotos de câmera de baixa resolução e anotações à mão.
- **Salvar o jogo:** salva no motel, no carro ou na base, com uma apresentação temática (escrever no diário).
- **Mínimo de interface na tela** durante a exploração.

## Áudio

- **Amostras de baixa taxa** e reverb pesado nos ambientes, no estilo da época.
- **Trilha:** ambiente sintetizado nos momentos de tensão e **rádio do carro** com estações da cidade (rock, música brasileira, rádios das comunidades) para a parte calorosa do tom.
- **O som é pista:** barulhos distantes, vozes, arranhões. Os fones de ouvido fazem parte da investigação.

---

## Escopo e roadmap

- **Fase 2 (greybox):** o shader PS1 entra **cedo**. Ele é barato e o greybox já fica com cara de jogo.
- **Corte vertical:** criação de personagem simples (corpo, rosto, pele, cabelo) e 1 ou 2 roupas por parte, com disfarce de agente.
- **Fase 4 e 5:** envelhecimento visual, cicatrizes, sinais de condição e roupas em quantidade.
- **Godot** tem vários shaders PSX de código aberto como ponto de partida.

## Decisões

- **Criação de personagem no corte vertical (18/11/2026):** `config/aparencia.json`. 9 sliders (altura, compleição, pernas, ombros, cabeça, mandíbula, nariz, olhos, testa), 6 tons de pele, 5 cabelos, 5 cores de cabelo, 4 barbas e roupas por parte (cabeça, tronco, pernas, pés). O boneco é montado em caixas low-poly (`presentation/personagem/corpo.gd`), sem esqueleto nem blend shapes ainda: serve para o corte vertical e já usa os mesmos dados que o modelo final vai usar. Disfarce de agente = terno, calça social e sapato social: quem vê o caçador desconfia pela metade. A tela fica em "Criar o caçador", na tela inicial.

- **Câmeras fixas:** em momentos roteirizados e também como opção do jogador nos interiores.
- **Voz:** só sons, sem falas dubladas.
- **Customização:** por sliders.
- **Efeito PS1 desligado por enquanto (17/11/2026):** o tremor dos vértices, a textura afim e o pontilhado da tela ficam desligados em `game/data/config/visual.json` (`efeito_ps1`), porque o chão da cidade piscava. Liga de novo mudando uma linha. A resolução interna de 640×480 continua.
- **Cidade de dia, com névoa clara (17/11/2026):** os bairros do mapa real ficam de dia nublado, com névoa esbranquiçada que engole o fundo, no espírito de Silent Hill.
