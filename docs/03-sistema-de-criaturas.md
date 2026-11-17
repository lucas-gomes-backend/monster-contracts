# 03 — Sistema de criaturas

## Objetivo

Definir **o formato de regras** que descreve qualquer criatura do jogo. Esse formato é a base de quase tudo:

- A **simulação** usa a ficha para fazer a criatura agir no mundo (pilar 1).
- O **gerador de casos** usa as marcas da ficha para criar pistas ([04](04-geracao-de-casos.md)).
- O **bestiário** do jogador é uma versão incompleta da ficha, que ele vai preenchendo ([05](05-investigacao-e-deducao.md)).
- As **condições** do jogador usam a mesma ficha ([12](12-habilidades-e-condicoes.md)).
- **Caçadores rivais** investigam o jogador usando a ficha da condição dele.
- O **limbo** reconstrói as criaturas mortas a partir da ficha ([13](13-tempo-morte-e-finais.md)).

## Princípios

1. **Regras explícitas e fixas.** Uma criatura nunca quebra as próprias regras. Se o vampiro precisa de convite, ele **sempre** precisa. É isso que torna a dedução justa.
2. **Variação dentro da regra, nunca contra ela.** Cada criatura gerada varia horário preferido, tipo de vítima, idade e personalidade, mas as regras da espécie continuam valendo.
3. **Nenhuma pista sozinha identifica uma criatura.** As marcas são compartilhadas entre espécies, e o que identifica é a **combinação**.
4. **Toda espécie precisa ser distinguível** das parecidas por pelo menos **duas** marcas. Isso é verificado automaticamente (ver "Matriz de distinção").
5. **Matar é só uma das saídas.** Toda ficha lista as resoluções possíveis, e várias criaturas têm saídas não letais.

---

## A ficha de uma criatura

### 1. Identidade

| Campo | Descrição | Exemplo (Lobisomem brasileiro) |
|---|---|---|
| **Nome** | Nome local e nomes alternativos | Lobisomem, lobisome |
| **Região** | Origem cultural | Brasil (interior) |
| **Família** | Arquétipo que define comportamentos padrão (ver "Famílias") | Amaldiçoado / Metamorfo |
| **Natureza** | Corpórea, espiritual ou híbrida | Corpórea |
| **Inteligência** | Instintiva, astuta ou ardilosa | Instintiva (transformado), astuta (humano) |
| **Disposição** | Hostil, neutra, protetora ou ressentida | Hostil quando transformado |
| **Perigo** | 1 a 5 | 3 |

### 2. Ciclo de atividade

Quando a criatura **pode** agir:

- **Horário:** noite, dia, crepúsculo, qualquer hora.
- **Lua:** cheia, nova, independe.
- **Calendário:** dias da semana, datas especiais, estações.
- **Clima:** chuva, neblina, calor.

> Exemplo: o lobisomem brasileiro age **à meia-noite de sexta-feira**, sobretudo na **lua cheia**.

### 3. Gatilho

O que **desperta** a criatura ou a faz começar a agir. É o "por que agora?" do caso.

- Exemplos: uma maldição de família, uma cova profanada, uma promessa quebrada, uma árvore derrubada, um convite aceito, uma data.

### 4. Necessidade (alimentação)

O que ela **precisa** e com que frequência. Isso define o **ritmo** do caso.

| Campo | Exemplo |
|---|---|
| **O quê** | Sangue, carne, medo, memória, oferenda, vingança |
| **Frequência** | Uma vez por ciclo lunar, a cada noite, quando provocada |
| **Escalada** | O que acontece se a necessidade não é atendida ou se ela é ameaçada |

### 5. Caça (comportamento)

- **Seleção de vítima:** quem ela escolhe. Por exemplo: animais primeiro e depois pessoas, quem estiver sozinho na estrada, quem desrespeitou a mata, membros de uma família.
- **Método:** como ataca (emboscada, sedução, possessão, assombração lenta).
- **Território:** raio de ação em torno do covil.
- **Reação ao caçador:** o que faz quando percebe que está sendo investigada:

  | Inteligência | Reação típica |
  |---|---|
  | Instintiva | Ignora ou ataca |
  | Astuta | Muda de território ou de rotina |
  | Ardilosa | Planta **pistas falsas**, manipula NPCs, prepara armadilhas |

### 6. Covil

- Onde fica, com que aparência e que sinais deixa: chiqueiro e encruzilhada, cemitério, mata fechada, porão, rio.

### 7. Disfarce

Como passa despercebida:

- **Forma humana:** vive como um morador comum (vampiro, lobisomem de dia).
- **Possessão:** usa um corpo emprestado.
- **Invisível:** só se percebe pelos efeitos (espíritos).
- **Forma animal ou objeto.**
- **Pistas do disfarce:** tiques, hábitos ou falhas que denunciam a forma humana. Por exemplo: palidez, evitar espelhos, sumir toda sexta-feira.

### 8. Marcas (evidências)

O campo **mais importante para a dedução**. São as pistas que a criatura deixa e que o gerador de casos usa. Cada marca tem:

| Atributo | Descrição |
|---|---|
| **Tag** | Identificador compartilhado entre espécies (ex.: `mordida_pescoco`, `pegadas_invertidas`) |
| **Onde aparece** | Corpo da vítima, cena, covil, testemunha, ambiente, registro |
| **Frequência** | Sempre, comum, rara |
| **Como detectar** | A olho nu, com UV, com EMF, com análise de laboratório, com habilidade |

Tipos de marca:

- **Físicas:** ferimentos, pegadas, pelos, sangue, objetos.
- **Ambientais:** frio súbito, cheiro (enxofre, terra molhada), animais agitados, eletrônicos falhando, plantas murchas.
- **Comportamentais:** padrão de horário, perfil das vítimas, padrão geográfico.
- **Sociais:** relatos de testemunhas, boatos, histórico da família, registros antigos.

### 9. Fraquezas

Separadas por **efeito**, porque cada uma serve para uma coisa:

| Efeito | Descrição | Exemplo (Lobisomem brasileiro) |
|---|---|---|
| **Afasta** | Impede a aproximação | Reza, figa, arruda |
| **Fere** | Causa dano real | Arma branca benzida |
| **Revela** | Força a criatura a mostrar a forma verdadeira | Ferimento que sangra a pessoa transformada |
| **Prende** | Imobiliza ou contém | Laço, correntes ao amanhecer |
| **Destrói/cura** | Resolve de vez | Ferir para quebrar a maldição, ou bala de prata (variante estrangeira) |

### 10. Tabus e regras

Comportamentos **obrigatórios** da criatura que o jogador pode explorar:

- Precisa de convite para entrar.
- Não atravessa água corrente.
- É obrigada a contar grãos espalhados no chão.
- Não pode recusar uma oferenda.
- Volta sempre ao mesmo lugar.

### 11. Resoluções possíveis

| Resolução | Descrição |
|---|---|
| **Matar** | Destrói a criatura e conta para o limbo |
| **Banir / exorcizar** | Remove do lugar ou do corpo, mas ela pode voltar em outro lugar |
| **Prender** | Contém na base, para estudo ou negociação |
| **Curar / quebrar maldição** | Devolve a humanidade (amaldiçoados) |
| **Apaziguar** | Atende a necessidade de outro jeito (espíritos, entidades da natureza) |
| **Negociar** | Faz um acordo, que gera favor, item ou condição |

Cada ficha lista **quais resoluções existem** para aquela espécie e **o que cada uma exige**.

### 12. Recompensas e materiais

- Materiais que a criatura deixa e o mercado negro compra ([08](08-economia-e-progressao.md)).
- Conhecimento liberado no bestiário e receitas de crafting.

### 13. Condição transmitida (opcional)

- Se a criatura pode **transformar o jogador**, e como ([12](12-habilidades-e-condicoes.md)).

### 14. Variantes regionais

- A mesma família pode ter regras diferentes por região. O **lobisomem brasileiro** (sétimo filho, sexta-feira, encruzilhada, chiqueiro) e o **lobisomem europeu** (mordida transmite, prata, lua cheia) são **espécies separadas** no bestiário.
- O jogador precisa considerar **onde** está o caso.

### 15. Pesquisa e fontes

- Fontes usadas para a criatura e notas de cuidado cultural.
- Toda criatura de **tradição viva**, como as religiosas e indígenas, passa por pesquisa extra. Algumas podem ficar **fora do jogo** por respeito.

---

## Famílias (arquétipos)

As famílias definem **comportamentos padrão**. A ficha só sobrescreve o que for diferente, o que poupa trabalho e mantém a coerência.

