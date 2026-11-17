# 07 — Mundo: a cidade, bairros e NPCs

## Objetivo

Definir **onde o jogo acontece** e **quem vive lá**. A cidade é o tabuleiro onde as criaturas agem, os casos são gerados e as consequências ficam marcadas, ao longo de uma carreira e entre carreiras (legado).

---

## A cidade

- Uma **grande cidade fictícia brasileira** (nome a definir), com **comunidades de imigrantes**: japonesa, árabe, europeia, entre outras ([01](01-visao-geral.md)).
- **Uma cidade por "mundo salvo":** a cidade é gerada **uma vez**, a partir de uma semente, e **persiste** entre as carreiras do legado. Cada nova carreira encontra a mesma cidade, anos depois, mudada.
- **Clima de PS1:** névoa, luz de poste, chuva frequente, ruas estreitas, letreiros de neon nos centros comerciais ([09](09-direcao-de-arte-camera-e-personagem.md)).

### Sugestões de nome (a decidir)

São Teodoro, Vila Serena, Porto das Almas, Santa Bárbara do Oeste, Nova Esperança da Serra.

---

## Estrutura

### Bairros como áreas separadas

A recomendação é que **cada bairro seja uma área própria**, compacta e explorável a pé, e não um mundo aberto contínuo:

- **Dentro do bairro:** exploração livre a pé e de carro, com algumas ruas, praças, becos e pontos-chave.
- **Entre bairros:** o jogador escolhe o destino no **mapa da cidade** (no carro) e há uma **viagem curta**: uma cena de estrada com rádio, ou um carregamento rápido. O tempo de jogo avança conforme a distância ([13](13-tempo-morte-e-finais.md)).

**Por quê:** um mundo aberto contínuo é caro demais para um dev solo. Áreas separadas permitem bairros mais densos, carregamento simples e simulação detalhada só onde o jogador está.

### Como um bairro é montado

1. **Planta:** um layout de ruas escolhido entre alguns modelos feitos à mão para cada tipo de bairro.
2. **Quarteirões:** preenchidos com **módulos** feitos à mão (casas, prédios, lojas, terrenos, mata) e combinados proceduralmente.
3. **Pontos-chave:** os lugares importantes do bairro (ver abaixo) são encaixados em lugares reservados da planta.
4. **Variação:** cores, placas, objetos de rua, pichações, vegetação e estado de conservação mudam por semente.

Cada módulo de interior já vem com **pontos de câmera fixa** e **pontos de pista** (onde objetos de pista podem aparecer) ([09](09-direcao-de-arte-camera-e-personagem.md)).

---

## Bairros

Cada bairro tem duas camadas:

1. **Tipo** (ambiente): define as **criaturas possíveis** ([03](03-sistema-de-criaturas.md)).
2. **Comunidade** (opcional): **aumenta a chance** de criaturas daquela cultura, sem excluir as outras, e define festas, comércio, rádio, nomes e folclore local.

### Bairros propostos

| Bairro (nome provisório) | Tipo | Comunidade | Destaques |
|---|---|---|---|
| **Alto da Grota** | Mata / periferia verde | Brasileira (interior) | Chácaras, trilhas, mata fechada, benzedeira |
| **Centro Velho** | Centro / vida noturna | Mista | Bares, hotéis, delegacia central, bar dos caçadores, mercado negro escondido |
| **Vila São Bento** | Antigo / religioso | Brasileira e europeia | Cemitério antigo, igrejas, casarões, terreiro |
| **Bairro Oriental** | Residencial denso + comércio | Japonesa | Templo, mercados, festas como o Obon, yokai |
| **Rua do Comércio Árabe** | Centro / comércio | Árabe | Lojas de tecido, mesquita, djinn e ghouls |
| **Cohab Nova** | Residencial denso | Brasileira | Conjuntos habitacionais, muita gente, vampiros e metamorfos |
| **Beira-Rio** | Orla / rio | Brasileira | Pescadores, palafitas, Iara, afogados |
| **Distrito Industrial** | Industrial / abandonado | Mista | Fábricas fechadas, trilhos, criptídeos, espíritos de acidentes |

A cidade completa deve ter cerca de **8 a 10 bairros**.

### Estado do bairro

Cada bairro tem valores que **mudam com o tempo** e com as ações do jogador:

