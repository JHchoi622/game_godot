extends Node2D

# 씬 노드들
var label_dialogue: RichTextLabel
var dialogue_bg: ColorRect
var background: Sprite2D
var sprite_principal: Sprite2D
var sprite_zombie: Sprite2D
var sprite_player: Sprite2D
var black_overlay: ColorRect
var red_overlay: ColorRect
var lightning_effect: ColorRect
var timer: Timer

# 전투 UI
var battle_ui: Control
var player_hp_label: Label
var zombie_hp_label: Label
var btn_attack: Button
var btn_item: Button
var battle_log: RichTextLabel

# 게임 상태
var current_sequence := 0
var player_hp := 50
var player_max_hp := 50
var player_attack := 10
var items_soup := 1

var zombie_hp := 20
var zombie_max_hp := 20
var zombie_attack := 5

var in_battle := false
var battle_phase := "player_turn"

# 스크립트 데이터
var sequences := []

# 이미지 경로
@export var principal_image_path: String = "res://images/principal.png"
@export var zombie_image_path: String = "res://images/zombie_nurse.jpg"
@export var player_image_path: String = "res://images/player.png"
@export var infirmary_bg_path: String = "res://images/infirmary.jpg"

func _ready():
	setup_sequences()
	setup_ui()
	
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	play_sequence()

func setup_sequences():
	sequences = [
		{
			"type": "show_principal",
			"duration": 0.5
		},
		{
			"type": "dialogue",
			"speaker": "교장",
			"text": "학생 여러분, 입학을 축하합니다.",
			"duration": 2.5
		},
		{
			"type": "dialogue",
			"speaker": "교장",
			"text": "…하지만 이곳은 평범한 학교가 아닙니다.",
			"duration": 2.5
		},
		{
			"type": "lightning",
			"duration": 1.0
		},
		{
			"type": "dialogue",
			"speaker": "교장",
			"text": "졸업까지 살아남은 자만이 진짜 학생이다.",
			"duration": 2.5
		},
		{
			"type": "dialogue",
			"speaker": "교장",
			"text": "수업은 전투다! 시험은 전쟁이다!!",
			"duration": 3.0
		},
		{
			"type": "fade_to_black",
			"duration": 1.5
		},
		{
			"type": "change_scene_infirmary",
			"duration": 1.0
		},
		{
			"type": "narration",
			"text": "자, 이제 첫 번째 생존 훈련이다.\n보건실에서 탈출한 좀비 간호사가 접근 중!",
			"duration": 3.5
		},
		{
			"type": "start_battle",
			"duration": 0.5
		}
	]

