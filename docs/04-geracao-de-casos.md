# 04 — Geração de casos e pistas

## Objetivo

Transformar a **simulação de uma criatura** ([03](03-sistema-de-criaturas.md)) num **caso jogável**: um contrato, um lugar, vítimas, testemunhas e pistas. O resultado precisa ser:

- **Justo:** resolvível só com o que o jogador consegue encontrar.
- **Variado:** dois casos com a mesma criatura não devem parecer iguais.
- **Vivo:** o caso continua andando enquanto o jogador investiga.

## Ideia central: o caso é a história do que aconteceu

O gerador **não escreve pistas diretamente**. Ele:

1. Decide **a verdade** (o que realmente está acontecendo).
2. **Simula os dias anteriores** ao contrato, deixando a criatura agir.
3. Cada coisa que acontece **deposita marcas no mundo**: objetos, ferimentos, memórias de testemunhas, registros.
4. Essas marcas **são as pistas**.

Como as pistas vêm de eventos simulados, elas são **coerentes entre si**: a pegada, o horário, o relato da testemunha e o corpo contam a mesma história.

---

## As três perguntas do caso

Todo caso tem três perguntas. Responder mais delas libera **resoluções melhores**:

| Pergunta | O que é | Sem a resposta |
|---|---|---|
| **O quê?** | Qual espécie | Preparação errada e confronto perigoso |
| **Quem / onde?** | Qual instância: identidade humana, covil, objeto | Não encontra a criatura, ou ataca o inocente |
| **Por quê?** | O gatilho e a motivação | Só sobra matar. Curar, apaziguar e negociar exigem saber o porquê |

> Exemplo: saber que é **lobisomem** permite enfrentá-lo. Saber **quem** é permite prendê-lo antes da sexta-feira. Saber **por quê** (a maldição de família) permite **curá-lo**.

---

## Pipeline de geração

### 1. Local

- Escolhe a região e a cidade, montada com módulos ([07](07-mundo-cidades-e-npcs.md)).
- A cidade já tem a população de NPCs, com rotinas, casas e relações.

### 2. A verdade

Sorteia **a estrutura do caso**, com peso pela reputação e pela dificuldade:

| Estrutura | Verdade | Exemplo |
|---|---|---|
| **Caça simples** | Uma criatura hostil é a culpada | Strigoi atacando a família |
| **Culpado humano** | A criatura reage a um crime humano | Curupira punindo um madeireiro |
| **Golpe** | Não existe criatura: é fraude, crime ou loucura | Herdeiro forjando uma "assombração" para vender a casa |
| **Cliente mentiroso** | Quem contrata é parte do problema | Fazendeiro esconde que causou o gatilho |
| **Criatura errada** | Uma criatura inocente leva a culpa por outra | Saci pregando peças, enquanto um corpo-seco mata de verdade |
| **Caso reverso** | O jogador é a "criatura" | Caçador rival investiga o jogador ([12](12-habilidades-e-condicoes.md)) |

Casos com **duas criaturas** ao mesmo tempo ficam para depois do corte vertical.

### 3. Instância da criatura

- Escolhe a espécie no **bestiário da região** e gera a semente: idade, personalidade, preferências.
- Escolhe a **identidade humana** entre os NPCs da cidade, se a espécie tiver disfarce.
- Escolhe o **covil** num local coerente com a ficha.

### 4. História de fundo

- Gera o **gatilho concreto**: quem quebrou a regra, quando e onde.
  - Exemplo: "O fazendeiro Valdomiro começou a desmatar a grota há 3 semanas."
- Gera **ligações com NPCs**: parentes, cúmplices, quem sabe de algo.
- Gera **registros antigos**, se a espécie tiver história no lugar: notícias, certidões, lendas locais.

### 5. Pré-simulação

- Roda a simulação por **N dias antes do contrato**. N depende da dificuldade e da escalada desejada.
- Cada evento (ataque, avistamento, alimentação, mudança de covil) **deposita marcas**:
  - **Objetos e vestígios** na cena: pegadas, pelos, sangue, objetos fora do lugar.
  - **Ferimentos** nas vítimas, que o legista ou o hospital registram.
  - **Memórias** nas testemunhas que estavam por perto (ver "Testemunhas").
  - **Registros:** boletins de ocorrência, notícias, prontuários.
  - **Efeitos ambientais:** animais mortos, plantas, frio, eletrônicos.

### 6. Contrato

Gera o **cliente** e o pedido:

| Campo | Descrição |
|---|---|
| **Quem** | Vítima, parente, autoridade, fazendeiro, padre, benzedeira, ou a própria criatura |
| **O que pede** | Matar, descobrir, proteger, expulsar, provar que não é nada |
| **O que sabe** | Parte da verdade, gerada a partir das memórias dele |
| **O que esconde** | E por quê: culpa, vergonha, proteger alguém, dinheiro |
| **Recompensa** | Pelo perigo, pela região e pela reputação do jogador |
| **Prazo** | Quanto tempo antes de o cliente desistir ou a situação piorar |

### 7. Ruído

Um caso só com pistas certas é óbvio. O gerador acrescenta ruído **controlado**:

- **Pistas irrelevantes:** eventos normais da cidade (um cachorro de verdade matou galinhas, alguém brigou no bar).
- **Pistas parecidas:** marcas que outras espécies **também** deixariam, mas **nunca** o bastante para completar a assinatura de outra espécie.
- **Interpretações erradas:** NPCs que dão o nome errado ao que viram ("foi o saci!").
- **Mentiras:** do cliente e de NPCs com motivo para mentir.

### 8. Validação (teste de justiça)

Um **solucionador automático** joga o caso como um jogador iniciante:

- Considera **só o equipamento inicial** e as pistas que **ainda não expiraram** no começo do caso.
- Verifica se as pistas reduzem os candidatos a **uma espécie** (usando a matriz de distinção de [03](03-sistema-de-criaturas.md)).
- Verifica se **"Quem / onde?"** é alcançável.
- Exige **redundância**: cada distinção importante precisa ter **pelo menos 2 caminhos independentes**. Assim, perder uma pista não trava o caso.
- Se falhar, o gerador **ajusta** (acrescenta uma testemunha, revela um registro) ou **descarta** e gera de novo.

### 9. Simulação ao vivo

- A partir do contrato, a criatura **continua agindo** em tempo real ([13](13-tempo-morte-e-finais.md)).
- Novos eventos geram novas vítimas **e** novas pistas: demorar custa vidas, mas o caso fica mais claro.
- A criatura **reage ao jogador** conforme a inteligência dela.

---

## Pistas

### Modelo de uma pista

| Atributo | Descrição |
|---|---|
| **Tag** | A marca da ficha (ex.: `pegadas_invertidas`) |
| **Origem** | Criatura, humano ou ruído. **O jogador não vê isso.** |
| **Local** | Onde está no mundo |
| **Detecção** | O que é preciso para perceber: olho nu, UV, EMF, laboratório, habilidade |
| **Validade** | Quanto tempo dura antes de sumir ou se degradar |
| **Precisão** | Clara, ambígua ou distorcida (testemunhos) |

### Pistas expiram

As pistas têm **validade**, o que cria urgência e torna a ordem da investigação uma decisão:

- **Chuva** apaga pegadas.
- **Corpos** são enterrados ou cremados. Depois disso, só o laudo ou uma exumação.
- **Testemunhas** esquecem, mudam a história ou viajam.
- **A polícia** limpa e isola a cena.
- **A criatura** pode destruir provas, se for ardilosa.

### Fontes de pista

| Fonte | Exemplos | Habilidade ou equipamento útil |
|---|---|---|
| **Cena** | Pegadas, sangue, objetos, marcas | Observação, UV, câmera |
| **Corpo** | Ferimentos, causa da morte, resíduos | Forense, disfarce de jaleco ou de agente |
| **Testemunhas** | O que viram, ouviram, sentiram | Leitura de pessoas, lábia |
| **Registros** | Jornais antigos, cartório, delegacia, hospital | Pesquisa, hacking |
| **Ambiente** | Animais, plantas, temperatura, eletrônicos | EMF, câmera térmica, sensitivo |
| **Folclore local** | Benzedeira, padre, idosos, biblioteca | Ocultismo, Social |
| **Covil** | Restos, objetos pessoais, sinais da rotina | Rastreamento |

---

## Testemunhas

Os relatos são gerados a partir dos **eventos reais**, passando por um **filtro de percepção** e por **motivações**:

### Filtro de percepção

| Fator | Efeito no relato |
|---|---|
| **Distância e luz** | Detalhes vagos ("um vulto grande") |
| **Medo** | Exagero ("tinha uns três metros!") |
| **Embriaguez, idade, sono** | Detalhes errados ou trocados |
| **Cultura do NPC** | O nome que ele dá ao que viu, que pode estar errado |

