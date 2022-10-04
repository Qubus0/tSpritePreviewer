extends Control

var settings: Dictionary = {
	"last_directory": "",
	"window_position": null,
	"window_size": null,
	"foreground": false
}
var save_path = "user://previewer_settings.json"
var default_error = ("To start, drag & drop a directory (folder) into this window.\n\n" +
	"Structure (important):\n" +
	"./SetName\n"+
	"   L SetNameHead_Head.png\n" +
	"   L SetNameBody_Body.png\n" +
	"   L SetNameLegs_Legs.png\n"
)

var background_color: Color setget set_background_color
var transparency_percentage := 100.0
var presets_group: ButtonGroup

var btn_to_be_untoggled: BaseButton

var watcher = DirectoryWatcher.new()

onready var background: Panel = $Background
onready var color_picker: Button = $CustomWindow/TitleBar/HBoxContainer/ColorPicker
onready var color_panel: PanelContainer = $ColorPanel
onready var parts_panel: PanelContainer = $PartsPanel
onready var animation_panel: PanelContainer = $AnimationPanel
onready var playback_panel: PanelContainer = $PlaybackPanel


func _ready() -> void:
#	if OS.get_screen_scale() and OS.get_screen_scale() == 2:
#		OS.window_size *= 2
	OS.set_low_processor_usage_mode(true)
	get_viewport().transparent_bg = true
	load_settings()
	save_settings()

	if settings.window_position:
		OS.window_position = settings.window_position
	if settings.window_size:
		OS.window_size = settings.window_size

	$CustomWindow/TitleBar/HBoxContainer/Foreground.pressed = settings.foreground

	add_child(watcher)
	watcher.connect("files_modified", self, "files_modified")
	background_color = $Background.get_stylebox("panel").bg_color

	get_tree().connect("files_dropped", self, "files_dropped")
	add_event_action_button_shortcut_hint_recursive(self)
	setup_button_connections()
	$"/root/ImageFactory".connect("preview", $CustomWindow, "preview_image")
	$CustomWindow.connect("change_setting", self, "change_setting")

	if settings.last_directory:
		watcher.add_scan_directory(settings.last_directory)
		create_preview(settings.last_directory)
	else:
		display_error(default_error)


func files_dropped(paths: PoolStringArray, _screen: int):
	clear_error()
	if paths.size() > 1:
		display_error("Add a single directory (folder)")
		return
	var path := paths[0]
	var dir := Directory.new()
	if not dir.dir_exists(path):
		display_error("That is not a directory")
		return
	if not dir.open(path) == OK:
		display_error("Something went wrong while opening the directory, please try again")
		return

	watcher.add_scan_directory(path)
	if settings.last_directory:
		watcher.remove_scan_directory(settings.last_directory)

	change_setting("last_directory", path)
	create_preview(path)


func files_modified(files: Array):
	create_preview(settings.last_directory)


func create_preview(directory_path: String) -> void:
	var last_frame = clear_preview_sprites()
	var preview_images := ItemFileReader.get_set_information(directory_path)
	if preview_images.empty():
		display_error("Nothing to display.\n" +
		"Did you follow the naming convention?\n\n" +
		"./SetName (folder)\n"+
		"   L SetNameHead_Head.png\n" +
		"   L SetNameBody_Body.png\n" +
		"   L SetNameLegs_Legs.png\n"
		)
	ImageFactory.compile_set_image(preview_images)
	set_preview_sprite_frame(last_frame)


func setup_button_connections() -> void:
	for button in get_tree().get_nodes_in_group("color_preset"):
		button.connect("pressed", self, "_on_ColorPreset_pressed", [button])

	for button in get_tree().get_nodes_in_group("untoggle"):
		button.connect("button_down", self, "ready_untoggle", [button])
		button.connect("button_up", self, "untoggle", [button])

	for button in get_tree().get_nodes_in_group("animation_state"):
		button.connect("pressed", self, "_on_animation_state_selected", [button])


func display_error(message: String) -> void:
	$ErrorLabel.show()
	$ErrorLabel.bbcode_text = message


func clear_error() -> void:
	$ErrorLabel.hide()
	$ErrorLabel.bbcode_text = ""


func save_settings() -> void:
	var dirs = File.new()
	dirs.open(save_path, File.WRITE)
	dirs.store_line(to_json(settings))


func load_settings() -> void:
	var save = File.new()
	save.open(save_path, File.READ)
	if not save.file_exists(save_path):
		display_error(default_error)
		return

	var json = parse_json(save.get_line())
	settings = json

	var dir := Directory.new()
	if not dir.dir_exists(settings.last_directory):
		settings.last_directory = ""

	if settings.window_position:
		settings.window_position = str2var("Vector2" + settings.window_position)
	if settings.window_size:
		settings.window_size = str2var("Vector2" + settings.window_size)

func change_setting(setting: String, value) -> void:
	settings[setting] = value
	save_settings()


func set_background_color(color: Color):
	background_color = color
	background.get_stylebox("panel").bg_color = color
	color_picker.get_stylebox("normal").bg_color = color
	color_picker.get_stylebox("pressed").bg_color = color
	color_picker.get_stylebox("hover").bg_color = color


func clear_preview_sprites() -> int:
	var last_frame = {}
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite: AnimatedSprite = preview_sprite as AnimatedSprite
		last_frame = sprite.frame
		sprite.frames.clear("idle")
		sprite.frames.clear("jump")
		sprite.frames.clear("use")
		sprite.frames.clear("move")
	return last_frame


func set_preview_sprite_playing(is_playing: bool) -> void:
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite := preview_sprite as AnimatedSprite
		sprite.playing = is_playing


