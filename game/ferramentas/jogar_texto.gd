extends SceneTree
## Joga um caso em texto, no terminal (Fase 1).
##
## Uso:
##   godot --headless --path game -s res://ferramentas/jogar_texto.gd -- --semente=7
##   godot --headless --path game -s res://ferramentas/jogar_texto.gd -- --semente=7 --comandos=C:/caminho/comandos.txt
## Prefira o atalho: .\tools\jogar.ps1 -Semente 7

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")


func _initialize() -> void:
	var semente := 1
	var arquivo_comandos := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--semente="):
			semente = arg.trim_prefix("--semente=").to_int()
		elif arg.begins_with("--comandos="):
			arquivo_comandos = arg.trim_prefix("--comandos=")

	var caso := Gerador.gerar(semente)
	if not caso.get("valido", false):
		print("Não foi possível gerar o caso %d: %s" % [semente, str(caso.get("erros", []))])
		quit(1)
		return
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	var sessao := Sessao.new(caso, criaturas, Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])
	var jogo := Interpretador.new(sessao, criaturas, Catalogo.carregar_textos_marcas()["dados"])
	print(jogo.abertura())

	if not arquivo_comandos.is_empty():
		for linha in FileAccess.get_file_as_string(arquivo_comandos).split("\n"):
			if linha.strip_edges().is_empty() or linha.begins_with("#"):
				continue
			print("\n> %s" % linha.strip_edges())
			print(jogo.executar(linha))
			if jogo.terminou:
				break
		quit(0)
		return

	# A leitura pode trazer várias linhas de uma vez (pipe) e devolve "" no fim da entrada.
	var pendentes: Array = []
	var leituras_vazias := 0
	while not jogo.terminou:
		if pendentes.is_empty():
			printraw("\n> ")
			var bruto := OS.read_string_from_stdin(4096)
			if bruto.is_empty():
				leituras_vazias += 1
				if leituras_vazias >= 3:
					break  # fim da entrada
				continue
			leituras_vazias = 0
			pendentes.assign(bruto.replace("\r", "").split("\n"))
		var linha: String = str(pendentes.pop_front()).strip_edges()
		if linha.is_empty():
			continue
		print(jogo.executar(linha))
	quit(0)
