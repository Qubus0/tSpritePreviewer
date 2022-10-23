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
onready var color_panel: PanelContainer = $Margin/Control/ColorPanel
onready var parts_panel: PanelContainer = $Margin/Control/PartsPanel
onready var animation_panel: PanelContainer = $Margin/Control/AnimationPanel
onready var playback_panel: PanelContainer = $Margin/Control/PlaybackPanel

onready var equipment_preview: PreviewControl = $CustomWindow/EquipmentPreview

var player_sprites := {
	"Player": [
		{
			"image": preload("res://images/player/Player/PlayerHead_Head.png"),
			"name": "PlayerHead_Head",
		},
		{
			"image": preload("res://images/player/Player/PlayerBody_Body.png"),
			"name": "PlayerBody_Body",
		},
		{
			"image": preload("res://images/player/Player/PlayerLegs_Legs.png"),
			"name": "PlayerLegs_Legs",
		},
	],
	"Clothes": [
		{
			"image": preload("res://images/player/Clothes/ClothesHead_Head.png"),
			"name": "ClothesHead_Head",
		},
		{
			"image": preload("res://images/player/Clothes/ClothesBody_Body.png"),
			"name": "ClothesBody_Body",
		},
		{
			"image": preload("res://images/player/Clothes/ClothesLegs_Legs.png"),
			"name": "ClothesLegs_Legs",
		},
	],
	"HairClothes": [
		{
			"image": preload("res://images/player/HairClothes/HairClothesHead_Head.png"),
			"name": "HairClothesHead_Head",
		},
	],
}

func _ready() -> void:
#	if OS.get_screen_scale() and OS.get_screen_scale() == 2:
#		OS.window_size *= 2
	OS.set_low_processor_usage_mode(true)
	get_viewport().transparent_bg = true
	load_settings()
	save_settings()

	if settings.window_position:
		if not settings.window_position > OS.get_screen_size() and not settings.window_position < Vector2.ZERO:
			OS.window_position = settings.window_position
	if settings.window_size:
		OS.window_size = settings.window_size
		$CustomWindow.adjust_preview_size()

	$CustomWindow/TitleBar/HBoxContainer/Foreground.pressed = settings.foreground
	toggle_panel(color_panel, false, 0)
	toggle_panel(parts_panel, false, 0)
	toggle_panel(animation_panel, false, 0)
	toggle_panel(playback_panel, false, 0)

	add_child(watcher)
	watcher.connect("files_modified", self, "files_modified")
	background_color = $Background.get_stylebox("panel").bg_color

	get_tree().connect("files_dropped", self, "files_dropped")
	add_event_action_button_shortcut_hint_recursive(self)
	setup_defocus_ui_elements_recursive(self)
	setup_button_connections()
	$CustomWindow.connect("change_setting", self, "change_setting")

	create_player_previews()
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


func files_modified(_files: Array):
	create_preview(settings.last_directory)


func create_preview(directory_path: String) -> void:
	equipment_preview.set_preview_sprite_playing(false)
	var last_frame = equipment_preview.clear_preview_sprites()
	var item_images := ItemFileReader.get_set_information(directory_path)
	if item_images.empty():
		display_error("Nothing to display.\n" +
		"Did you follow the naming convention?\n\n" +
		"./SetName (folder)\n"+
		"   L SetNameHead_Head.png\n" +
		"   L SetNameBody_Body.png\n" +
		"   L SetNameLegs_Legs.png\n"
		)
	var preview_images = ImageFactory.compile_set_images(item_images)
	equipment_preview.create_preview(preview_images)
	equipment_preview.set_preview_sprite_frame(last_frame)
	equipment_preview.set_preview_sprite_playing(true)


func create_player_previews() -> void:
	create_preset_preview("Player")
	create_preset_preview("Clothes")
	create_preset_preview("HairClothes")


func create_preset_preview(part: String) -> void:
	var images: Array = player_sprites[part]
	var preview_images := ImageFactory.compile_set_images(images, part)
	equipment_preview.create_preview(preview_images)


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


func ready_untoggle(button: BaseButton):
	if button.pressed:
		btn_to_be_untoggled = button


func untoggle(button: BaseButton):
	if button == btn_to_be_untoggled:
		btn_to_be_untoggled = null
		button.pressed = false
		button.release_focus()


func add_event_action_button_shortcut_hint_recursive(node: Node) -> void:
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


func setup_defocus_ui_elements_recursive(node: Node) -> void:
	# stops confusing interactions because things never release focus in godot
	# not the greatest for accessibility though
	if node is BaseButton:
		node.connect("pressed", self, "unfocus_after_interaction", [null, node])

	if node is Slider:
		node.connect("value_changed", self, "unfocus_after_interaction", [node])

	for child_node in node.get_children():
		setup_defocus_ui_elements_recursive(child_node)


