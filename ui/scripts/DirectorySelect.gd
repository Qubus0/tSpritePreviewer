extends Button

signal save_directory

var default_label_color


func _on_DirButton_pressed() -> void:
	$Modal.popup_centered()


func _on_Modal_dir_selected(dir: String) -> void:
	$Input.text = dir
	emit_signal("save_directory", name, dir)


func _on_Input_ready() -> void:
	default_label_color = $Input.get_color("font_color")


func _on_Input_text_changed(new_text: String) -> void:
	var dir = Directory.new()
	if dir.dir_exists(new_text):
		$Input.add_color_override("font_color", default_label_color)


func _on_Input_text_entered(new_text: String) -> void:
	var dir = Directory.new()
	if dir.dir_exists(new_text):
		$Modal.current_dir = new_text
		$Modal.emit_signal("confirmed")
		$Input.release_focus()
	else:
		$Input.add_color_override("font_color", Color.red)


func adjust_to_main_dir_change(dir) -> void:
	$Modal.current_dir = dir
	$Input.text = dir
	emit_signal("save_directory", name, dir, false)
