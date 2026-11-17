# 02 — Loop de jogo

## Objetivo

Mostrar **como todos os sistemas se encaixam** num ciclo que o jogador repete. O jogo tem **quatro loops**, um dentro do outro:

```
LEGADO ─ várias carreiras na mesma cidade
 └─ CARREIRA ─ dos 20 anos até a aposentadoria (~10 h)
     └─ CICLO DE CASO ─ contrato → investigação → desfecho → interlúdio (~20 a 30 min)
         └─ MOMENTO A MOMENTO ─ explorar, examinar, conversar, testar
```

---

## 1. Momento a momento

O que o jogador faz **a cada minuto**, em terceira pessoa pela cidade:

- **Andar e dirigir** pelos bairros, com névoa, rádio e o relógio correndo.
- **Examinar** cenas com lanterna, UV e EMF, e **fotografar** pistas.
- **Conversar** com NPCs, escolher temas, **confrontar** com provas.
- **Abrir o caderno** para ligar pistas a características (arrastar e soltar).
- **Gerenciar a mochila**: o que levar, o que deixar no carro.
- **Testar** hipóteses em campo e **vigiar** locais.
- **Evitar suspeita**: escolher o disfarce certo, não ser visto onde não deve.

**Sensação-alvo:** curiosidade e tensão. Sempre há algo a examinar, alguém a quem perguntar, e o relógio lembrando que a criatura continua agindo.

---

## 2. Ciclo de caso

```
 ┌──────────────────────────────────────────────────────────────────┐
 │                                                                  │
 ▼                                                                  │
CONTRATO ──► INVESTIGAÇÃO ──► PREPARAÇÃO ──► DESFECHO ──► INTERLÚDIO ┘
 escolher     coletar,         mochila,       confrontar,   cartas, loja,
 um caso      pesquisar,       armas,         curar, expor,  cura, treino,
              testar           disfarce       negociar...    pular tempo
```

### 2.1 Contrato

Os contratos chegam por **vários canais**, e cada canal traz um tipo de caso:

| Canal | Tipo de caso |
|---|---|
| **Secretária eletrônica / telefone** da base | Clientes que já conhecem o jogador |
| **Jornal** | Notícias estranhas: o jogador vai por conta própria, sem cliente nem pagamento garantido |
| **Rádio da polícia** (upgrade do carro) | Casos antes de virarem notícia |
| **Bar dos caçadores** | Contratos de outros caçadores, trabalhos difíceis |
| **Cartas** | Pedidos de ajuda, ameaças, consequências de casos antigos ([04](04-geracao-de-casos.md)) |
| **Criaturas** | Pedidos do mercado oculto, para jogadores com condição ou com reputação entre o sobrenatural |

- Ficam disponíveis **2 a 4 ofertas** ao mesmo tempo, cada uma com bairro, cliente, pedido, recompensa, prazo e um **perigo estimado** (que pode estar errado).
- O jogador trabalha em **um caso por vez**. As ofertas não escolhidas **expiram** ou são pegas por outros caçadores, e às vezes voltam piores.

### 2.2 Investigação

Coleta, pesquisa, hipóteses e testes de campo ([05](05-investigacao-e-deducao.md)).

### 2.3 Preparação

Com uma hipótese em mãos, o jogador se prepara:

- **Mochila e bolsos:** o que levar, com limite de espaço e peso ([08](08-economia-e-progressao.md)).
- **Armas e materiais** contra as fraquezas da criatura suspeita.
- **Fabricar** o que falta: munição de prata, saquinhos de proteção, oferendas.
- **Disfarce e roupa** certos para o lugar.
- **Escolher a hora:** de dia, quando o vampiro dorme? Na sexta, quando o lobisomem aparece?

**A preparação é a "aposta" do jogador na própria dedução.** Ir com o equipamento errado é a principal forma de punição por errar.

### 2.4 Desfecho

O jogador age: confronta, prende, cura, apazigua, negocia, expõe um humano, desmascara um golpe ou abandona ([05](05-investigacao-e-deducao.md), [06](06-confronto-e-rituais.md)). Depois vem o **relatório do caso** com toda a verdade.

### 2.5 Interlúdio

O tempo entre um caso e outro. É onde a **progressão** acontece:

| Atividade | Sistema |
|---|---|
| **Ler cartas e abrir presentes** | Consequências ([04](04-geracao-de-casos.md)) |
| **Receber e gastar** | Economia, lojas, mercado negro ([08](08-economia-e-progressao.md)) |
| **Consertar** armas e carro | Desgaste e danos ([08](08-economia-e-progressao.md)) |
| **Fabricar** itens rituais | Crafting |
| **Melhorar a base** | Base ([08](08-economia-e-progressao.md)) |
| **Treinar** com mentores | Habilidades humanas ([12](12-habilidades-e-condicoes.md)) |
| **Pesquisar** criaturas | Bestiário ([03](03-sistema-de-criaturas.md)) |
| **Cuidar da condição** | Sangue, oferendas, preparação para a lua cheia ([12](12-habilidades-e-condicoes.md)) |
| **Despistar caçadores rivais** | Caçada ([12](12-habilidades-e-condicoes.md)) |
| **Customizar** roupa e visual | Personagem ([09](09-direcao-de-arte-camera-e-personagem.md)) |

#### Pular o tempo

