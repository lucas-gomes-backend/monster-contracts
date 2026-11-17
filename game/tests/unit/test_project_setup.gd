extends "res://tests/framework/test_case.gd"
## Confere a configuração básica do projeto (docs/09 e docs/10).


func test_resolucao_interna_ps1() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 640, "largura interna")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 480, "altura interna")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport", "modo de ampliação")


func test_renderizador_leve() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")


func test_cena_inicial_existe() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_false(main_scene.is_empty(), "cena inicial configurada")
	assert_true(ResourceLoader.exists(main_scene), "arquivo da cena inicial")


func test_cena_inicial_carrega() -> void:
	var packed: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	assert_true(packed != null, "a cena carrega")
	if packed:
		var node := packed.instantiate()
		assert_true(node != null, "a cena instancia")
		if node:
			node.free()
