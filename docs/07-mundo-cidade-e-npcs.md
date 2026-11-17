# 07 — Mundo: a cidade, bairros e NPCs

## Objetivo

Definir **onde o jogo acontece** e **quem vive lá**. A cidade é o tabuleiro onde as criaturas agem, os casos são gerados e as consequências ficam marcadas, ao longo de uma carreira e entre carreiras (legado).

---

## A cidade: Santos

O jogo se passa em **Santos (SP)**, uma versão sobrenatural da cidade real.

### Por que Santos combina com o jogo

- **Porto:** por onde passa gente e mercadoria do mundo inteiro. Isso explica, dentro do mundo, por que criaturas de todas as culturas aparecem na mesma cidade.
- **Imigração:** a cidade foi porta de entrada de imigrantes. O navio *Kasato Maru*, que trouxe os primeiros imigrantes japoneses ao Brasil em 1908, chegou pelo porto de Santos.
- **Paisagem variada:** orla, centro histórico, porto, morros com mata atlântica, zona noroeste com mangue e palafitas, e uma área continental quase toda de mata e rios.
- **Canais e marés:** os canais de drenagem que cortam a cidade e as ressacas dão um clima único de água, névoa e inundação, perfeito para a estética PS1 ([09](09-direcao-de-arte-camera-e-personagem.md)).

### A mesma cidade, com estrutura procedural

| O que é **fixo** (igual para todos os jogadores) | O que é **procedural** (gerado pela semente de cada mundo) |
|---|---|
| O **traçado real das ruas**, em escala reduzida (ver "Mapa real em escala reduzida") | Os prédios de cada lote, com módulos de casas, prédios, lojas e terrenos |
| A lista de bairros, com nome e **limites reais** | Os interiores |
| A zona de cada bairro e quais bairros são vizinhos | A população de NPCs, rotinas e relações |
| Os marcos e pontos históricos reais (porto, orla, canais, Monte Serrat, cemitérios históricos) | A posição dos pontos-chave menores |
| O relevo dos morros | Os túneis do subterrâneo (seguindo as ruas) |
| As comunidades e o folclore de cada zona | Os casos, as criaturas e os segredos |

O jogador reconhece **as ruas de Santos**, mas cada mundo tem **prédios, pessoas e histórias diferentes**. A cidade gerada **persiste** entre as carreiras do legado.

### Mapa real em escala reduzida

O traçado da cidade vem do **mapa real**, importado de dados abertos (OpenStreetMap), e **reduzido em escala**.

- **Escala: 1:3.** A ilha passa de cerca de 39 km² para cerca de **4,3 km²**. Um bairro médio fica com cerca de **280 m de lado**, uns 3 a 4 minutos a pé de ponta a ponta.
- **Só as distâncias encolhem.** Ruas, calçadas, casas e pessoas continuam em tamanho humano. Por isso o mapa é **simplificado**: ficam as avenidas, os canais, a orla e as ruas importantes, e as ruas menores são fundidas ou removidas.
- **Relevo:** os morros usam dados públicos de altitude. A altura é reduzida **menos** que as distâncias, para os morros continuarem parecendo morros.
- **Área continental:** é quase toda mata. Entram só os núcleos habitados (como Caruara, Monte Cabrão e Ilha Diana), bem mais comprimidos, com mata entre eles.
- **Desempenho:** os dados do mapa ocupam poucos MB. Com bairros carregados separadamente e a estética PS1, o custo de desempenho é baixo.

#### Ferramenta de importação

Uma ferramenta feita uma vez (estimativa: **3 a 6 semanas**) que:

1. Lê os dados de ruas, limites de bairro, canais e pontos históricos.
2. Simplifica o traçado e aplica a escala.
3. Gera ruas, calçadas, canais e o relevo no Godot.
4. Marca os **lotes vazios** onde o gerador procedural coloca os prédios.
5. Corta a cidade nos **limites de cada bairro**, transformando as ruas que cruzam o limite em saídas para o bairro vizinho.

Depois disso, cada bairro precisa de um **ajuste manual** curto (meio dia a um dia).