O interlúdio termina quando o jogador **escolhe quanto tempo deixar passar** até o próximo caso:

| Pulo | Ganho | Custo |
|---|---|---|
| **Curto** (dias) | Pega o próximo caso rápido | Ferimentos não saram, pouco treino |
| **Médio** (semanas) | Ferimentos saram, treino e pesquisa avançam | Algumas ofertas expiram |
| **Longo** (meses) | Cura completa, muito treino, base melhora | **Envelhece mais**, o mundo muda, caçadores rivais se organizam |

**A idade vira um recurso.** Cada pulo longo deixa o caçador mais preparado, mas aproxima a aposentadoria ([13](13-tempo-morte-e-finais.md)).

---

## 3. Carreira

A carreira dura cerca de **10 horas** e **20 a 30 casos**, dos 20 anos até a aposentadoria ([13](13-tempo-morte-e-finais.md)).

### Arco da carreira

| Fase | Idade aproximada | Como é jogar |
|---|---|---|
| **Começo** | 20 a 25 | Motel, carro velho (ou o carro herdado), espingarda de sal. Bestiário só com senso comum (ou herdado). Casos simples em 1 ou 2 bairros. Muito erro e aprendizado |
| **Ascensão** | 25 a 35 | Casa ou base pequena, primeiros disfarces e equipamento profissional. Mais bairros abertos. Primeira condição, por escolha ou por falha |
| **Auge** | 35 a 50 | Base completa, reputação em vários bairros, casos com várias camadas, caçadores rivais, decisões morais pesadas |
| **Declínio** | 50+ | O corpo cansa, a mente está no máximo. Casos de investigação pura, papel de mentor, preparação da aposentadoria |

- Criaturas **imortais** ficam presas no "auge" para sempre. Elas não envelhecem, mas veem os humanos à sua volta envelhecerem e morrerem.

### Abertura da cidade

- A cidade abre **aos poucos**: os bairros ficam disponíveis conforme a reputação e os contatos do jogador.
- Isso controla a dificuldade (mais bairros significam mais criaturas possíveis) e dá **sensação de expansão**.

### Primeira hora (introdução)

1. **Criação do personagem** aos 20 anos ([09](09-direcao-de-arte-camera-e-personagem.md)).
2. **Caso tutorial** com um **mentor**, um caçador veterano **gerado aleatoriamente**, que ensina o caderno, a coleta e um teste de campo.
3. **Primeiro caso sozinho** num bairro, com estrutura simples e equipamento improvisado.
4. **Primeiro interlúdio:** cartas, loja e o primeiro pulo de tempo.

**Regra do mentor:**

- **Primeira carreira:** mentor aleatório.
- **Se a carreira anterior terminou em aposentadoria:** o mentor da carreira seguinte é **o seu personagem anterior**, já velho, com a aparência, as cicatrizes e as histórias que ele acumulou.
- **Na carreira depois dessa** (ou se a anterior terminou em morte definitiva): o mentor volta a ser aleatório.

---

## 4. Legado

Quando a carreira termina (aposentadoria ou morte definitiva), o jogador pode **começar outra na mesma cidade, anos depois** ([13](13-tempo-morte-e-finais.md)):

- A cidade **mudou** com o que o caçador anterior fez: bairros mais seguros ou mais perigosos, criaturas poupadas que agora têm histórias, inimigos que lembram.
- **O que passa adiante:** só duas coisas.
  - **O carro**, com os upgrades e as marcas que ele acumulou.
  - **O bestiário**, com as anotações e confirmações do caçador anterior.
- **O que não passa:** dinheiro, base, equipamento, habilidades, condição e reputação. O novo caçador começa por baixo, mas com o carro do antecessor e o caderno dele.
- O caçador anterior, se se aposentou, aparece como **mentor** (ver "Regra do mentor").

---

## Sessão típica

| Duração da sessão | O que cabe |
|---|---|
| **30 minutos** | Um caso completo, ou investigação parcial e salvar no meio |
| **1 a 2 horas** | 2 a 4 casos com interlúdios: um "capítulo" da carreira |
| **Fim de semana** | Uma carreira inteira |

- O jogo salva no **motel, no carro ou na base** ([09](09-direcao-de-arte-camera-e-personagem.md)), então sempre há um ponto de parada perto.

---

## Curva emocional de um caso

```
tensão
  ▲                              ★ desfecho
  │                         ╱╲
  │                    ╱╲  ╱  ╲
  │          ╱╲      ╱    ╲╱    ╲
  │    ╱╲  ╱    ╲  ╱              ╲___ cartas: alívio ou culpa
  │  ╱    ╲      ╲╱                    ╲___ interlúdio: calma
  └──────────────────────────────────────────────► tempo
   contrato  pistas  vítima  teste   confronto
```

- A tensão **sobe em ondas**: cada nova vítima ou pista pesa, cada hipótese confirmada alivia um pouco.
- O **desfecho** é o pico.
- As **cartas** dão o "fechamento emocional", e o **interlúdio** é o respiro antes do próximo caso.

---

## Decisões

- **Casos abertos:** um por vez.
- **Pulo de tempo:** opções fixas (curto, médio, longo).
- **Mentor:** aleatório; se a carreira anterior terminou em aposentadoria, o mentor seguinte é o personagem anterior, e depois volta a ser aleatório.
- **Legado:** passam só o carro e o bestiário.
