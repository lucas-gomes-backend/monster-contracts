# 05 — Investigação e dedução

## Objetivo

Definir **como o jogador transforma pistas em respostas**. É a parte que decide se o jogo é divertido.

## Princípios

1. **Quem deduz é o jogador.** O jogo registra fatos, mas **não interpreta** por ele. Uma pista diz "pegadas com o calcanhar na frente", não "pegadas de Curupira".
2. **O jogo não confirma a resposta antes da hora.** Não existe botão "enviar resposta". O jogador **age** com base no que acredita (prepara, testa, confronta, acusa), e a verdade aparece nas consequências.
3. **Hipóteses podem ser testadas.** As regras fixas das criaturas ([03](03-sistema-de-criaturas.md)) permitem **testes de campo**: o jogador pode provar ou descartar uma suspeita, com custo e risco.
4. **Tempo é o recurso principal.** Toda ação consome tempo, enquanto a criatura age e as pistas expiram ([04](04-geracao-de-casos.md)).
5. **Errar é parte do jogo, não um game over.** O erro gera consequências (cartas, reputação, limbo), mas a carreira continua.

---

## Fluxo de uma investigação

```
Contrato ─► Coleta ─► Pesquisa ─► Hipótese ─► Teste de campo ─► Decisão
              ▲                       │              │
              └───────────────────────┴──────────────┘
                    (volta a coletar quando algo não fecha)
```

As etapas não são fixas: o jogador vai e volta entre elas o tempo todo. A ordem é dele, e escolher a ordem é parte da estratégia, porque as pistas expiram.

---

## Coleta

### Ações de coleta

| Ação | O que faz | Tempo | Risco ou custo |
|---|---|---|---|
| **Examinar** | Modo de inspeção: aproxima a câmera, varre com lanterna, UV ou EMF | Minutos | Pouco |
| **Fotografar** | Registra uma pista no caderno, mesmo depois que ela some | Segundos | Filme ou memória da câmera |
| **Coletar amostra** | Leva pelo, sangue, terra para análise | Minutos | Espaço na mochila, itens frágeis |
| **Entrevistar** | Conversa com testemunhas, vítimas, moradores | Minutos | Pode levantar suspeita |
| **Consultar registros** | Delegacia, hospital, cartório, jornal | Horas | Exige disfarce ou acesso |
| **Vigiar** | Fica num local por um tempo, esperando algo acontecer | Horas | Perigoso à noite |
| **Seguir** | Acompanha um NPC suspeito pela rotina dele | Horas | Ser visto aumenta a suspeita |
| **Invadir** | Entra onde não devia (casa, necrotério, covil) | Minutos | Suspeita alta, polícia, perigo |

### Acesso social

Boa parte das pistas está **atrás de pessoas**:

- **Disfarces** ([09](09-direcao-de-arte-camera-e-personagem.md)) abrem portas: agente federal na delegacia, jaleco no necrotério, jornalista com os moradores.
- **Horários importam:** a repartição fecha, a testemunha trabalha de dia, o bar só abre à noite.
- **Reputação no bairro** ([08](08-economia-e-progressao.md)) muda o quanto as pessoas falam.
- **Suspeita alta** fecha portas e pode levar à prisão ou à proibição de entrar no bairro.

---

## O caderno do caçador

O caderno é a **interface central** da investigação. Ele tem o visual de um caderno físico: fotos de baixa resolução, recortes de jornal e anotações à mão ([09](09-direcao-de-arte-camera-e-personagem.md)).

### Seções

| Seção | Conteúdo | Quem preenche |
|---|---|---|
| **Pistas** | Cada pista encontrada, com foto ou desenho, local, data e uma **descrição factual** | O jogo registra, o jogador anota |
| **Pessoas** | NPCs encontrados, relações entre eles, o que cada um disse | O jogo registra os depoimentos, o jogador marca contradições |
| **Linha do tempo** | Eventos com data e hora: ataques, avistamentos, depoimentos | O jogo coloca o que tem data, o jogador organiza o resto |
| **Mapa do bairro** | Locais visitados, cenas, onde as pistas foram achadas | O jogador marca e liga pontos |
| **Bestiário** | Fichas das criaturas, só com o que o jogador sabe ([03](03-sistema-de-criaturas.md)) | Pesquisa e experiência |
| **Hipóteses** | O quadro de dedução (ver abaixo) | O jogador |

### O quadro de hipóteses

É onde a dedução acontece:

1. O jogador **arrasta uma pista** e **solta numa característica** do bestiário para ligar as duas.
   - Exemplo: liga a pista "pegadas com o calcanhar na frente" à característica "pés virados para trás".
2. O quadro mostra **quais candidatos são compatíveis** com todas as ligações feitas.
3. O jogador **risca** os candidatos que descartou e **circula** o suspeito principal.
4. Também registra as respostas para **"Quem / onde?"** e **"Por quê?"** ([04](04-geracao-de-casos.md)).

**O jogo não diz se uma ligação está certa.** Se o jogador liga uma pista errada, as eliminações também saem erradas. Interpretar a pista é a parte da dedução que pertence ao jogador.