func setup_ui():
	# 배경
	background = Sprite2D.new()
	background.position = Vector2(640, 360)
	background.z_index = 0
	add_child(background)
	
	# 교장 스프라이트
	sprite_principal = Sprite2D.new()
	sprite_principal.position = Vector2(640, 360)
	sprite_principal.visible = false
	sprite_principal.z_index = 1
	if FileAccess.file_exists(principal_image_path):
		sprite_principal.texture = load(principal_image_path)
	add_child(sprite_principal)
	
	# 좀비 스프라이트
	sprite_zombie = Sprite2D.new()
	sprite_zombie.position = Vector2(900, 360)
	sprite_zombie.visible = false
	sprite_zombie.z_index = 1
	if FileAccess.file_exists(zombie_image_path):
		sprite_zombie.texture = load(zombie_image_path)
	add_child(sprite_zombie)
	
	# 플레이어 스프라이트
	sprite_player = Sprite2D.new()
	sprite_player.position = Vector2(350, 360)
	sprite_player.visible = false
	sprite_player.z_index = 1
	if FileAccess.file_exists(player_image_path):
		sprite_player.texture = load(player_image_path)
	add_child(sprite_player)
	
	# 검은 오버레이
	black_overlay = ColorRect.new()
	black_overlay.color = Color.BLACK
	black_overlay.size = Vector2(1280, 720)
	black_overlay.z_index = 10
	add_child(black_overlay)
	
	# 붉은 오버레이 (번개 효과)
	red_overlay = ColorRect.new()
	red_overlay.color = Color(0.8, 0.0, 0.0, 0.0)
	red_overlay.size = Vector2(1280, 720)
	red_overlay.z_index = 9
	add_child(red_overlay)
	
	# 번개 효과
	lightning_effect = ColorRect.new()
	lightning_effect.color = Color(1.0, 1.0, 0.8, 0.0)
	lightning_effect.size = Vector2(1280, 720)
	lightning_effect.z_index = 8
	add_child(lightning_effect)
	
	# 대사 배경
	dialogue_bg = ColorRect.new()
	dialogue_bg.position = Vector2(50, 580)
	dialogue_bg.size = Vector2(1180, 120)
	dialogue_bg.color = Color(0.1, 0.1, 0.2, 0.85)
	dialogue_bg.visible = false
	dialogue_bg.z_index = 11
	add_child(dialogue_bg)
	
	# 대사 라벨
	label_dialogue = RichTextLabel.new()
	label_dialogue.position = Vector2(80, 600)
	label_dialogue.size = Vector2(1120, 90)
	label_dialogue.add_theme_font_size_override("normal_font_size", 22)
	label_dialogue.bbcode_enabled = true
	label_dialogue.fit_content = true
	label_dialogue.visible = false
	label_dialogue.z_index = 12
	add_child(label_dialogue)
	
	setup_battle_ui()

func setup_battle_ui():
	battle_ui = Control.new()
	battle_ui.visible = false
	battle_ui.z_index = 15
	add_child(battle_ui)
	
	# 플레이어 HP
	player_hp_label = Label.new()
	player_hp_label.position = Vector2(100, 50)
	player_hp_label.add_theme_font_size_override("font_size", 24)
	player_hp_label.text = "플레이어 HP: 50/50"
	battle_ui.add_child(player_hp_label)
	
	# 좀비 HP
	zombie_hp_label = Label.new()
	zombie_hp_label.position = Vector2(900, 50)
	zombie_hp_label.add_theme_font_size_override("font_size", 24)
	zombie_hp_label.text = "보건실 좀비 HP: 20/20"
	battle_ui.add_child(zombie_hp_label)
	
	# 공격 버튼
	btn_attack = Button.new()
	btn_attack.position = Vector2(100, 600)
	btn_attack.size = Vector2(200, 80)
	btn_attack.text = "🥊 공격"
	btn_attack.add_theme_font_size_override("font_size", 24)
	btn_attack.pressed.connect(_on_attack_pressed)
	battle_ui.add_child(btn_attack)
	
	# 아이템 버튼
	btn_item = Button.new()
	btn_item.position = Vector2(350, 600)
	btn_item.size = Vector2(250, 80)
	btn_item.text = "🥄 급식 국물 (1)"
	btn_item.add_theme_font_size_override("font_size", 24)
	btn_item.pressed.connect(_on_item_pressed)
	battle_ui.add_child(btn_item)
	
	# 전투 로그
	battle_log = RichTextLabel.new()
	battle_log.position = Vector2(700, 450)
	battle_log.size = Vector2(500, 200)
	battle_log.add_theme_font_size_override("normal_font_size", 18)
	battle_log.bbcode_enabled = true
	battle_log.scroll_following = true
	battle_ui.add_child(battle_log)

func play_sequence():
	if current_sequence >= sequences.size():
		return
	
	var seq = sequences[current_sequence]
	
	match seq.type:
		"show_principal":
			show_principal_scene(seq.duration)
		"dialogue":
			show_dialogue(seq.speaker, seq.text, seq.duration)
		"narration":
			show_narration(seq.text, seq.duration)
		"lightning":
			play_lightning_effect(seq.duration)
		"fade_to_black":
			fade_to_black(seq.duration)
		"change_scene_infirmary":
			change_to_infirmary(seq.duration)
		"start_battle":
			start_battle()

