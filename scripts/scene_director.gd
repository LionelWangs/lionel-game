extends Node
## 场景切换与像素溶解过场（autoload: SceneDirector）

const DITHER_SHADER := """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fill_color : source_color = vec4(0.055, 0.043, 0.063, 1.0);

const float BAYER[16] = {
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
};

void fragment() {
	vec2 cell = floor(UV * vec2(640.0, 360.0));
	int x = int(mod(cell.x, 4.0));
	int y = int(mod(cell.y, 4.0));
	float threshold = BAYER[y * 4 + x] / 16.0;
	float a = threshold < progress ? 1.0 : 0.0;
	COLOR = vec4(fill_color.rgb, a);
}
"""

var cutscene_beats: Array = []
var after_cutscene := ""
## 非空表示处于截图自检模式：跳过转场动画，窗口置顶，保证不依赖帧率
var shot_mode := ""

var _cover: ColorRect
var _mat: ShaderMaterial
var _progress := 0.0
var _busy := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			shot_mode = arg
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var shader := Shader.new()
	shader.code = DITHER_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("progress", 0.0)
	_cover = ColorRect.new()
	_cover.material = _mat
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_cover)
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	if shot_mode != "":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_move_to_foreground()


## 带像素溶解转场的场景切换
func goto_scene(path: String, dur := 0.4) -> void:
	if shot_mode != "":
		print("DIRECTOR goto ", path, " busy=", _busy)
	if _busy:
		return
	if shot_mode != "":
		# 自检模式：不做转场动画，直接切场景（保持透明，避免截图被遮罩盖住）
		_set_progress(0.0)
		get_tree().change_scene_to_file(path)
		return
	_busy = true
	await _fade_to(1.0, dur)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, dur)
	_busy = false


func play_cutscene(beats: Array, next_path: String) -> void:
	cutscene_beats = beats
	after_cutscene = next_path
	goto_scene("res://scenes/cutscene.tscn")


func finish_cutscene() -> void:
	var next := after_cutscene
	if next == "":
		next = "res://scenes/game.tscn"
	if shot_mode != "":
		print("DIRECTOR finish_cutscene -> ", next)
	goto_scene(next)


func is_busy() -> bool:
	return _busy


func _fade_to(target: float, dur: float) -> void:
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_method(_set_progress, _progress, target, dur)
	await tw.finished
	if is_equal_approx(target, 0.0):
		_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_progress(v: float) -> void:
	_progress = v
	_mat.set_shader_parameter("progress", v)


## 截图并退出（供 --shot-* 自检使用）
func save_shot(name: String) -> void:
	print("DIRECTOR save_shot ", name)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var suffix := "-zh" if TranslationServer.get_locale().begins_with("zh") else ""
	var path := "res://debug/%s%s.png" % [name, suffix]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot saved: ", path)
	get_tree().quit()
