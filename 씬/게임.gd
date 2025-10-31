extends Node2D

# 씬 노드들
var label_narration: RichTextLabel
var label_thought: RichTextLabel
var narration_bg: ColorRect
var thought_bg: ColorRect
var background: Sprite2D
var sprite_principal: Sprite2D
var black_overlay: ColorRect
var timer: Timer

# 스크립트 데이터
var current_sequence := 0
var sequences := [
	{
		"type": "fade_in",
		"duration": 2.0
	},
	{
		"type": "narration",
		"text": "여기는 대한민국 최강의 던전, 공포의 ○○고등학교.",
		"duration": 3.0
	},
	{
		"type": "narration",
		"text": "매년 수많은 수험 전사들이 이곳에서 생존 퀘스트를 시작한다…",
		"duration": 3.5
	},
	{
		"type": "thought",
		"text": "그래… 여기서 살아남기만 하면 대학으로 갈 수 있다고 했지…",
		"duration": 3.0
	},
	{
		"type": "thought",
		"text": "근데 왜 교문에 '주의: 낙제 시 귀환 불가' 같은 게 써 있냐?",
		"duration": 3.5
	},
	{
		"type": "gate_pass",
		"duration": 1.5
	},
	{
		"type": "show_principal",
		"duration": 2.0
	}
]

# 배경 이미지 경로 설정 (프로젝트 폴더 내 경로)
@export var gate_image_path: String = "res://images/gate.png"
@export var principal_image_path: String = "res://images/principal.png"
@export var next_scene_path: String = "res://scene_2_opening.tscn"

func _ready():
	# 화면 설정
	setup_ui()
	
	# 타이머 설정
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# 시퀀스 시작
	play_sequence()

func setup_ui():
	# 배경 스프라이트
	background = Sprite2D.new()
	background.position = Vector2(640, 360)
	background.z_index = 0
	add_child(background)
	
	# 이미지 로드
	if FileAccess.file_exists(gate_image_path):
		background.texture = load(gate_image_path)
	else:
		print("경고: 배경 이미지를 찾을 수 없습니다: " + gate_image_path)
	
	# 검은 오버레이
	black_overlay = ColorRect.new()
	black_overlay.color = Color.BLACK
	black_overlay.size = Vector2(1280, 720)
	black_overlay.z_index = 10
	add_child(black_overlay)
	
	# 교장 스프라이트
	sprite_principal = Sprite2D.new()
	sprite_principal.position = Vector2(640, 360)
	sprite_principal.visible = false
	sprite_principal.z_index = 1
	add_child(sprite_principal)
	
	if FileAccess.file_exists(principal_image_path):
		sprite_principal.texture = load(principal_image_path)
	else:
		print("경고: 교장 이미지를 찾을 수 없습니다: " + principal_image_path)
	
	# 내레이션 배경
	narration_bg = ColorRect.new()
	narration_bg.position = Vector2(50, 580)
	narration_bg.size = Vector2(1180, 120)
	narration_bg.color = Color(0.1, 0.1, 0.2, 0.85)  # 진한 파란색 반투명
	narration_bg.visible = false
	narration_bg.z_index = 11
	add_child(narration_bg)
	
	# 내레이션 라벨
	label_narration = RichTextLabel.new()
	label_narration.position = Vector2(80, 600)
	label_narration.size = Vector2(1120, 90)
	label_narration.add_theme_font_size_override("normal_font_size", 24)
	label_narration.bbcode_enabled = true
	label_narration.fit_content = true
	label_narration.visible = false
	label_narration.z_index = 12
	add_child(label_narration)
	
	# 생각 배경
	thought_bg = ColorRect.new()
	thought_bg.position = Vector2(50, 580)
	thought_bg.size = Vector2(1180, 120)
	thought_bg.color = Color(0.2, 0.2, 0.2, 0.8)  # 어두운 회색 반투명
	thought_bg.visible = false
	thought_bg.z_index = 11
	add_child(thought_bg)
	
	# 생각 라벨 (플레이어 내적 독백)
	label_thought = RichTextLabel.new()
	label_thought.position = Vector2(80, 600)
	label_thought.size = Vector2(1120, 90)
	label_thought.add_theme_font_size_override("normal_font_size", 20)
	label_thought.bbcode_enabled = true
	label_thought.fit_content = true
	label_thought.visible = false
	label_thought.z_index = 12
	add_child(label_thought)

func play_sequence():
	if current_sequence >= sequences.size():
		print("장면 1 완료 - 장면 2로 전환")
		go_to_scene2()
		return
	
	var seq = sequences[current_sequence]
	
	match seq.type:
		"fade_in":
			fade_in(seq.duration)
		"narration":
			show_narration(seq.text, seq.duration)
		"thought":
			show_thought(seq.text, seq.duration)
		"gate_pass":
			pass_through_gate(seq.duration)
		"show_principal":
			show_principal(seq.duration)

func fade_in(duration: float):
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, duration)
	tween.finished.connect(_on_sequence_complete)

func show_narration(text: String, duration: float):
	label_thought.visible = false
	thought_bg.visible = false
	label_narration.visible = true
	narration_bg.visible = true
	label_narration.text = "[center][color=white]%s[/color][/center]" % text
	
	timer.start(duration)

func show_thought(text: String, duration: float):
	label_narration.visible = false
	narration_bg.visible = false
	label_thought.visible = true
	thought_bg.visible = true
	label_thought.text = "[center][color=gray][i]'%s'[/i][/color][/center]" % text
	
	timer.start(duration)

func pass_through_gate(duration: float):
	label_thought.visible = false
	thought_bg.visible = false
	
	# 카메라가 교문으로 줌인하듯이 배경을 확대하고 위치 이동
	var tween = create_tween()
	# 배경을 확대하면서 중앙(교문) 부분으로 이동
	tween.tween_property(background, "scale", Vector2(1.8, 1.8), duration * 0.5)
	# 배경의 위치를 약간 위로 이동 (교문 중심으로)
	tween.parallel().tween_property(background, "position", Vector2(640, 280), duration * 0.5)
	tween.parallel().tween_property(background, "modulate:a", 0.0, duration * 0.5)
	tween.tween_property(black_overlay, "color:a", 1.0, duration * 0.5)
	tween.finished.connect(_on_sequence_complete)

func show_principal(duration: float):
	background.visible = false
	sprite_principal.visible = true
	sprite_principal.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, duration * 0.3)
	tween.tween_property(sprite_principal, "modulate:a", 1.0, duration * 0.7)
	tween.finished.connect(_on_sequence_complete)

func go_to_scene2():
	# 대사창과 플레이어 관련 UI 숨기기
	label_narration.visible = false
	label_thought.visible = false
	narration_bg.visible = false
	thought_bg.visible = false
	
	# 교장만 보이게
	sprite_principal.visible = true
	background.visible = false
	
	# 2초 대기 후 장면 2로 전환
	await get_tree().create_timer(2.0).timeout
	
	if FileAccess.file_exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("에러: 장면 2를 찾을 수 없습니다: " + next_scene_path)

func _on_timer_timeout():
	_on_sequence_complete()

func _on_sequence_complete():
	current_sequence += 1
	play_sequence()

func _input(event):
	# 스페이스바로 스킵
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if timer.time_left > 0:
			timer.stop()
			_on_sequence_complete()