> A testemunha não diz "era um lobisomem". Ela diz "um cachorro do tamanho de um bezerro, perto do chiqueiro do seu Zé, depois da meia-noite". **Quem interpreta é o jogador.**

### Motivações para mentir ou omitir

- Proteger alguém (o filho amaldiçoado, o patrão).
- Medo de retaliação.
- Vergonha (estava onde não devia).
- Querer atenção ou dinheiro.

Mentiras seguem as mesmas regras de geração: **contradizem algum fato verificável**. O jogador sempre pode pegá-las cruzando pistas.

---

## Dificuldade

O gerador tem botões que sobem com a reputação e o progresso:

| Botão | Fácil | Difícil |
|---|---|---|
| **Ruído** | Pouco | Muitas pistas irrelevantes e parecidas |
| **Inteligência da criatura** | Instintiva | Ardilosa, que planta pistas falsas |
| **Validade das pistas** | Longa | Curta, com chuva e polícia agindo rápido |
| **Espécies parecidas na região** | Poucas | Várias com marcas em comum |
| **Cliente** | Honesto | Mentiroso ou parte do problema |
| **Estrutura** | Caça simples | Criatura errada ou culpado humano |
| **Pistas avançadas** | Raras | Mais pistas que exigem equipamento melhor, **mas sempre como caminho extra, nunca o único** |

---

## Depois do caso: o mundo lembra

O resultado de cada caso **fica no mundo** e pode **gerar casos futuros**:

- A família de uma vítima vira cliente, ou inimiga, se você falhou.
- Uma criatura poupada aparece depois para cobrar ou ajudar.
- Um caçador rival que viu algo começa um **caso reverso** contra você.
- Um culpado humano que escapou causa outro problema.
- A reputação regional e a suspeita da polícia mudam ([08](08-economia-e-progressao.md)).

---

## Exemplo completo

**Cidade:** Santa Cruz do Alto, interior do Brasil (fictícia).

**Verdade (estrutura "Culpado humano" + "Cliente mentiroso"):**
- Valdomiro, fazendeiro, está desmatando ilegalmente a grota há 3 semanas.
- O **Curupira** da grota começou a desorientar e afastar os peões. Dois sumiram na mata e estão vivos, perdidos.
- Valdomiro contrata o jogador para "matar a coisa que pegou meus peões" e **esconde o desmatamento**.

**Pistas geradas pela simulação:**

| Pista | Fonte | Aponta para |
|---|---|---|
| Pegadas **viradas para trás** na trilha | Cena | Curupira (distinção-chave) |
| Peão que voltou conta que "andou em círculo a noite toda e ouviu assobio" | Testemunha | Curupira |
| Toras recém-cortadas escondidas num barracão | Cena (fazenda) | Por quê: desmatamento |
| Caminhoneiro diz que leva madeira da fazenda à noite | Testemunha | Por quê, e o cliente mente |
| Galinhas mortas no galinheiro | Ruído | Raposa de verdade |
| Moradora jura que "é o lobisomem, sempre foi" | Interpretação errada | Ruído |
| Notícia antiga de outro desmatador que "sumiu na mata" | Registro | Curupira e o padrão |

**Resoluções possíveis:**
- **Ideal:** apaziguar o Curupira com oferenda, achar os peões vivos e **expor** Valdomiro. Reputação alta, mas Valdomiro não paga. Pode até ganhar a Marca da Mata.
- **Cinza:** apaziguar e cobrar de Valdomiro sem expor. Recebe o pagamento, e o problema volta.
- **Errada:** tentar matar o Curupira. Muito perigoso, a mata pune, os peões morrem, e o "sucesso" pesa no limbo.

---

## Técnica

- **Semente reproduzível:** a mesma semente gera o mesmo caso. É essencial para testar e corrigir bugs.
- **Modo depuração:** uma tela que mostra **a verdade**, todas as pistas e a origem de cada uma.
- **Gerador em lote:** gera 100 casos e mostra estatísticas (quantos passaram na validação, distribuição de estruturas e espécies, média de pistas). É o **teste de fogo da Fase 1**.

---

## Questões em aberto

- Quantos dias de pré-simulação por caso? Sugestão: entre 3 e 21 dias, conforme a dificuldade.
- O jogador pode **recusar** um contrato depois de começar a investigar? Com que custo?
- O caso pode **falhar sozinho** (o prazo acabou, o cliente morreu, outro caçador resolveu)?
- Quanto tempo de jogo, em média, um caso deve durar? Com a carreira de 10 h e 20 a 30 casos, a referência é de **20 a 30 minutos por caso**.
