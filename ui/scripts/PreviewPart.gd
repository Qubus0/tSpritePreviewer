extends Control
class_name PreviewPart

export var _state0 := ""
export var _state1 := ""

onready var state0_name := name + _state0
onready var state0_player_name := state0_name + "Player"
onready var state0_clothes_name := state0_name + "Clothes"
onready var state1_name := name + _state1
onready var state1_player_name := state1_name + "Player"
onready var state1_clothes_name := state1_name + "Clothes"

var state0_sprite: AnimatedSprite
var state0_player_sprite: AnimatedSprite
var state0_clothes_sprite: AnimatedSprite
var state1_sprite: AnimatedSprite
var state1_player_sprite: AnimatedSprite
var state1_clothes_sprite: AnimatedSprite

var shown_state_default := true setget set_shown_state
var has_states := false

var is_equipment_visible := true
var is_player_visible := true
var is_clothes_visible := true


func _ready() -> void:
	state0_sprite = find_node("State0")
	state0_player_sprite = find_node("State0Player")
	state0_clothes_sprite = find_node("State0Clothes")
	state1_sprite = find_node("State1")
	state1_player_sprite = find_node("State1Player")
	state1_clothes_sprite = find_node("State1Clothes")
	has_states = state1_sprite is AnimatedSprite


func set_shown_state(is_default: bool = true) -> void:
	shown_state_default = is_default
	state0_sprite.visible = 			is_default and is_equipment_visible
	state0_clothes_sprite.visible = 	is_default and is_clothes_visible and not is_equipment_visible
	state0_player_sprite.visible = 	is_default and is_player_visible

	state1_sprite.visible = 			not is_default and is_equipment_visible
	state1_clothes_sprite.visible = 	not is_default and is_clothes_visible and not is_equipment_visible
	state1_player_sprite.visible = 	not is_default and is_player_visible


func toggle_clothes_state0(make_visible: bool) -> void:
	state0_clothes_sprite.visible = make_visible


func toggle_clothes_state1(make_visible: bool) -> void:
	state1_clothes_sprite.visible = make_visible


func add_sprites_to_dictionary(dict: Dictionary) -> Dictionary:
	dict[state0_name] = 			state0_sprite
	dict[state0_player_name] = 	state0_player_sprite
	dict[state0_clothes_name] = 	state0_clothes_sprite
	if has_states:
		dict[state1_name] = 			state1_sprite
		dict[state1_player_name] = 	state1_player_sprite
		dict[state1_clothes_name] = 	state1_clothes_sprite
	return dict


func toggle_equipment(make_visible: bool) -> void:
	is_equipment_visible = make_visible
	state0_sprite.visible = shown_state_default and is_equipment_visible
	if has_states:
		state1_sprite.visible = not shown_state_default and is_equipment_visible

	if not name == "Head":
		state0_clothes_sprite.visible = shown_state_default and is_clothes_visible and not is_equipment_visible
		if has_states:
			state1_clothes_sprite.visible = not shown_state_default and is_clothes_visible and not is_equipment_visible


func toggle_player(make_visible: bool) -> void:
	is_player_visible = make_visible
	state0_player_sprite.visible = shown_state_default and is_player_visible
	if has_states:
		state1_player_sprite.visible = not shown_state_default and is_player_visible


func toggle_clothes(make_visible: bool) -> void:
	if name == "Head":
		return
	is_clothes_visible = make_visible
	state0_clothes_sprite.visible = shown_state_default and is_clothes_visible
	if has_states:
		state1_clothes_sprite.visible = not shown_state_default and is_clothes_visible


