extends Button


func _on_Button_button_down() -> void:
	OS.clipboard = $"/root/VanityPageFactory".template