#### Licença

- Os dados do OpenStreetMap usam a licença **ODbL**. O jogo precisa dar o crédito "© colaboradores do OpenStreetMap". Confirmar os detalhes da licença antes de publicar.
- Se os limites de bairro estiverem incompletos no OpenStreetMap, usar os mapas da prefeitura ou traçar os limites à mão.

### Cuidado com a cidade real

- **Nada de pessoas ou empresas reais:** NPCs, lojas e instituições são fictícios. Marcos públicos (porto, orla, canais, morros, cemitérios) podem aparecer.
- **Não estigmatizar bairros:** bairros pobres, morros e palafitas não podem ser retratados como "lugares de monstro" ou de criminosos. As criaturas aparecem **em toda a cidade**, inclusive na orla rica, e os moradores de cada bairro são tratados com a mesma dignidade.
- **Pesquisa local:** consultar moradores e fontes da cidade para acertar o clima, o sotaque, as comidas, as festas e as histórias de cada zona.

---

## Bairros

### Quantidade

A versão completa usa **os bairros de Santos**. A referência é a [lista de bairros de Santos da Wikipédia](https://pt.wikipedia.org/wiki/Lista_de_bairros_de_Santos), com **66 bairros**, agrupados em 5 zonas. Não há um número oficial confirmado: outras fontes falam em 58 bairros. A lista final precisa ser conferida com a prefeitura.

| Zona | Bairros | Tipo predominante no jogo |
|---|---|---|
| **Orla e intermediária** | Aparecida, Boqueirão, Embaré, Gonzaga, José Menino, Pompeia, Ponta da Praia | Residencial denso, vida noturna, orla |
| **Central e portuária** | Campo Grande, Centro, Encruzilhada, Estuário, Jabaquara, Macuco, Marapé, Paquetá, Saboó, Valongo, Vila Belmiro, Vila Mathias, Vila Nova, Vila Rica e os setores do porto (Alemoa, Macuco, Paquetá, Ponta da Praia, Saboó, Valongo) | Antigo/religioso, centro/comércio, industrial/porto |
| **Morros** | Monte Serrat, Cachoeira, Caneleira, Chico de Paula, Nova Cintra, Embaré, Fontana, Jabaquara, José Menino, Marapé, Pacheco, Penha, Saboó, Santa Maria, Santa Teresinha, São Bento | Mata, residencial |
| **Noroeste** | Alemoa, Areia Branca, Bom Retiro, Caneleira, Chico de Paula, Castelo, Piratininga, São Manoel, Outeirinho, Rádio Clube, Santa Maria, São Jorge, Vila Haddad | Residencial denso, mangue/rio |
| **Área continental** | Barnabé, Cabuçu, Caruara, Guarapará, Ilha Diana, Iriri, Monte Cabrão, Quilombo, Sítio das Neves, Trindade | Mata, rio, mangue |

### Alerta de escopo

**66 bairros é muita coisa para um dev solo.** Para tornar isso possível:

- **Bairros como áreas separadas** (decidido): cada bairro é uma área compacta, e o jogador se desloca entre eles pelo mapa.
- **Mapa real importado:** o traçado das ruas vem pronto dos dados abertos, então não é preciso desenhar plantas.
- **Kits por zona:** bairros da mesma zona compartilham módulos e paleta. Os 16 morros, por exemplo, usam o mesmo kit de módulos com variações.
- **Bairros principais e secundários:** cerca de 15 a 20 bairros **principais** recebem marcos e pontos-chave próprios. Os outros são **secundários**, montados só com o kit da zona.
- **Abertura por zona:** a cidade abre zona por zona ao longo da carreira ([02](02-loop-de-jogo.md)), e o desenvolvimento também pode ser feito zona por zona.

### Como um bairro é montado

1. **Planta:** o traçado real das ruas do bairro, importado e reduzido (ver "Mapa real em escala reduzida").
2. **Lotes:** preenchidos com **módulos** feitos à mão (casas, prédios, lojas, terrenos, mata) e combinados proceduralmente, usando o kit da zona.
3. **Marcos:** os marcos fixos do bairro (ex.: o Monte Serrat, um canal, o cais) são encaixados em lugares reservados.
4. **Pontos-chave:** delegacia, igreja, biblioteca e outros (ver abaixo), conforme o bairro.
5. **Variação:** cores, placas, objetos de rua, pichações, vegetação e conservação mudam pela semente.

Cada módulo de interior já vem com **pontos de câmera fixa** e **pontos de pista** ([09](09-direcao-de-arte-camera-e-personagem.md)).

### Tipo e comunidade

Cada bairro tem duas camadas:

1. **Tipo** (ambiente): define as **criaturas possíveis** ([03](03-sistema-de-criaturas.md)).
2. **Comunidade** (opcional): **aumenta a chance** de criaturas daquela cultura, sem excluir as outras, e define festas, comércio, rádio, nomes e folclore local. A distribuição das comunidades pelos bairros deve seguir a **pesquisa sobre a história real** da imigração na cidade.

### Estado do bairro

Cada bairro tem valores que **mudam com o tempo** e com as ações do jogador:

| Valor | Sobe com | Efeito |
|---|---|---|
| **Medo** | Casos não resolvidos, vítimas, boatos | Moradores trancam as portas, saem menos à noite, falam menos com estranhos, mais contratos aparecem |
| **Reputação do jogador** | Casos bem resolvidos | Pessoas falam mais, preços melhores, novos contatos ([08](08-economia-e-progressao.md)) |
| **Suspeita** | Ações arriscadas do jogador ([05](05-investigacao-e-deducao.md)) | Polícia mais presente, portas fechadas |
| **Atividade sobrenatural** | Criaturas não resolvidas, ou soltas pelo jogador | Mais casos, casos mais perigosos |

No **legado**, esses valores atravessam carreiras.

### Abertura gradual

- A primeira carreira começa com **1 ou 2 bairros** abertos ([02](02-loop-de-jogo.md)).
- Novos bairros se abrem por **reputação**, **contatos** e **contratos** que levam até eles.

---

## Esgotos e subterrâneo

Por baixo da cidade existe uma **segunda camada**: esgotos, galerias de águas pluviais, túneis de serviço, porões e partes cobertas dos canais.

### Como funciona

- **Uma área subterrânea por bairro**, ligada às dos bairros vizinhos.
- **Entradas:** bueiros, bocas de lobo, saídas dos canais, porões de casarões, galpões do porto.
- **Montagem procedural** com módulos de túnel: retas, cruzamentos, câmaras, escadas, comportas, desmoronamentos.
- **Os túneis seguem as ruas reais**, como acontece na vida real. Assim, quem conhece a superfície consegue se orientar embaixo.
- **Visual PS1 claustrofóbico:** escuridão total fora da lanterna, água até o joelho, eco, goteiras ([09](09-direcao-de-arte-camera-e-personagem.md)).

### Para que serve

| Uso | Detalhe |
|---|---|
| **Covis** | Muitas criaturas se escondem no subterrâneo: ghouls, bestas, criptídeos, espíritos de afogados, lendas urbanas como o "jacaré do esgoto" |
| **Pistas** | Restos, objetos arrastados, marcas nas paredes, corpos levados pela água |
| **Atalhos** | Ir de um bairro vizinho a outro sem passar pela rua |
| **Fuga** | Escapar da polícia ou de uma criatura da superfície |
| **Mercado negro** | Uma das entradas do mercado oculto pode ser por baixo da cidade ([08](08-economia-e-progressao.md)) |

### Perigos

- **Maré e chuva:** com a **maré alta** e chuva forte, as galerias **inundam**. Caminhos ficam bloqueados, pistas são levadas pela água e há risco de afogamento. A **tábua de marés** fica no caderno e passa a fazer parte do planejamento.
- **Gases:** bolsões de gás exigem máscara. Fogo e disparos perto deles são muito perigosos.
- **Se perder:** sem mapa e com pouca luz, é fácil se desorientar.
- **Sujeira:** sair do esgoto com a roupa suja e o cheiro **aumenta a suspeita** até se trocar ([09](09-direcao-de-arte-camera-e-personagem.md)).
- **Doenças:** ferimentos abertos no esgoto podem infeccionar.

### Equipamento útil

Lanterna forte, botas de borracha, máscara de gás, corda, mapa das galerias (comprado de um funcionário ou desenhado aos poucos no caderno).

---

## Pontos-chave

| Ponto | Onde | Para que serve |
|---|---|---|
| **Delegacia** | Central e algumas de bairro | Boletins de ocorrência, depoimentos, celas (se o jogador for preso) |
| **Hospital / IML** | Centro | Prontuários, corpos, legista |
| **Biblioteca** | Pública no centro; menores em igrejas e universidades | Pesquisa confiável ([03](03-sistema-de-criaturas.md)) |
| **Lan house** | Vários bairros | Pesquisa rápida e pouco confiável |
| **Jornal** | Centro | Arquivo de notícias, jornalistas |
| **Cartório** | Centro | Certidões, histórico de famílias e imóveis |
| **Igreja, templo, mesquita, terreiro** | Conforme a comunidade | Folclore, água benta, rituais, zonas protegidas |
| **Cemitério** | Bairros antigos | Covas, registros de enterro, covis |
| **Porto e cais** | Zona portuária | Contêineres, navios, contrabando, criaturas que chegam de fora |
| **Bar dos caçadores** | Centro (um na cidade) | Contratos difíceis, informação, rivais |
| **Mercado negro** | Escondido; abre por reputação ou condição | Materiais, itens raros, moedas por espécie ([08](08-economia-e-progressao.md)) |
| **Balsa / barco** | Ligação com a área continental e ilhas | Deslocamento até bairros isolados como Ilha Diana |
| **Lojas comuns** | Vários | Ferragens, roupas, farmácia, armas (com registro) |
| **Mecânico** | Vários | Conserto do carro (caro, e faz perguntas) |
| **Motel** | Vários | Base inicial, salvar o jogo |

---

## NPCs

### População

- Os NPCs são montados com o **mesmo sistema de personagem** do jogador: corpo, rosto, roupas ([09](09-direcao-de-arte-camera-e-personagem.md)).
- Cada bairro **principal** tem cerca de **30 a 60 NPCs com identidade completa**. Bairros **secundários** têm menos, e todos têm **figurantes** para dar movimento às ruas.

### O que cada NPC tem

| Campo | Exemplo | Uso |
|---|---|---|
| **Identidade** | Nome, idade, aparência, comunidade | Reconhecer e lembrar |
| **Casa e trabalho** | Mora na Rua 3, trabalha no porto | Onde encontrar |
| **Rotina** | Acorda às 5h, turno no porto das 6h às 14h, bar às 20h | Saber quando e onde ele está, e se tem álibi |
| **Relações** | Família, amigos, desafetos, patrão | Quem protege quem, quem sabe o quê |
| **Traços** | Observador, medroso, fofoqueiro, cético, religioso, bebe muito | Mudam o **filtro de percepção** das testemunhas ([04](04-geracao-de-casos.md)) |
| **Segredos** | Caso extraconjugal, dívida, crime antigo | Motivos para mentir |
| **Crenças** | Folclore da comunidade dele | O nome que ele dá ao que viu (às vezes errado) |
| **Memórias** | Eventos que presenciou | De onde vêm os depoimentos |

### Rotinas e simulação

- No estilo de *Shadows of Doubt*, os NPCs seguem **rotinas diárias**: casa, trabalho, lazer, sono.
- **Simulação em níveis de detalhe:**
  - **Bairro atual:** simulação completa.
  - **Outros bairros:** simulação **resumida**, que registra só os eventos importantes.
- Isso permite **álibis** e **testemunhas coerentes** sem pesar no desempenho.

### NPCs especiais

| Papel | Exemplos | O que oferecem |
|---|---|---|
| **Mentor** | Caçador veterano, ou o seu personagem anterior ([02](02-loop-de-jogo.md)) | Tutorial, treino, conselhos |
| **Contatos** | Legista, policial, bibliotecária, benzedeira, padre, mecânico, jornalista, estivador, receptador | Acesso, informação, serviços, favores |
| **Clientes** | Gerados para cada caso | Contratos |
| **Caçadores rivais** | Outros caçadores da cidade | Competição, alianças, caça contra o jogador ([12](12-habilidades-e-condicoes.md)) |
| **Criaturas disfarçadas** | Um morador comum que é a criatura do caso | O alvo do "Quem?" |

### Contatos

- Cada contato tem um nível de **confiança** com o jogador, que sobe com favores, presentes e casos resolvidos.
- Contatos podem **pedir favores**, **mudar de bairro**, **ser vítimas** de criaturas, ou **trair** o jogador se a suspeita estiver alta.

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

- **Dia e noite:** de dia, ruas cheias, porto em movimento. De noite, orla vazia, bares no centro, criaturas.
- **Clima e mar:** chuva apaga pegadas ([04](04-geracao-de-casos.md)), neblina vinda do mar reduz a visão, **ressacas** alagam a orla e as galerias.
- **Marés:** a maré sobe e desce ao longo do dia e afeta canais, mangues, esgotos e algumas criaturas.
- **Eventos comuns:** brigas, furtos, acidentes, navios chegando, festas. São o **ruído** natural dos casos.
- **Datas e festas:** Festa Junina, Finados, Carnaval, festas das comunidades imigrantes, Sexta-feira 13. Mudam a rotina dos NPCs, o comportamento das criaturas e geram contratos especiais ([13](13-tempo-morte-e-finais.md)).
- **Mudanças ao longo dos anos:** bairros melhoram ou decaem, comércios fecham e abrem, NPCs envelhecem, se mudam, morrem e têm filhos.

---

## Deslocamento

| Meio | Quando | Observação |
|---|---|---|
| **A pé** | Dentro do bairro | Silencioso, lento |
| **Carro** | Dentro e entre bairros | Rápido, leva o porta-malas, pode ser reconhecido |
| **Esgotos** | Entre bairros vizinhos, por baixo | Discreto, perigoso, sujo |
| **Ônibus / táxi** | Quando o carro quebra ou foi apreendido | Mais lento, sem porta-malas, custa dinheiro |
| **Balsa / barco** | Para a área continental e ilhas | Horários fixos |

---

## Escopo no roadmap

- **Fase 1 (só texto):** um bairro abstrato com uma lista de NPCs, rotinas e locais.
- **Fase 2 (greybox):** uma rua, uma casa e um trecho de esgoto em módulos cinza.
- **Corte vertical:**
  - **2 bairros:** um de mata (por exemplo, um **morro** como o São Bento ou o Monte Serrat) e um antigo (por exemplo, **Paquetá** ou **Valongo**, no centro histórico).
  - O subterrâneo desses 2 bairros, ligando um ao outro.
  - Cerca de 30 NPCs com identidade em cada bairro, com rotinas.
  - Pontos-chave: delegacia, biblioteca, igreja, benzedeira, cemitério, motel, mecânico, lan house.
  - Suspeita e polícia básicas, maré básica.
- **Depois:** as demais zonas, uma por vez.

## Decisões

- **Nome da cidade:** Santos (SP).
- **Bairros:** áreas separadas, com mapa.
- **Quantidade:** os bairros reais de Santos (cerca de 66 pela lista de referência, a confirmar).
- **Mesma cidade para todos:** traçado real das ruas, limites de bairro e pontos históricos, em escala 1:3. Prédios, interiores, NPCs e casos são gerados por semente.
- **Esgotos e subterrâneo:** incluídos como segunda camada da cidade.

## Questões em aberto

- Quais bairros são **principais** e quais são **secundários**?
- Os setores do **porto** contam como bairros jogáveis separados ou como uma área portuária só?
- A **área continental** entra desde o começo ou só mais tarde na carreira?
- Os dados do OpenStreetMap para Santos (ruas e limites de bairro) estão completos? Verificar antes de construir a ferramenta.
