extends Control
class_name PreviewControl

var previews := {}
var sprite_frames := preload("res://ui/PreviewSpriteFrames.tres")

signal frame_changed(frame)


func _ready() -> void:
	$Head/State0.connect("frame_changed", self, "_on_Head_frame_changed")
	for node in get_children():
		if node is PreviewPart:
			previews = node.add_sprites_to_dictionary(previews)
			continue

		var preview_sprite: AnimatedSprite = node as AnimatedSprite
		if not preview_sprite:
			continue
		previews[preview_sprite.name] = preview_sprite


func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	if not mouse_pos or not is_in_window(mouse_pos):
		return
	$ArmBack/SpecialPivot.look_at(mouse_pos)
	$ArmFront/SpecialPivot.look_at(mouse_pos)


func is_in_window(position: Vector2) -> bool:
	if position.x < 0 or position.y < 0:
		return false
	if position.x > OS.window_size.x or position.y > OS.window_size.y:
		return false
	return true


func create_preview(preview_images: Dictionary) -> void:
	for set_part in preview_images.keys():
		var preview_sprite: AnimatedSprite = previews[set_part]

		for state in preview_images[set_part].keys():
			for frame in preview_images[set_part][state]:
				preview_sprite.frames.add_frame(state, frame)


func clear_preview_sprites() -> int:
	var last_frame = {}
	for part_type in previews.keys():
		if "Player" in part_type or "Clothes" in part_type or "Hair" in part_type:
			continue
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		last_frame = sprite.frame
		sprite.frames.clear("idle")
		sprite.frames.clear("jump")
		sprite.frames.clear("use")
		sprite.frames.clear("move")
		sprite.frames.clear("sit")
		sprite.frames.clear("special")
	return last_frame


func is_preview_sprite_playing() -> bool:
	for part_type in previews.keys():
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		return sprite.playing
	return true


func set_preview_sprite_playing(is_playing: bool) -> void:
	for part_type in previews.keys():
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		sprite.playing = is_playing


func set_preview_sprite_animation(animation: String) -> void:
	for part_type in previews.keys():
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		sprite.animation = animation


func next_preview_sprite_animation_frame(forward: bool) -> void:
	for part_type in previews.keys():
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		var next_frame: int = sprite.frame + 1
		if not forward: next_frame = sprite.frame -1

		var frame_count: int = sprite.frames.get_frame_count(sprite.animation)
		if frame_count > 0:
			sprite.frame = (frame_count + next_frame) % frame_count


func set_preview_sprite_animation_speed(use_fps: int, move_fps: int) -> void:
	for part_type in previews.keys():
		var sprite: AnimatedSprite = previews[part_type] as AnimatedSprite
		sprite.frames.set_animation_speed("use", use_fps)
		sprite.frames.set_animation_speed("special", use_fps)
		sprite.frames.set_animation_speed("move", move_fps)


func set_preview_sprite_frame(frame: int) -> void:
	for part_type in previews.keys():
		var sprite := previews[part_type] as AnimatedSprite

		var frame_count: int = sprite.frames.get_frame_count(sprite.animation)
		if frame_count > 0:
			sprite.frame = frame % frame_count


func sort_animation_layers() -> void:
	# use anim: shoulder is only behind the arm at frames 0, 1 not 2, 3
	var sprite: AnimatedSprite = $Head/State0
	if (sprite.animation == "use" and (sprite.frame == 0 or sprite.frame == 1) or
		sprite.animation == "jump"):
		move_child($ShoulderFront, 5)
	else:
		move_child($ShoulderFront, 6)


func toggle_part(part: String, make_visible: bool) -> void:
	var preview_part = get_node(part) as PreviewPart
	preview_part.visible = make_visible


func toggle_equipment_part(part: String, make_visible: bool) -> void:
	var preview_part = get_node(part) as PreviewPart
	preview_part.toggle_equipment(make_visible)


func toggle_equipment_part_state(part: String, is_state_default: bool) -> void:
	var preview_part = get_node(part) as PreviewPart
	preview_part.shown_state_default = is_state_default


func toggle_clothes_state0(part: String, is_state_default: bool) -> void:
	var preview_part = get_node(part) as PreviewPart
	preview_part.toggle_clothes_state0(is_state_default)


func toggle_clothes_state1(part: String, is_state_default: bool) -> void:
	var preview_part = get_node(part) as PreviewPart
	preview_part.toggle_clothes_state1(is_state_default)


func toggle_player_visible(make_visible: bool) -> void:
	for part in get_children():
		part.toggle_player(make_visible)


func toggle_clothes_visible(make_visible: bool) -> void:
	for part in get_children():
		part.toggle_clothes(make_visible)


func toggle_male_female(is_male: bool) -> void:
	$Body.shown_state_default = is_male
	$ShoulderBack.shown_state_default = is_male
	$ShoulderFront.shown_state_default = is_male


func toggle_special_arm(is_arm_special: bool) -> void:
	$ArmBack.shown_state_default = not is_arm_special
	$ArmFront.shown_state_default = not is_arm_special


func _on_Head_frame_changed() -> void:
	# frames on all animations are always in sync -> only need to check one
	var sprite: AnimatedSprite = $Head/State0
	emit_signal("frame_changed", sprite.frame)
	sort_animation_layers()


