extends SceneTree
## Gerador em lote (ferramenta de desenvolvimento, docs/10): gera N casos e mostra as
## estatísticas (core/casos/estatisticas.gd). Não faz parte do jogo.
##
## Uso:
##   godot --headless --path game -s res://ferramentas/lote.gd -- --casos=100 --inicio=1 --saida=C:/caminho/lote.json
## Prefira o atalho: .\tools\lote.ps1

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Estatisticas := preload("res://core/casos/estatisticas.gd")


func _initialize() -> void:
	var quantidade := 100
	var inicio := 1
	var saida := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--casos="):
			quantidade = maxi(1, arg.trim_prefix("--casos=").to_int())
		elif arg.begins_with("--inicio="):
			inicio = arg.trim_prefix("--inicio=").to_int()
		elif arg.begins_with("--saida="):
			saida = arg.trim_prefix("--saida=")

	var casos: Array = []
	for semente in range(inicio, inicio + quantidade):
		var caso := Gerador.gerar(semente)
		casos.append(caso)
		# O registro não vira JSON; o resto do caso não precisa sair daqui.
	var resumo := Estatisticas.resumir(casos)
	_imprimir(resumo, inicio, quantidade)
	if not saida.is_empty():
		var arquivo := FileAccess.open(saida, FileAccess.WRITE)
		if arquivo:
			arquivo.store_string(JSON.stringify(resumo, "  ", true) + "\n")
			print("Relatório salvo em %s" % saida)
		else:
			print("Não foi possível salvar em %s" % saida)
	quit(0)


func _imprimir(r: Dictionary, inicio: int, quantidade: int) -> void:
	print("")
	print("== Lote de casos: sementes %d a %d ==" % [inicio, inicio + quantidade - 1])
	print("Casos justos: %d de %d (%.1f%%)" % [r["validos"], r["casos"], float(r["taxa_validos"]) * 100.0])
	print("Tentativas: média %.2f, máximo %d, justos de primeira %.1f%%" % [r["tentativas"]["media"], r["tentativas"]["maximo"], float(r["tentativas"]["primeira_tentativa"]) * 100.0])
	print("Estruturas: %s" % _linha(r["estruturas"]))
	print("Espécies:   %s" % _linha(r["especies"]))
	print("Pistas por caso: média %.1f (mín %d, máx %d)" % [r["pistas"]["media"], r["pistas"]["minimo"], r["pistas"]["maximo"]])
	print("  por tipo (média): %s" % _linha(r["pistas"]["por_tipo"]))
	print("Depoimentos por caso: média %.1f (mín %d, máx %d)" % [r["depoimentos"]["media"], r["depoimentos"]["minimo"], r["depoimentos"]["maximo"]])
	print("Evidências do iniciante: média %.1f (mín %d)" % [r["evidencias_do_iniciante"]["media"], r["evidencias_do_iniciante"]["minimo"]])
	print("Mentiras: %s" % _linha(r["mentiras"]))
	print("Ruídos por caso: %.1f | Boletins por caso: %.1f | Casos com chuva: %.1f%%" % [r["ruidos"]["media"], r["boletins"]["media"], float(r["chuva"]) * 100.0])
	print("Motivos de descarte:")
	var motivos: Array = r["descartes"].keys()
	motivos.sort_custom(func(a, b): return int(r["descartes"][a]) > int(r["descartes"][b]))
	for m in motivos:
		print("  %4d  %s" % [r["descartes"][m], m])
	print("")


func _linha(contagem: Dictionary) -> String:
	var chaves := contagem.keys()
	chaves.sort()
	var partes: Array = []
	for k in chaves:
		partes.append("%s %s" % [k, str(contagem[k])])
	return ", ".join(partes) if not partes.is_empty() else "-"
