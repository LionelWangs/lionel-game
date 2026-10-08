extends Node
## 背景音乐（autoload: Music）
## 首个输入事件之后才真正开声，兼容浏览器/移动端的自动播放限制。

const VOLUME_DB := -14.0

var enabled := true
var current := ""

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _active := 0
var _pending := ""
var _input_seen := false
var _fade: Tween


func _ready() -> void:
	for _i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	enabled = GameState.music_on


func _input(event: InputEvent) -> void:
	if _input_seen:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		_input_seen = true
		if _pending != "":
			var track := _pending
			_pending = ""
			_play_now(track)


func play(track: String) -> void:
	if current == track and _players[_active].playing:
		return
	current = track
	if not enabled:
		return
	if not _input_seen:
		_pending = track
		return
	_play_now(track)


func set_enabled(on: bool) -> void:
	enabled = on
	if not enabled:
		_fade_out()
	elif current != "":
		_play_now(current)


func toggle() -> bool:
	set_enabled(not enabled)
	return enabled


func _play_now(track: String) -> void:
	if not _streams.has(track):
		_streams[track] = MusicFactory.title_loop() if track == "title" else MusicFactory.game_loop()
	var next := 1 - _active
	var old := _players[_active]
	var player := _players[next]
	player.stream = _streams[track]
	player.volume_db = -80.0
	player.play()
	_active = next
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", VOLUME_DB, 0.9)
	_fade.parallel().tween_property(old, "volume_db", -80.0, 0.9)
	_fade.chain().tween_callback(old.stop)


func _fade_out() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	var player := _players[_active]
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", -80.0, 0.4)
	_fade.tween_callback(player.stop)