| Família | Padrão | Resoluções típicas | Exemplos |
|---|---|---|---|
| **Mortos-vivos** | Corpóreos, noturnos, se alimentam dos vivos | Matar, prender | Vampiros, draugr, jiangshi |
| **Metamorfos** | Vivem disfarçados, se transformam em ciclo | Matar, curar, prender | Lobisomens, kitsune, skin-changers |
| **Amaldiçoados** | Humanos sob maldição, inocentes no dia a dia | Curar, prender, matar | Mula sem cabeça, lobisomem brasileiro |
| **Espíritos / assombrações** | Incorpóreos, presos a um lugar, objeto ou pessoa | Apaziguar, banir | Yūrei, banshee, La Llorona |
| **Entidades da natureza** | Protegem um território, punem quem viola regras | Apaziguar, negociar | Curupira, Boitatá, rusalka, kappa |
| **Trapaceiros** | Pregam peças, quase nunca matam, adoram acordos | Negociar, prender | Saci, fadas, djinn menores |
| **Demônios / pactuantes** | Fazem acordos, possuem corpos, cobram dívidas | Banir, exorcizar, negociar | Demônios de encruzilhada, djinn, oni |
| **Bestas / criptídeos** | Animais sobrenaturais, instintivos | Matar, prender, afastar | Chupacabra, Mapinguari, bunyip |

---

## Simulação: estados de comportamento

Cada criatura roda numa máquina de estados simples, que é o que gera o caso com o passar do tempo:

```
Dormente ──(gatilho)──► Ativa ──► Caçando ──► Alimentada ──► Ativa ...
                          │            │
                          │            └─(necessidade não atendida / ameaça)──► Escalando
                          └─(percebe o caçador)──► Reagindo (fugir, atacar, enganar)
```

- **Escalada:** quanto mais tempo passa sem resolução, **mais vítimas, mais ousadia e mais pistas**. O prazo do contrato tem peso real, e a investigação fica mais fácil, mas ao custo de vidas.
- **Reação ao caçador:** depende da inteligência (ver "Caça").
- **Mudança de covil:** criaturas astutas trocam de covil se o jogador chega perto demais sem agir.

---

## Variação individual

Cada criatura gerada recebe uma **semente** que define o que pode variar **sem quebrar as regras da espécie**:

| Variável | Exemplo |
|---|---|
| **Idade** | Vampiro jovem (impulsivo, deixa mais rastros) ou ancião (cuidadoso, mais forte) |
| **Personalidade** | Cruel, faminta, arrependida, territorial |
| **Preferências** | Horário dentro do ciclo, perfil de vítima, área de caça |
| **História** | Quem era, por que está aqui, que ligação tem com os moradores |
| **Identidade humana** | Para quem se disfarça: qual NPC da cidade ela é |

---

## Matriz de distinção (validação)

Para garantir o pilar da **dedução justa**, um teste automático compara todas as espécies de uma região:

- Para cada par de espécies parecidas, deve haver **pelo menos 2 marcas** que uma tem e a outra não, ou que aparecem de forma diferente.
- Pelo menos uma dessas marcas precisa ser **detectável com equipamento inicial**, para o jogo não exigir upgrade para resolver um caso básico.
- Se uma nova criatura falha nesse teste, a ficha dela precisa ser ajustada.

---

## Exemplos de fichas (resumidas)

### Lobisomem (Brasil)

| Campo | Valor |
|---|---|
| Família | Amaldiçoado / Metamorfo |
| Ciclo | Meia-noite de sexta-feira, mais forte na lua cheia |
| Gatilho | Maldição de nascença (sétimo filho homem) ou de família |
| Necessidade | Correr sete cemitérios ou encruzilhadas, atacar animais; escala para pessoas |
| Disfarce | Morador comum: pálido, magro, some toda sexta à noite |
| Marcas | Chiqueiros e galinheiros revirados, pegadas de cão grande, pelos, animais mortos, testemunha de "cachorro enorme" |
| Fraquezas | Ferir a fera faz o humano aparecer ferido (revela e cura) |
| Resoluções | **Curar** (ferir para quebrar), prender, matar |
| Disposição | Hostil transformado; o humano é vítima da maldição |

### Strigoi (Romênia)

| Campo | Valor |
|---|---|
| Família | Morto-vivo |
| Ciclo | Noite; enfraquece de dia |
| Gatilho | Morte sem os ritos corretos, cova perturbada |
| Necessidade | Sangue, primeiro de parentes e conhecidos |
| Disfarce | Pode voltar à aparência de quando vivo |
| Marcas | Vítimas enfraquecidas ao longo de noites, marcas pequenas, animais agitados, cova remexida, corpo sem decomposição |
| Fraquezas | Alho (afasta), estaca (prende/destrói), sol (fere), grãos espalhados (obriga a contar) |
| Tabus | Precisa contar grãos e sementes |
| Resoluções | Matar (estaca e ritual na cova), prender |
| Condição | Pode transmitir vampirismo |

### Curupira (Brasil)

