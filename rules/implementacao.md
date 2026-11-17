# rules/implementacao.md — lida ao criar funcionalidade ou commitar

## Unidades pequenas

- Uma tarefa = **um comportamento**, com o seu teste. Nada de entregar um sistema inteiro de uma vez.
- Ordem dentro da tarefa: teste que falha → código mínimo → portão verde → commit.

## Núcleo e apresentação

- `game/core/` é código puro: `extends RefCounted` (ou `Object`), sem nós, sem cenas,
  sem `get_tree()`, sem `res://presentation/` ou `res://ui/`. O teste `tests/arch/` reprova.
- A apresentação **lê** o estado do núcleo e **envia ações** a ele. Nunca o contrário.
- Todo sistema novo entra **conectado**: o que ele produz precisa ter quem use
  (pista, testemunho, carta, relatório). Sistema sem consumidor é dívida, não entrega.

## Conteúdo é dado

- Criaturas, itens, rituais, bairros e testes de campo ficam em `data/` como JSON,
  validados por esquema em `data/schemas/`. Nunca como `enum` ou constante no código.
- Adicionar uma criatura não pode exigir mudar código do núcleo.

## Docs e regras

- `rules/`, `AGENTS.md`, `CLAUDE.md`: no máximo 100 linhas (`tools/check-docs.ps1`).
  Passou disso: quebre em arquivos menores e aponte no índice.
- Os documentos de design (`docs/`) não têm teto, mas cada decisão nova vai para a seção
  "Decisões" da parte certa, e o Diário do Caçador é atualizado.

## Commits (Conventional Commits)

- Prefixos: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`.
- Trabalho de uma fase do roadmap cita a fase: `feat(fase-01): gera pistas a partir do registro`.
- Assunto curto, no imperativo, em português. Corpo explica o porquê quando não é óbvio.
- **Só commite com `.\tools\verify.ps1` em 0.**
- Mensagens com várias linhas: passe por arquivo (`git commit -F arquivo`) no PowerShell 5.1.

## Nunca commitar

- Segredos, chaves, `.env`, dados reais de pessoas, saves grandes.
- Arquivos gerados pelo Godot fora do necessário (`.godot/` já está no `.gitignore`;
  os `*.uid` **devem** ser commitados).

## Decisões grandes

- Dependência nova, mudança de formato de dados ou de save, mudança na separação
  núcleo/apresentação: registrar na parte de design certa (`docs/`) e combinar antes de codar.