| Valor | Sobe com | Efeito |
|---|---|---|
| **Medo** | Casos não resolvidos, vítimas, boatos | Moradores trancam as portas, saem menos à noite, falam menos com estranhos, mais contratos aparecem |
| **Reputação do jogador** | Casos bem resolvidos | Pessoas falam mais, preços melhores, novos contatos ([08](08-economia-e-progressao.md)) |
| **Suspeita** | Ações arriscadas do jogador ([05](05-investigacao-e-deducao.md)) | Polícia mais presente, portas fechadas |
| **Atividade sobrenatural** | Criaturas não resolvidas, ou soltas pelo jogador | Mais casos, casos mais perigosos |

No **legado**, esses valores atravessam carreiras: um bairro que o caçador anterior abandonou pode estar tomado pelo medo anos depois.

### Abertura gradual

- A primeira carreira começa com **1 ou 2 bairros** abertos ([02](02-loop-de-jogo.md)).
- Novos bairros se abrem por **reputação**, **contatos** e **contratos** que levam até eles.

---

## Pontos-chave

| Ponto | Onde | Para que serve |
|---|---|---|
| **Delegacia** | Central e algumas de bairro | Boletins de ocorrência, depoimentos, celas (se o jogador for preso) |
| **Hospital / IML** | Centro | Prontuários, corpos, legista |
| **Biblioteca** | Pública no centro; menores em igrejas e universidade | Pesquisa confiável ([03](03-sistema-de-criaturas.md)) |
| **Lan house** | Vários bairros | Pesquisa rápida e pouco confiável |
| **Jornal** | Centro | Arquivo de notícias, jornalistas |
| **Cartório** | Centro | Certidões, histórico de famílias e imóveis |
| **Igreja, templo, mesquita, terreiro** | Bairros com essas comunidades | Folclore, água benta, rituais, zonas protegidas |
| **Cemitério** | Bairros antigos | Covas, registros de enterro, covis |
| **Bar dos caçadores** | Centro Velho (um na cidade) | Contratos difíceis, informação, rivais |
| **Mercado negro** | Escondido; abre por reputação ou condição | Materiais, itens raros, moedas por espécie ([08](08-economia-e-progressao.md)) |
| **Lojas comuns** | Vários | Ferragens, roupas, farmácia, armas (com registro) |
| **Mecânico** | Vários | Conserto do carro (caro, e faz perguntas) |
| **Motel** | Vários | Base inicial, salvar o jogo |

---

## NPCs

### População

- Os NPCs são montados com o **mesmo sistema de personagem** do jogador: corpo, rosto, roupas ([09](09-direcao-de-arte-camera-e-personagem.md)).
- Cada bairro tem cerca de **30 a 60 NPCs com identidade completa**, mais **figurantes** sem identidade para dar movimento às ruas.

### O que cada NPC tem

| Campo | Exemplo | Uso |
|---|---|---|
| **Identidade** | Nome, idade, aparência, comunidade | Reconhecer e lembrar |
| **Casa e trabalho** | Mora na Rua 3, trabalha na padaria | Onde encontrar |
| **Rotina** | Acorda às 6h, padaria das 7h às 15h, bar às 20h | Saber quando e onde ele está, e se tem álibi |
| **Relações** | Família, amigos, desafetos, patrão | Quem protege quem, quem sabe o quê |
| **Traços** | Observador, medroso, fofoqueiro, cético, religioso, bebe muito | Mudam o **filtro de percepção** das testemunhas ([04](04-geracao-de-casos.md)) |
| **Segredos** | Caso extraconjugal, dívida, crime antigo | Motivos para mentir |
| **Crenças** | Folclore da comunidade dele | O nome que ele dá ao que viu (às vezes errado) |
| **Memórias** | Eventos que presenciou | De onde vêm os depoimentos |

### Rotinas e simulação

- No estilo de *Shadows of Doubt*, os NPCs seguem **rotinas diárias**: casa, trabalho, lazer, sono.
- **Simulação em níveis de detalhe:**
  - **Bairro atual:** simulação completa, com cada NPC andando, trabalhando, dormindo.
  - **Outros bairros:** simulação **resumida**, que registra só os eventos importantes (onde cada um estava, quem viu o quê).
