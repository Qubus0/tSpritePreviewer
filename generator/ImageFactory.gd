extends Node

signal preview

var frame_size : Vector2 = Vector2(40, 56)
var frame_count : int = 20;
var preview_size = 70
var preview_pos = Vector2(preview_size/2 - frame_size.x/2, 2+ preview_size/2 - frame_size.y/2)


func compile_set_image(set_images: Array) -> void:
	var preview_images := {}
	var src_pos : Vector2 = Vector2.ZERO
	var src : Image
	for frame in frame_count:
		var state = get_state(frame)
		src_pos = Vector2(0, frame * frame_size.y)

		for sprite in set_images:
			var preview = create_empty_preview()
			var part_type = sprite.name.rsplit("_", false, 1)[1]
			if not part_type:
				continue

			src = sprite.image
			if src.get_width() > frame_size.x:
				extract_body_and_arm_preview_images(frame, src, preview_images)
			else:
				preview.blend_rect(src, Rect2(src_pos, frame_size), preview_pos)
				add_part_preview_images(state, preview_images, preview, part_type)

			if state == "idle":
				if part_type == "Legs":
					# the sitting legs are just taking the idle frames legs and editing them
					preview.fill(Color.transparent)
					# l 46-52 up 4, right 4
					var bottom_lines = Rect2(Vector2(0, 46), Vector2(frame_size.x, 12))
					preview.blend_rect(src, bottom_lines, preview_pos + bottom_lines.position + Vector2(4, -4))
					# l 44-45 up 2, right 2
					var mid_line = Rect2(Vector2(0, 44), Vector2(frame_size.x, 2))
					preview.blend_rect(src, mid_line, preview_pos + mid_line.position + Vector2(2, -2))
					# l 42-43 copy on top
					var top_line = Rect2(Vector2(0, 42), Vector2(frame_size.x, 2))
					preview.blend_rect(src, top_line, preview_pos + top_line.position)

				add_part_preview_images("sit", preview_images, preview, part_type)
	emit_signal("preview", preview_images)


func create_empty_preview() -> Image:
	var preview = Image.new()
	preview.create(preview_size, preview_size, false, Image.FORMAT_RGBA8)
	return preview


func add_part_preview_images(state: String, preview_images: Dictionary, preview: Image, part_type: String) -> void:
	var texture = ImageTexture.new()
	texture.create_from_image(preview, 0)
	if not preview_images.has(part_type):
		preview_images[part_type] = {
			"idle": [],
			"jump": [],
			"use": [],
			"move": [],
			"sit": []
		}
	preview_images[part_type][state].append(texture)


func extract_body_and_arm_preview_images(frame: int, source: Image, preview_images: Dictionary) -> void:
	var pos = { # coordinates for the body spritesheet
			"body": {
				"idle": Vector2(0, 0),
				"jump": Vector2(1, 0),
				},
			"arm": {
				"shoulder": Vector2(0, 1),
				"idle": [ Vector2(2, 0) ],
				"jump": [ Vector2(2, 1) ],
				"use":  [ Vector2(3, 0), Vector2(4, 0), Vector2(5, 0), Vector2(6, 0) ],
				"move": [ Vector2(3, 1), Vector2(4, 1), Vector2(5, 1), Vector2(6, 1) ],
			},
			# back arm and female is the same as front and male, with this offset
			"alt_offset": Vector2(0, 2),
		}

	var state: String = get_state(frame)
	var arm_index: int = get_arm_index(frame)
	var upshift := Vector2.ZERO # this shifts the body sprite up when the foot is up
	match frame:
		7,8,9,14,15,16:
			upshift = Vector2(0 , -2)

	add_body_part_preview_from_position(
		"ArmBack", frame_size * (pos.arm[state][arm_index] + pos.alt_offset),
		source, upshift, state, preview_images
	)
	add_body_part_preview_from_position(
		"Body", frame_size * pos.body[state if state == "jump" else "idle"],
		source, upshift, state, preview_images
	)
	add_body_part_preview_from_position(
		"Female", frame_size * pos.body[state if state == "jump" else "idle"] + pos.alt_offset,
		source, upshift, state, preview_images
	)
	add_body_part_preview_from_position(
		"ArmFront", frame_size * pos.arm[state][arm_index],
		source, upshift, state, preview_images
	)
	add_body_part_preview_from_position(
		"Shoulder", frame_size * pos.arm.shoulder,
		source, upshift, state, preview_images
	)


func add_body_part_preview_from_position(part_type: String, position: Vector2, source: Image, upshift: Vector2, state: String, preview_images: Dictionary):
	# since the positions are "coordinates" on the body sprite, they need to be
	# multiplied by the frame_size to get the real pixel values
	var preview = create_empty_preview()
	preview.blend_rect(
		source,
		Rect2(position, frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(state, preview_images, preview, part_type)
	if state == "idle":
		add_part_preview_images("sit", preview_images, preview, part_type)


# up frames and arm positions (0 midback, 1 back, 1 midfront, 3 front)
#  6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19
#  0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0 	up
#  0, 1, 1, 1, 1, 0, 0, 0, 2, 3, 3, 2, 0, 0		arms
func get_state(frame: int) -> String:
	match frame:
		0:
			return "idle"
		1, 2, 3, 4:
			return "use"
		5:
			return "jump"
		_:
			return "move"


func get_arm_index(frame: int) -> int:
	match frame:
		1, 2, 3, 4:
			return frame - 1 # arm array index from 0
		7, 8, 9, 10:
			return 1
		14, 17:
			return 2
		15, 16:
			return 3
		_:
			return 0