### Quadro de cortiça (opcional)

Na base, o caderno pode ser aberto como um **quadro de cortiça** na parede, com fotos, recortes e barbantes ligando as coisas. É a mesma informação, só que mais visual e mais satisfatória para casos complexos.

---

## Testemunhas e mentiras

### Entrevistas

- O jogador escolhe **temas** para perguntar (a noite do ataque, a vítima, outra pessoa, um lugar, uma pista).
- As respostas vêm das **memórias geradas** pela simulação, já com o filtro de percepção ([04](04-geracao-de-casos.md)).
- A **habilidade de Leitura de pessoas** ([12](12-habilidades-e-condicoes.md)) destaca hesitações e nervosismo, mas não diz qual é a verdade.

### Confrontar com provas

Quando um depoimento contradiz uma pista, o jogador pode **apresentar a prova**:

- **Contradição real:** o NPC cede e conta mais (o que viu de verdade, quem está protegendo, o que esconde).
- **Contradição falsa** (o jogador entendeu errado): o NPC se fecha, a confiança cai e a suspeita sobe.
- NPCs com **motivo forte** para mentir podem precisar de mais de uma prova, ou de pressão (intimidação) ou empatia.

---

## Pesquisa

- As fontes estão em [03](03-sistema-de-criaturas.md): internet, biblioteca, outros caçadores, folclore local.
- **Pesquisar no meio do caso consome tempo**, enquanto a criatura continua agindo.
- Cada informação no bestiário mostra **de onde veio** e **quão confiável é**:
  - Informação da internet aparece com um sinal de alerta.
  - Informação confirmada em campo aparece como certa.
- Pesquisa **direcionada** é mais rápida: perguntar "o que deixa pegadas viradas para trás?" é melhor que ler o livro todo.

---

## Testes de campo

Os testes são a parte mais ativa da dedução. Como as criaturas **sempre** seguem as próprias regras, o jogador pode **provocar uma reação** para confirmar ou descartar uma suspeita.

| Teste | Como fazer | O que confirma |
|---|---|---|
| **Grãos na porta** | Espalhar sementes na entrada da casa do suspeito | Strigoi (é obrigado a parar e contar) |
| **Espelho ou câmera** | Fotografar ou filmar o suspeito, posicionar um espelho | Vampiros (sem reflexo) |
| **Linha de sal** | Fechar uma porta ou janela com sal | Espíritos (não atravessam) |
| **Oferenda** | Deixar fumo ou cachaça na trilha da mata | Curupira e entidades da natureza (aceitam e respondem) |
| **Ferimento revelador** | Ferir a fera de leve e procurar o morador ferido no dia seguinte | Lobisomem brasileiro (o humano aparece com o mesmo ferimento) |
| **Água benta / objeto sagrado** | Oferecer, tocar, aproximar | Demônios, possuídos, portadores de pacto |
| **EMF / câmera térmica** | Medir o local na hora certa | Presença espiritual ou ausência de calor corporal |

### Regras dos testes

- **Custam algo:** material, tempo, e às vezes uma noite inteira de vigília.
- **Têm risco:** criaturas astutas e ardilosas **percebem o teste** e podem mudar de comportamento, fugir ou atacar ([03](03-sistema-de-criaturas.md)).
- **São confiáveis quando bem feitos:** a regra da criatura é fixa. Mas o teste só vale para **o suspeito testado**: testar a pessoa errada dá "negativo" sem descartar a criatura.
- **O conhecimento importa:** o jogador só conhece um teste se souber a regra que ele explora. Por isso a pesquisa abre novos testes.

---

## Decisão: responder às três perguntas

O caso termina quando o jogador **age**. Não há tela de resposta. Algumas formas de agir:

| Ação | Quando faz sentido |
|---|---|
| **Preparar e confrontar** | Sabe **o quê** e **onde**. Leva as fraquezas certas e vai ao covil ou espera a criatura |
| **Prender** | Sabe **quem** e tem como conter |
| **Curar / quebrar maldição** | Sabe **o quê**, **quem** e **por quê** |
| **Apaziguar / negociar** | Sabe **o quê** e **por quê** |
| **Expor um humano** | Juntou provas contra o culpado humano e leva à polícia, à imprensa ou ao cliente |
| **Desmascarar um golpe** | Provou que não há criatura |
| **Abandonar** | Desiste do caso, com custo ([04](04-geracao-de-casos.md)) |

### O relatório do caso

Depois do desfecho, o jogo mostra um **relatório** comparando **o que o jogador acreditava** com **o que era verdade**. O relatório revela **toda a verdade** do caso:

- Qual era a criatura, quem era, por quê.
- Quais pistas o jogador encontrou e quais **perdeu ou interpretou errado**.
- Quais NPCs mentiram, e por quê.
- O bestiário recebe as informações **confirmadas** em campo.

Isso transforma o erro em aprendizado, no estilo da revelação de *Return of the Obra Dinn*, e faz o jogador melhorar de verdade entre os casos.

---

## Tempo e pressão

