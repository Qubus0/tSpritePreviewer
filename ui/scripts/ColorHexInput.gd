extends LineEdit

var last_reject := ""


func _on_ColorHexInput_text_change_rejected(rejected_substring: String) -> void:
	last_reject = rejected_substring


func _on_ColorHexInput_text_changed(new_text: String) -> void:
	# deal with pastes: 6 digit hex with '#' in front
	if last_reject.length() == 1 and "#" in new_text:
		var hex = new_text.replace("#", "")
		hex += last_reject
		last_reject = ""
		self.text = hex
		emit_signal("text_changed", hex)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_ENTER or event.scancode == KEY_ESCAPE:
			release_focus()
