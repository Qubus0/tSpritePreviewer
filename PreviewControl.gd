extends Control

var previews := {}


func _ready() -> void:
	for node in get_children():
		var preview_sprite: Node = node
		if not preview_sprite is AnimatedSprite:
			preview_sprite = node.get_node_or_null(node.name)
			if not preview_sprite is AnimatedSprite:
				continue
		previews[preview_sprite.name] = preview_sprite


func _process(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	if not mouse_pos or not is_in_window(mouse_pos):
		return
	$ArmSpecialBack.look_at(mouse_pos)
	$ArmSpecialFront.look_at(mouse_pos)


func is_in_window(position: Vector2) -> bool:
	if position.x < 0 or position.y < 0:
		return false
	if position.x > OS.window_size.x or position.y > OS.window_size.y:
		return false
	return true