| Ação | Tempo aproximado |
|---|---|
| Examinar uma cena | 15 a 60 min de jogo |
| Entrevista | 10 a 30 min |
| Ir a outro ponto do bairro | 10 a 30 min |
| Ir a outro bairro | 30 min a 2 h |
| Pesquisa na internet | 30 min |
| Pesquisa na biblioteca | 2 a 4 h |
| Vigília | O tempo que o jogador escolher |
| Análise de amostra no laboratório | Algumas horas a 1 dia |

- O relógio aparece no caderno e no relógio de pulso do personagem.
- Eventos da simulação acontecem enquanto isso: novos ataques, pistas expirando, testemunhas viajando.
- Com a meta de **20 a 30 minutos reais por caso**, um caso cobre de **1 a 4 dias de jogo**.

---

## Suspeita durante a investigação

Ações arriscadas aumentam a **suspeita** ([08](08-economia-e-progressao.md)):

- Ser visto invadindo ou com arma na mão.
- Mentir mal com um disfarce.
- Estar em várias cenas de crime.
- Roupa suja de sangue.

Com suspeita alta, a polícia aparece, NPCs se recusam a falar, e o jogador pode ser **detido** (perde tempo e equipamento apreendido) ou **barrado no bairro**.

---

## Habilidades e condições na investigação

Elas abrem **novos jeitos de coletar**, nunca a resposta ([12](12-habilidades-e-condicoes.md)):

| Fonte | Ajuda na investigação |
|---|---|
| **Observação** | Destaca pistas sutis na cena |
| **Leitura de pessoas** | Destaca hesitação e nervosismo |
| **Pesquisa** | Pesquisa mais rápida e direcionada |
| **Forense** | Analisa amostras em campo, sem laboratório |
| **Vampirismo** | Sente o cheiro de sangue: sabe onde alguém sangrou |
| **Licantropia** | Segue rastros pelo cheiro |
| **Sensitivo** | Vê e conversa com espíritos, tem visões tocando objetos |
| **Marca da Mata** | Animais contam o que viram |

---

## Ajuda e dificuldade

| Modo | Como funciona |
|---|---|
| **Assistido** | O jogo sugere ligações óbvias entre pistas e características, e destaca contradições nos depoimentos |
| **Padrão** | Sem sugestões. O quadro mostra os candidatos compatíveis com as ligações do jogador |
| **Puro** | O quadro não filtra candidatos. O jogador cruza tudo sozinho |

---

## Exemplo rápido

**Caso:** galinhas mortas e um homem ferido no bairro antigo. O cliente pede para "matar o cachorro do demônio".

1. **Cena:** pegadas de cachorro grande e pelos escuros. A chuva da madrugada vai apagar as pegadas, então o jogador **fotografa** primeiro.
2. **Entrevista:** o vizinho viu "um bicho do tamanho de um bezerro" depois da meia-noite **de sexta**. Uma senhora jura que é o lobisomem.
3. **Pesquisa:** na biblioteca, o jogador descobre as regras do lobisomem brasileiro (sexta-feira, sétimo filho, ferimento revelador).
4. **Hipóteses:** ligando as pistas, restam o **lobisomem brasileiro**, o **lobisomem europeu** e um **cachorro de verdade** (golpe ou acaso).
5. **Pessoas:** o caderno mostra que **Tonico**, o filho mais novo da família do lado, falta ao trabalho toda sexta. A mãe teve **sete filhos**.
6. **Teste de campo:** na sexta seguinte, o jogador fere a fera de leve. No sábado, Tonico aparece com o braço enfaixado.
7. **Decisão:** o jogador sabe **o quê** (lobisomem brasileiro), **quem** (Tonico) e **por quê** (maldição de nascença), e escolhe **quebrar a maldição** em vez de matar.
8. **Consequência:** algumas semanas depois, chega uma carta da mãe de Tonico, com um bolo.

---

## Escopo no roadmap

- **Fase 1 (só texto):** o caderno com Pistas, Pessoas e Hipóteses, mais entrevistas. É o teste de fogo.
- **Corte vertical:** caderno completo menos o quadro de cortiça, **todos os testes de campo**, confrontar com provas, relatório do caso.
  - Alguns testes servem para criaturas que ainda não estarão no corte vertical (grãos para o strigoi, espelho para vampiros). Eles entram mesmo assim, porque **um teste negativo também é informação**: descarta suspeitas e ensina o jogador a testar.
- **Depois:** quadro de cortiça, vigília e perseguição mais elaboradas.

## Decisões

- **Ligar pistas:** arrastar e soltar no caderno.
- **Relatório do caso:** mostra toda a verdade.
- **Testes de campo no corte vertical:** todos.
- **EMF e câmera térmica (18/11/2026):** não exploram uma fraqueza, e sim o que a criatura é. O teste tem `positivo_se` (natureza ou família da ficha) em `config/testes_de_campo.json`. EMF: natureza espiritual ou híbrida, família espírito ou demônio (pega o Curupira). Térmica: morto-vivo ou espírito, sem calor de corpo (pega o corpo-seco). Os dois esperam a hora em que a criatura age.
