extends KinematicBody2D

# Типы положений
enum a {DOWN, UP, LEFT, RIGHT}

# Настройки передвижения
# Скорость
export (int) var speed = 100
# Задержка между сменой кадров
export (int) var change = 10
export (a) var default_state = a.UP

# Объекты
onready var character = $Character
onready var water_sprite = $Character/Water
# Звук
onready var player = $AudioStreamPlayer
onready var player2 = $AudioStreamPlayer2

# Переменные, которые нужны программе
# Не стоит их менять
var distance_passed = 0
# Типы положений
enum {DOWN, UP, LEFT, RIGHT}
# Текущий тип
var type = 0
# Стоял ли персонаж в предыдущий раз
# То есть задана ли уже неподвижная стойка
var idle = true
# Множитель, меняется при нажатии shift
var mult : int = 1
# Для порядка звуков шагов
var first_sound : bool = false
# Нажата ли хоть какая-нибудь кнопка передвижения
var any_button_pressed : bool
# Нажата ли кнопка влево или вправо
# Чтобы блокировать более позднюю обработку вверх и вниз
var side_used : bool
# Вектор передвижения
var velocity : Vector2
# Кадры
enum {DOWN_1, UP_1, SIDE_1,
	DOWN_2, UP_2, SIDE_2,
	DOWN_STILL, UP_STILL, SIDE_STILL}

# Для предотвращения отключения воды
var water_level : int = 0
var water_protection : bool = false setget set_water_protection

func set_water_protection(val):
	water_protection = val
	if !water_protection:
		if water_level == 1:
			water_sprite.visible = true
			water_sprite.playing = true
	else:
		water_sprite.visible = false
		water_sprite.playing = false

# Заблокировать обработку ввода
func lock() -> void:
	set_physics_process(false)


# Возобновить обработку ввода
func unlock() -> void:
	set_physics_process(true)


# Включить воду внизу
func enable_water() -> void:
	water_level += 1
	if !water_protection and water_level == 1:
		water_sprite.visible = true
		water_sprite.playing = true


# Отключить воду внизу
func disable_water() -> void:
	water_level -= 1
	if water_level == 0:
		water_sprite.visible = false
		water_sprite.playing = false


# Воспроизвести звук шага
func play_step() -> void:
	if first_sound:
		player.play()
	else:
		player2.play()
	# Изменить состояние
	first_sound = !first_sound


# Общая часть функций движения в сторону
func go_side() -> void:
	idle = false
	side_used = true
	any_button_pressed = true
	distance_passed += 1
	# Анимация
	# Крайнее положение
	if distance_passed == change:
		character.frame = SIDE_2
		play_step()
	elif distance_passed == 2 * change:
		character.frame = SIDE_STILL
	# Крайнее положение
	elif distance_passed == 3 * change:
		character.frame = SIDE_1
		play_step()
	# Обратный порядок
	elif distance_passed == 4 * change:
		character.frame = SIDE_STILL
		distance_passed = 0


# Вправо
func go_right() -> void:
	# Если предыдущее состояние не "вправо"
	if type != RIGHT:
		type = RIGHT
		# Обнулить счетчик для анимации
		distance_passed = 0
		character.frame = SIDE_1
		character.flip_h = false
	go_side()
	velocity.x += 1


# Влево
func go_left() -> void:
	if type != LEFT:
		type = LEFT
		distance_passed = 0
		character.frame = 2
		character.flip_h = true
	go_side()
	velocity.x -= 1


# Вниз
func go_down() -> void:
	idle = false
	any_button_pressed = true
	if !side_used:
		if type != DOWN:
			type = DOWN
			distance_passed = 0
			character.frame = DOWN_1
			character.flip_h = false
		distance_passed += 1
		# Крайнее положение
		if distance_passed == change:
			character.frame = DOWN_1
			play_step()
		elif distance_passed == 3 * change:
			character.frame = DOWN_2
			play_step()
		elif distance_passed == 4 * change:
			distance_passed = DOWN_1 
	velocity.y += 1


# Вверх
func go_up() -> void:
	idle = false
	any_button_pressed = true
	if !side_used:
		if type != UP:
			type = UP
			distance_passed = 0
			character.frame = UP_1
			character.flip_h = false
		distance_passed += 1
		# Крайнее положение
		if distance_passed == change:
			character.frame = UP_1
			play_step()
		elif distance_passed == 3 * change:
			character.frame = UP_2
			play_step()
		elif distance_passed == 4 * change:
			distance_passed = UP_1
	velocity.y -= 1


func check_for_col_disable_btn():
	if Input.is_action_just_pressed("ui_home"):
		get_node("CollisionShape2D").disabled = !get_node("CollisionShape2D").disabled


# Обработка ввода
func get_input() -> bool:
	# Сбросить переменные
	velocity = Vector2()
	any_button_pressed = false
	side_used = false
	check_for_col_disable_btn()
	# Обработка 4 сторон передвижения
	if Input.is_action_pressed('ui_right'):
		go_right()
	if Input.is_action_pressed('ui_left'):
		go_left()
	if Input.is_action_pressed('ui_down'):
		go_down()
	if Input.is_action_pressed('ui_up'):
		go_up()
	# Если кнопки не были нажаты в первый раз
	if !idle && !any_button_pressed:
		idle = true
		if type == UP:
			character.frame = UP_STILL
		elif type == DOWN:
			character.frame = DOWN_STILL
		else:
			character.frame = SIDE_STILL
		return false
	mult = 4 if Input.is_action_pressed("speed_up") else 1
	velocity = velocity.normalized() * speed * mult
	return true


# Вызывается постоянно
func _physics_process(_delta) -> void:
	# Если была нажата хоть одна клавиша передвижения
	if get_input():
		# Переместиться на velocity
		# Он задается get_input() при обработке ввода
		move_and_slide(velocity)


func _ready():
	# Установка позиции
	if default_state == UP:
		go_up()
	elif default_state == DOWN:
		go_down()
	elif default_state == RIGHT:
		go_right()
	else:
		go_left()