| Campo | Valor |
|---|---|
| Família | Entidade da natureza |
| Ciclo | Qualquer hora, dentro da mata |
| Gatilho | Caça predatória, desmatamento, desrespeito à mata |
| Necessidade | Proteger o território. Pune os infratores e pode aceitar oferendas |
| Disfarce | Raramente visto; só os efeitos aparecem |
| Marcas | **Pegadas ao contrário**, pessoas perdidas andando em círculos, assobios, caçadores desorientados ou sumidos |
| Fraquezas | Não é para ser morto. Oferenda (fumo, cachaça) apazigua, e novelo emaranhado distrai |
| Resoluções | **Apaziguar**, **negociar** (pode dar a Marca da Mata), expor quem está destruindo a mata |
| Disposição | Protetora. **O verdadeiro culpado do caso costuma ser humano.** |

### Onryō (Japão)

| Campo | Valor |
|---|---|
| Família | Espírito / assombração |
| Ciclo | Noite, principalmente na hora do boi (cerca de 2h) e no Obon |
| Gatilho | Morte injusta ou violenta, objeto ou lugar ligado à morte perturbado |
| Necessidade | Vingança contra os responsáveis e, por extensão, contra quem entra no seu espaço |
| Disfarce | Invisível; às vezes aparece como mulher de branco, de cabelo longo |
| Marcas | Frio súbito, água pingando, cabelos pretos onde não deveria, eletrônicos falhando, pesadelos repetidos nos moradores, uma morte antiga nos registros |
| Fraquezas | Ofuda (afasta), ritual de purificação, **resolver a injustiça original** (apazigua) |
| Resoluções | Apaziguar (revelar a verdade da morte), banir |
| Condição | Pode possuir pessoas, inclusive o jogador sensitivo |

---

## Bestiário inicial proposto

### Corte vertical (3 a 4 criaturas, uma região)

Para a primeira cidade, **brasileira**, com contraste entre famílias:

1. **Lobisomem (Brasil):** amaldiçoado, com resolução por cura.
2. **Curupira:** entidade da natureza, com resolução não letal e culpado humano.
3. **Corpo-seco** ou **Mula sem cabeça:** morto-vivo ou amaldiçoado, como segunda opção.
4. **Golpe humano:** um "monstro" que não existe, para o jogador aprender a duvidar.

### Fase 4 (expansão)

- **Brasil:** Boitatá, Saci, Cuca, Mapinguari, Iara.
- **Europa:** Strigoi, Lobisomem europeu, Banshee, Rusalka, Draugr.
- **Ásia:** Onryō, Kitsune, Kappa, Jiangshi.
- **Oriente Médio e África:** Djinn, Ghoul (gul), Tokoloshe (requer pesquisa cuidadosa).
- **Américas:** La Llorona, Chupacabra.

---

## Formato de dados (rascunho)

As fichas ficam em **arquivos de dados** (JSON ou recursos do Godot), não em código, para facilitar adicionar criaturas:

```json
{
  "id": "lobisomem_br",
  "nome": "Lobisomem",
  "regiao": "brasil_interior",
  "familia": ["amaldicoado", "metamorfo"],
  "natureza": "corporea",
  "inteligencia": "instintiva",
  "perigo": 3,
  "ciclo": { "horario": "meia_noite", "dias": ["sexta"], "lua": "cheia_bonus" },
  "gatilhos": ["setimo_filho", "maldicao_familia"],
  "necessidade": { "tipo": "corrida_ritual", "frequencia": "semanal", "escalada": "ataca_pessoas" },
  "marcas": [
    { "tag": "galinheiro_revirado", "onde": "cena", "freq": "comum", "detectar": "olho_nu" },
    { "tag": "pegadas_cao_grande", "onde": "cena", "freq": "sempre", "detectar": "olho_nu" },
    { "tag": "pelos_escuros", "onde": "cena", "freq": "comum", "detectar": "olho_nu" },
    { "tag": "morador_some_sexta", "onde": "testemunha", "freq": "comum", "detectar": "entrevista" }
  ],
  "fraquezas": [
    { "item": "arma_branca_benzida", "efeito": "fere_revela" },
    { "item": "figa_arruda", "efeito": "afasta" }
  ],
  "resolucoes": ["curar", "prender", "matar"],
  "condicao_transmitida": null
}
```

---

## Questões em aberto

- Quantas criaturas por região o jogo precisa ter para a dedução não ficar óbvia? Sugestão: pelo menos 6 por região na versão completa.
- Criaturas de regiões diferentes podem aparecer fora da sua região (um strigoi no Brasil)? Isso aumenta a dificuldade.
- Quanto da ficha o jogador vê no bestiário desde o início, e quanto precisa descobrir jogando?