func unfocus_after_interaction(_val, control: Control) -> void:
	control.release_focus()


func _on_animation_state_selected(button: BaseButton) -> void:
	var state := button.name.to_lower()
	equipment_preview.set_preview_sprite_animation(state)
	equipment_preview.sort_animation_layers()


func toggle_panel(panel: PanelContainer, make_visible: bool, time_s = .3) -> void:
	var tw: Tween = $PanelTween
	var start := panel.margin_top
	var end := panel.margin_top - 400 if make_visible else panel.margin_top + 400
	tw.interpolate_property(
		panel, "margin_top", start, end,
		time_s, Tween.TRANS_CIRC, Tween.EASE_IN_OUT
	)
	tw.start()


func _on_EquipmentPreview_frame_changed(frame) -> void:
	$Margin/Control/PlaybackPanel/HBoxContainer/FrameIndex.text = "%02d" % (frame + 1)


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_Foreground_toggled(button_pressed: bool) -> void:
	OS.move_window_to_foreground()
	OS.set_window_always_on_top(button_pressed)
	change_setting("foreground", button_pressed)


func _on_ColorPicker_toggled(button_pressed: bool) -> void:
	toggle_panel(color_panel, button_pressed)


func _on_Parts_toggled(button_pressed: bool) -> void:
	toggle_panel(parts_panel, button_pressed)


func _on_Animations_toggled(button_pressed: bool) -> void:
	toggle_panel(animation_panel, button_pressed)


func _on_Playback_toggled(button_pressed: bool) -> void:
	toggle_panel(playback_panel, button_pressed)


func _on_PausePlay_toggled(button_pressed: bool) -> void:
	equipment_preview.set_preview_sprite_playing(button_pressed)


func _on_PreviousFrame_pressed() -> void:
	equipment_preview.next_preview_sprite_animation_frame(false)


func _on_NextFrame_pressed() -> void:
	equipment_preview.next_preview_sprite_animation_frame(true)


func _on_Speed1_toggled(_button_pressed: bool) -> void:
	$Margin/Control/PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	equipment_preview.set_preview_sprite_animation_speed(1, 1)


func _on_Speed2_toggled(_button_pressed: bool) -> void:
	$Margin/Control/PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	equipment_preview.set_preview_sprite_animation_speed(8, 16)


func _on_Speed3_toggled(_button_pressed: bool) -> void:
	$Margin/Control/PlaybackPanel/HBoxContainer/PausePlay.pressed = true
	equipment_preview.set_preview_sprite_animation_speed(8*2, 16*2)


func _on_ColorPreset_pressed(button: Button) -> void:
	presets_group = button.group
	var color_rect: ColorRect = button.get_node_or_null("Color")
	if color_rect:
		self.background_color = color_rect.color
		self.background_color.a = transparency_percentage/100


func _on_AlphaSlider_value_changed(value: float) -> void:
	transparency_percentage = value
	self.background_color.a = transparency_percentage/100
	$Margin/Control/ColorPanel/VBoxContainer/Alpha/Label.text = "%s%%" % transparency_percentage


func _on_ColorHexInput_text_changed(new_text: String) -> void:
	if new_text.is_valid_html_color():
		self.background_color = Color(new_text)
		if presets_group:
			var btn := presets_group.get_pressed_button()
			if btn: btn.pressed = false


func _on_Head_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("Head", button_pressed)


func _on_EquipmentHead_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_equipment_part("Head", button_pressed)


func _on_Shoulder_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("ShoulderFront", button_pressed)


func _on_ShoulderBack_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("ShoulderBack", button_pressed)


func _on_ArmFront_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("ArmFront", button_pressed)


func _on_EquipmentArmFront_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_equipment_part("ArmFront", button_pressed)
	equipment_preview.toggle_equipment_part("ShoulderFront", button_pressed)


func _on_ArmBack_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("ArmBack", button_pressed)


func _on_EquipmentArmBack_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_equipment_part("ArmBack", button_pressed)
	equipment_preview.toggle_equipment_part("ShoulderBack", button_pressed)


func _on_Body_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("Body", button_pressed)


func _on_EquipmentBody_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_equipment_part("Body", button_pressed)


func _on_Legs_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_part("Legs", button_pressed)


func _on_EquipmentLegs_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_equipment_part("Legs", button_pressed)


func _on_Male_toggled(button_pressed: bool) -> void:
	# when Female button is pressed, this untoggles -> only need one func
	equipment_preview.toggle_male_female(button_pressed)


func _on_Special_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_special_arm(button_pressed)


func _on_EquipmentHair_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_clothes_state0("Head", button_pressed)


func _on_EquipmentHairAlt_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_clothes_state1("Head", button_pressed)


func _on_ShowPlayer_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_player_visible(button_pressed)


func _on_ShowClothes_toggled(button_pressed: bool) -> void:
	equipment_preview.toggle_clothes_visible(button_pressed)