func show_principal_scene(duration: float):
	black_overlay.modulate.a = 1.0
	sprite_principal.visible = true
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 0.0, duration)
	tween.finished.connect(_on_sequence_complete)

func show_dialogue(speaker: String, text: String, duration: float):
	dialogue_bg.visible = true
	label_dialogue.visible = true
	label_dialogue.text = "[b][color=yellow]%s[/color][/b]\n[color=white]%s[/color]" % [speaker, text]
	
	timer.start(duration)

func show_narration(text: String, duration: float):
	dialogue_bg.visible = true
	label_dialogue.visible = true
	label_dialogue.text = "[center][color=white]%s[/color][/center]" % text
	
	timer.start(duration)

func play_lightning_effect(duration: float):
	var tween = create_tween()
	# 번개 번쩍
	tween.tween_property(lightning_effect, "color:a", 0.8, 0.1)
	tween.tween_property(lightning_effect, "color:a", 0.0, 0.1)
	tween.tween_property(lightning_effect, "color:a", 0.7, 0.1)
	tween.tween_property(lightning_effect, "color:a", 0.0, 0.1)
	# 붉게 물들기
	tween.tween_property(red_overlay, "color:a", 0.4, duration * 0.6)
	tween.finished.connect(_on_sequence_complete)

func fade_to_black(duration: float):
	dialogue_bg.visible = false
	label_dialogue.visible = false
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 1.0, duration)
	tween.finished.connect(_on_sequence_complete)

func change_to_infirmary(duration: float):
	sprite_principal.visible = false
	red_overlay.color.a = 0.0
	
	# 보건실 배경으로 변경
	if FileAccess.file_exists(infirmary_bg_path):
		background.texture = load(infirmary_bg_path)
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 0.0, duration)
	tween.finished.connect(_on_sequence_complete)

func start_battle():
	dialogue_bg.visible = false
	label_dialogue.visible = false
	
	# 캐릭터 표시
	sprite_player.visible = true
	sprite_zombie.visible = true
	
	# 좀비 대사
	await get_tree().create_timer(0.5).timeout
	show_enemy_dialogue("오늘의 주사… 놓고 가야지… 크윽…")
	
	await get_tree().create_timer(2.5).timeout
	show_player_dialogue("이게… 진짜 학교 맞아!?")
	
	await get_tree().create_timer(2.5).timeout
	hide_dialogue()
	
	# 전투 시작
	in_battle = true
	battle_ui.visible = true
	update_battle_ui()
	add_battle_log("[color=yellow]⚔ 튜토리얼 전투 시작![/color]")

func show_enemy_dialogue(text: String):
	dialogue_bg.visible = true
	label_dialogue.visible = true
	label_dialogue.text = "[b][color=green]보건실 좀비[/color][/b]\n[color=white]%s[/color]" % text

func show_player_dialogue(text: String):
	dialogue_bg.visible = true
	label_dialogue.visible = true
	label_dialogue.text = "[b][color=cyan]플레이어[/color][/b]\n[color=white]%s[/color]" % text

func hide_dialogue():
	dialogue_bg.visible = false
	label_dialogue.visible = false

func _on_attack_pressed():
	if battle_phase != "player_turn":
		return
	
	battle_phase = "animating"
	disable_battle_buttons()
	
	# 플레이어 공격
	zombie_hp -= player_attack
	add_battle_log("[color=cyan]플레이어의 공격! %d 데미지![/color]" % player_attack)
	
	# 좀비 공격 애니메이션
	var tween = create_tween()
	tween.tween_property(sprite_zombie, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite_zombie, "modulate", Color.WHITE, 0.1)
	
	await get_tree().create_timer(1.0).timeout
	
	if zombie_hp <= 0:
		zombie_hp = 0
		update_battle_ui()
		battle_victory()
		return
	
	update_battle_ui()
	enemy_turn()

func _on_item_pressed():
	if battle_phase != "player_turn" or items_soup <= 0:
		return
	
	battle_phase = "animating"
	disable_battle_buttons()
	
	# 아이템 사용
	items_soup -= 1
	player_hp = min(player_hp + 20, player_max_hp)
	add_battle_log("[color=lime]급식 국물을 마셨다! HP +20 회복![/color]")
	
	await get_tree().create_timer(1.0).timeout
	
	update_battle_ui()
	enemy_turn()