- Isso permite **álibis** ("ele estava no bar às 23h") e **testemunhas coerentes** sem pesar no desempenho.

### NPCs especiais

| Papel | Exemplos | O que oferecem |
|---|---|---|
| **Mentor** | Caçador veterano, ou o seu personagem anterior ([02](02-loop-de-jogo.md)) | Tutorial, treino, conselhos |
| **Contatos** | Legista, policial, bibliotecária, benzedeira, padre, mecânico, jornalista, receptador | Acesso, informação, serviços, favores |
| **Clientes** | Gerados para cada caso | Contratos |
| **Caçadores rivais** | Outros caçadores da cidade | Competição, alianças, caça contra o jogador ([12](12-habilidades-e-condicoes.md)) |
| **Criaturas disfarçadas** | Um morador comum que é a criatura do caso | O alvo do "Quem?" |

### Contatos

- Cada contato tem um nível de **confiança** com o jogador.
- A confiança sobe com favores, presentes, casos resolvidos que ajudaram o contato.
- Contatos podem **pedir favores** em troca, **mudar de bairro**, **ser vítimas** de criaturas, ou **trair** o jogador se a suspeita estiver alta.

---

## Polícia e suspeita

- A polícia é uma força **humana e cega ao sobrenatural**: ela vê invasões, armas e corpos, não monstros.
- A **suspeita** existe em cada bairro e também de forma geral na cidade.

| Nível | Efeito |
|---|---|
| **Normal** | Nada |
| **Observado** | Viaturas passam mais vezes, policiais pedem documentos, alguns contatos ficam receosos |
| **Procurado** | A polícia aborda o jogador, pode **deter**, apreender equipamento e rebocar o carro ([08](08-economia-e-progressao.md)) |
| **Barrado** | Entrar no bairro vira risco de prisão imediata |

- **Reduzir a suspeita:** tempo, disfarces, contatos na polícia, suborno, ficar longe do bairro.
- **Ser preso:** perde tempo (o caso continua andando), paga fiança, e o equipamento pode ser apreendido.

---

## Vida da cidade

- **Dia e noite:** de dia, ruas cheias e lojas abertas. De noite, ruas vazias, bares e criaturas.
- **Clima:** chuva apaga pegadas ([04](04-geracao-de-casos.md)), neblina reduz a visão, o calor muda rotinas.
- **Eventos comuns:** brigas, furtos, acidentes, festas. São o **ruído** natural dos casos.
- **Datas e festas das comunidades:** Festa Junina, Finados, Carnaval, Obon, Ramadã, Sexta-feira 13. Mudam a rotina dos NPCs, o comportamento das criaturas e geram contratos especiais ([13](13-tempo-morte-e-finais.md)).
- **Mudanças ao longo dos anos:** bairros podem melhorar ou decair, comércios fecham e abrem, NPCs envelhecem, se mudam, morrem e têm filhos.

---

## Deslocamento

| Meio | Quando | Observação |
|---|---|---|
| **A pé** | Dentro do bairro | Silencioso, lento |
| **Carro** | Dentro e entre bairros | Rápido, leva o porta-malas, pode ser reconhecido |
| **Ônibus / táxi** | Quando o carro quebra ou foi apreendido | Mais lento, sem porta-malas, custa dinheiro |

---

## Escopo no roadmap

- **Fase 1 (só texto):** um bairro abstrato com uma lista de NPCs, rotinas e locais.
- **Fase 2 (greybox):** uma rua e uma casa em módulos cinza.
- **Corte vertical:**
  - **2 bairros:** Alto da Grota (mata) e Vila São Bento (antigo/religioso).
  - Cerca de 30 NPCs com identidade em cada um, com rotinas.
  - Pontos-chave: delegacia, biblioteca, igreja, benzedeira, cemitério, motel, mecânico, lan house.
  - Suspeita e polícia básicas.
- **Depois:** os demais bairros, comunidades, mercado negro, mudanças de longo prazo.

## Questões em aberto

- Nome da cidade.
- Bairros separados com mapa (recomendado) ou cidade contínua?
- Quantos bairros na versão completa? Sugestão: 8 a 10.
- A cidade é a mesma para todos os jogadores (feita à mão em alto nível) ou gerada por semente para cada novo mundo?