func set_preview_sprite_animation(animation: String) -> void:
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite := preview_sprite as AnimatedSprite
		sprite.animation = animation


func next_preview_sprite_animation_frame(forward: bool):
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite := preview_sprite as AnimatedSprite
		var next_frame: int = sprite.frame + 1
		if not forward: next_frame = sprite.frame -1

		var frame_count: int = sprite.frames.get_frame_count(sprite.animation)
		sprite.frame = (frame_count + next_frame) % frame_count


func set_preview_sprite_animation_speed(use_fps: int, move_fps: int):
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite := preview_sprite as AnimatedSprite
		sprite.frames.set_animation_speed("use", use_fps)
		sprite.frames.set_animation_speed("move", move_fps)


func set_preview_sprite_frame(frame: int):
	for preview_sprite in $CustomWindow/PreviewControl.get_children():
		var sprite := preview_sprite as AnimatedSprite

		var frame_count: int = sprite.frames.get_frame_count(sprite.animation)
		sprite.frame = frame % frame_count


func ready_untoggle(button: BaseButton):
	if button.pressed:
		btn_to_be_untoggled = button


func untoggle(button: BaseButton):
	if button == btn_to_be_untoggled:
		btn_to_be_untoggled = null
		button.pressed = false
		button.release_focus()


func _on_animation_state_selected(button: BaseButton) -> void:
	var state := button.name.to_lower()
	set_preview_sprite_animation(state)


func add_event_action_button_shortcut_hint_recursive(node: Node):
	var button := node as BaseButton
	if button and button.shortcut:
		var input_action := button.shortcut.shortcut as InputEventAction
		if input_action:
			var actions := InputMap.get_action_list(input_action.action)
			if not actions:
				return

			var tooltip := ""
			for action in actions:
				tooltip += action.as_text() + ", "
			tooltip = tooltip.rsplit(",", false, 1)[0]

			tooltip = " (%s)" % tooltip
			button.hint_tooltip += tooltip
			# remove leading spaces in case the tooltip was empty
			button.hint_tooltip.trim_prefix(" ")

	for child_node in node.get_children():
		add_event_action_button_shortcut_hint_recursive(child_node)


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_Foreground_toggled(button_pressed: bool) -> void:
	OS.move_window_to_foreground()
	OS.set_window_always_on_top(button_pressed)
	change_setting("foreground", button_pressed)


func _on_ColorPicker_toggled(button_pressed: bool) -> void:
	color_panel.visible = button_pressed


func _on_Parts_toggled(button_pressed: bool) -> void:
	parts_panel.visible = button_pressed


func _on_Animations_toggled(button_pressed: bool) -> void:
	animation_panel.visible = button_pressed


func _on_Playback_toggled(button_pressed: bool) -> void:
	playback_panel.visible = button_pressed


func _on_PausePlay_toggled(button_pressed: bool) -> void:
	set_preview_sprite_playing(button_pressed)


func _on_PreviousFrame_pressed() -> void:
	next_preview_sprite_animation_frame(false)


func _on_NextFrame_pressed() -> void:
	next_preview_sprite_animation_frame(true)


func _on_Speed1_toggled(_button_pressed: bool) -> void:
	$PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	set_preview_sprite_animation_speed(1, 1)


func _on_Speed2_toggled(_button_pressed: bool) -> void:
	$PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	set_preview_sprite_animation_speed(8, 16)


func _on_Speed3_toggled(_button_pressed: bool) -> void:
	$PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	set_preview_sprite_animation_speed(8*2, 16*2)


func _on_Head_frame_changed() -> void:
	# frames on all animations are always in sync -> only need to check one
	var sprite: AnimatedSprite = $CustomWindow/PreviewControl/Head
	var frame: String = "%02d" % (sprite.frame + 1)
	$PlaybackPanel/HBoxContainer/FrameIndex.text = frame

	# use anim: shoulder is only behind the arm at frames 0, 1 not 2, 3
	if sprite.animation == "use" and (sprite.frame == 2 or sprite.frame == 3):
		$CustomWindow/PreviewControl.move_child($CustomWindow/PreviewControl/ArmFront, 5)
	else:
		$CustomWindow/PreviewControl.move_child($CustomWindow/PreviewControl/ArmFront, 6)


func _on_ColorPreset_pressed(button: Button) -> void:
	presets_group = button.group
	var color_rect: ColorRect = button.get_node_or_null("Color")
	if color_rect:
		self.background_color = color_rect.color
		self.background_color.a = transparency_percentage/100


func _on_AlphaSlider_value_changed(value: float) -> void:
	transparency_percentage = value
	self.background_color.a = transparency_percentage/100
	$ColorPanel/VBoxContainer/Alpha/Label.text = "%s%%" % transparency_percentage


func _on_ColorHexInput_text_changed(new_text: String) -> void:
	if new_text.is_valid_html_color():
		self.background_color = Color(new_text)
		if presets_group:
			var btn :=  presets_group.get_pressed_button()
			if btn: btn.pressed = false


func _on_Shoulder_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Shoulder.visible = button_pressed


func _on_Head_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Head.visible = button_pressed


func _on_Hair_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Hair.visible = button_pressed


func _on_ArmFront_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/ArmFront.visible = button_pressed


func _on_Body_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Body.visible = button_pressed
	$CustomWindow/PreviewControl/Female.visible = button_pressed


func _on_ArmBack_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/ArmBack.visible = button_pressed


func _on_Legs_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Legs.visible = button_pressed


func _on_Female_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Female.visible = button_pressed
	$PartsPanel/Parts/Body.pressed = true


func _on_Male_toggled(button_pressed: bool) -> void:
	$CustomWindow/PreviewControl/Body.visible = button_pressed
	$PartsPanel/Parts/Body.pressed = true