func enemy_turn():
	battle_phase = "enemy_turn"
	
	await get_tree().create_timer(0.5).timeout
	
	# 적 공격
	player_hp -= zombie_attack
	add_battle_log("[color=red]좀비의 주사 공격! %d 데미지![/color]" % zombie_attack)
	
	# 플레이어 피격 애니메이션
	var tween = create_tween()
	tween.tween_property(sprite_player, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite_player, "modulate", Color.WHITE, 0.1)
	
	await get_tree().create_timer(1.0).timeout
	
	if player_hp <= 0:
		player_hp = 0
		update_battle_ui()
		battle_defeat()
		return
	
	update_battle_ui()
	battle_phase = "player_turn"
	enable_battle_buttons()

func battle_victory():
	battle_phase = "victory"
	battle_ui.visible = false
	
	# 좀비 사라짐
	var tween = create_tween()
	tween.tween_property(sprite_zombie, "modulate:a", 0.0, 1.0)
	
	await get_tree().create_timer(1.5).timeout
	
	show_narration("좋아, 첫 전투 생존 성공! 하지만 진짜 지옥은 이제부터다…", 3.0)
	
	await get_tree().create_timer(3.5).timeout
	
	show_boss_preview()

func battle_defeat():
	add_battle_log("[color=red][b]전투 패배...[/b][/color]")
	# 게임 오버 처리
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func show_boss_preview():
	# 화면 어둡게
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 0.7, 1.0)
	
	await get_tree().create_timer(1.5).timeout
	
	show_dialogue("???", "하하하! 아직은 예열 단계다.", 2.5)
	
	await get_tree().create_timer(3.0).timeout
	
	show_dialogue("???", "첫 번째 시련은 국어쌤의 문법 던전이다.", 2.5)
	
	await get_tree().create_timer(3.0).timeout
	
	show_dialogue("???", "그대의 문장력이 약하면, 그대로 멘탈이 무너질 것이다!", 3.0)
	
	await get_tree().create_timer(3.5).timeout
	
	show_chapter_title()

func show_chapter_title():
	hide_dialogue()
	sprite_player.visible = false
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "modulate:a", 1.0, 1.0)
	
	await get_tree().create_timer(1.5).timeout
	
	# 챕터 타이틀
	var chapter_label = Label.new()
	chapter_label.position = Vector2(340, 330)
	chapter_label.add_theme_font_size_override("font_size", 48)
	chapter_label.add_theme_color_override("font_color", Color.YELLOW)
	chapter_label.text = "[CHAPTER 1 – 국어쌤의 문법 지옥]"
	chapter_label.z_index = 20
	add_child(chapter_label)
	
	var title_tween = create_tween()
	title_tween.tween_property(chapter_label, "modulate:a", 1.0, 1.5)
	
	await get_tree().create_timer(4.0).timeout
	
	print("챕터 1 시작!")

func update_battle_ui():
	player_hp_label.text = "플레이어 HP: %d/%d" % [player_hp, player_max_hp]
	zombie_hp_label.text = "보건실 좀비 HP: %d/%d" % [zombie_hp, zombie_max_hp]
	btn_item.text = "🥄 급식 국물 (%d)" % items_soup
	
	if items_soup <= 0:
		btn_item.disabled = true

func disable_battle_buttons():
	btn_attack.disabled = true
	btn_item.disabled = true

func enable_battle_buttons():
	btn_attack.disabled = false
	if items_soup > 0:
		btn_item.disabled = false

func add_battle_log(message: String):
	battle_log.append_text(message + "\n")

func _on_timer_timeout():
	_on_sequence_complete()

func _on_sequence_complete():
	current_sequence += 1
	play_sequence()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not in_battle and timer.time_left > 0:
			timer.stop()
			_on_sequence_complete()
