extends Control

var min_window_size := 130
var drag_border_width := 10

var drag_start_position: Vector2
var is_dragging_window := false
var is_title_bar_shown := true

var is_resizing_window := false
var attempt_resizing_window := false
var current_side_flags := 0000

var preview_size : Vector2 = Vector2(ImageFactory.preview_size, ImageFactory.preview_size)

onready var tw: Tween = $TitleBar/TitleBarTween


signal change_setting(setting, value)


func _ready() -> void:
	hide_title_bar()


func _process(_delta: float) -> void:
	if is_hovering_title_bar():
		show_title_bar()
	else:
		hide_title_bar()


func _on_TitleBar_gui_input(event: InputEvent) -> void:
	if attempt_resizing_window:
		return
	var mouse_click := event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == BUTTON_LEFT:
		is_dragging_window = mouse_click.pressed
		drag_start_position = mouse_click.position

	var mouse_drag := event as InputEventMouseMotion
	if mouse_drag and is_dragging_window:
		OS.window_position += get_global_mouse_position() - drag_start_position


func _on_CustomWindow_gui_input(event: InputEvent) -> void:
	var side_flags := 0000

	var mouse_event := event as InputEventMouse
	if mouse_event:
		if mouse_event.position.y < drag_border_width:
			side_flags += 1000 # top
		if mouse_event.position.x > rect_size.x -drag_border_width:
			side_flags += 100 # right
		if mouse_event.position.y > rect_size.y -drag_border_width:
			side_flags += 10 # bottom
		if mouse_event.position.x < drag_border_width:
			side_flags += 1 # left

		if not is_resizing_window:
			current_side_flags = side_flags

		attempt_resizing_window = true
		match current_side_flags:
			0000:
				mouse_default_cursor_shape = CURSOR_ARROW
				attempt_resizing_window = false
			0010, 1000: mouse_default_cursor_shape = CURSOR_VSIZE
			0001, 0100: mouse_default_cursor_shape = CURSOR_HSIZE
			1001, 0110: mouse_default_cursor_shape = CURSOR_FDIAGSIZE
			1100, 0011: mouse_default_cursor_shape = CURSOR_BDIAGSIZE

	var mouse_click := event as InputEventMouseButton
	if mouse_click:
		is_resizing_window = mouse_click.pressed

	var mouse_drag := event as InputEventMouseMotion
	if mouse_drag and is_resizing_window:
		var new_window_size := OS.window_size
		var new_window_position := OS.window_position
		# side + each adjacent corner
		if current_side_flags in [ 1000, 1100, 1001 ]:
			new_window_size.y -= mouse_drag.relative.y
			new_window_position.y += mouse_drag.relative.y
		if current_side_flags in [ 0100, 0110, 1100 ]:
			new_window_size.x += mouse_drag.relative.x
		if current_side_flags in [ 0010, 0110, 0011 ]:
			new_window_size.y += mouse_drag.relative.y
		if current_side_flags in [ 0001, 1001, 0011 ]:
			new_window_position.x += mouse_drag.relative.x
			new_window_size.x -= mouse_drag.relative.x

		# positions and size are not directly set to have a minimum window size
		# if the window size gets smaller it is set to a fxied size here
		if new_window_size.x > min_window_size:
			OS.window_size.x = new_window_size.x
			OS.window_position.x = new_window_position.x
		else:
			OS.window_size.x = min_window_size
			# since resizing from the left/top repositions the window,
			# take just the remaining 'movement' to not produce jitter
			if not new_window_position.x == OS.window_position.x:
				var difference_to_min_size = new_window_size.x - min_window_size
				OS.window_position.x = new_window_position.x + difference_to_min_size

		if new_window_size.y > min_window_size:
			OS.window_size.y = new_window_size.y
			OS.window_position.y = new_window_position.y
		else:
			OS.window_size.y = min_window_size
			if not new_window_position.y == OS.window_position.y:
				var difference_to_min_size = new_window_size.y - min_window_size
				OS.window_position.y = new_window_position.y + difference_to_min_size

	emit_signal("change_setting", "window_position", OS.window_position)
	emit_signal("change_setting", "window_size", OS.window_size)


func show_title_bar() -> void:
	tw.stop_all()
	$TitleBar.modulate = Color.white


func hide_title_bar() -> void:
	if not $TitleBar.modulate == Color.white:
		return

	if tw.is_active():
		tw.stop($TitleBar)
	tw.interpolate_property($TitleBar, "modulate",
		Color.white, Color.transparent,
		2, Tween.TRANS_QUAD, Tween.EASE_OUT, 1
	)
	tw.start()


func is_hovering_title_bar() -> bool:
	return $TitleBar.get_global_rect().has_point(get_global_mouse_position())


func _on_CustomWindow_resized() -> void:

	var window_size : Vector2 = self.rect_size
	var scale : Vector2 = window_size - preview_size * $PreviewControl.rect_scale
	if scale.x > 100 and scale.y > 100:
		$PreviewControl.rect_scale += Vector2(1, 1)
	elif scale.x < 0 or scale.y < 0:
		if not $PreviewControl.rect_scale == Vector2(1, 1):
			$PreviewControl.rect_scale -= Vector2(1, 1)

	# debugging
	$ReferenceRect.rect_position = window_size/2 - (preview_size * $PreviewControl.rect_scale) / 2
	$ReferenceRect.rect_size = (preview_size * $PreviewControl.rect_scale)

