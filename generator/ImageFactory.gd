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
		src_pos = Vector2(0, frame * frame_size.y)

		var preview = Image.new()
		preview.create(preview_size, preview_size, false, Image.FORMAT_RGBA8)
		for sprite in set_images:
			var part_type = sprite.name.rsplit('_', false, 1)[1]
			if not part_type:
				continue

			src = sprite.image
			if src.get_width() > frame_size.x:
				extract_body_and_arm_preview_images(frame, src, preview_images, preview)
			else:
				preview.fill(Color.transparent)
				preview.blend_rect(src, Rect2(src_pos, frame_size), preview_pos)
				add_part_preview_images(frame, preview_images, preview, part_type)

	emit_signal("preview", preview_images)


#func compile_set_image(set: JourneysTrendVanitySet):
#	var src_pos : Vector2 = Vector2.ZERO
#	var src : Image
#	for frame in frame_count:
#		src_pos = Vector2(0, frame * frame_size.y)
#
#		for item in set.items:
#			if item.sprites.empty():
#				continue
#
#			var preview = Image.new()
#			preview.create(preview_size, preview_size, false, Image.FORMAT_RGBA8)
#			for sprite in item.sprites:
#				var part_type = sprite.name.rsplit('_', false, 1)[1]
#				if not part_type:
#					continue
#
#				src = sprite.image
#				if src.get_width() > frame_size.x:
#					extract_body_and_arm_preview_images(frame, src, set, preview)
#				else:
#					preview.blend_rect(src, Rect2(src_pos, frame_size), preview_pos)
#					add_part_preview_images(frame, set, preview, part_type)
#
#	emit_signal("preview", set)


func add_part_preview_images(frame: int, preview_images: Dictionary, preview: Image, part_type: String) -> void:
	var state: String = get_state(frame)
	var texture = ImageTexture.new()
	texture.create_from_image(preview, 0)
	if not preview_images.has(part_type):
		preview_images[part_type] = {
			"idle": [],
			"jump": [],
			"use": [],
			"move": []
		}
	preview_images[part_type][state].append(texture)


func extract_body_and_arm_preview_images(frame: int, source: Image, preview_images: Dictionary, preview: Image) -> void:
	var pos = {
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

	# since the positions are "coordinates" on the body sprite, they need to be
	# multiplied by the frame_size to get the real pixel values
	# order from back to front: back arm, body, front arm, shoulder
	preview.fill(Color.transparent)
	preview.blend_rect(
		source,
		Rect2(frame_size * (pos.arm[state][arm_index] + pos.alt_offset), frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(frame, preview_images, preview, "ArmBack")

	preview.fill(Color.transparent)
	preview.blend_rect(
		source,
		Rect2(frame_size * pos.body[state if state == "jump" else "idle"], frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(frame, preview_images, preview, "Body")

	preview.fill(Color.transparent)
	preview.blend_rect(
		source,
		Rect2(frame_size * pos.body[state if state == "jump" else "idle"] + pos.alt_offset, frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(frame, preview_images, preview, "Female")

	preview.fill(Color.transparent)
	preview.blend_rect(
		source,
		Rect2(frame_size * pos.arm[state][arm_index], frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(frame, preview_images, preview, "ArmFront")

	preview.fill(Color.transparent)
	preview.blend_rect(
		source,
		Rect2(frame_size * pos.arm.shoulder, frame_size),
		preview_pos + upshift
	)
	add_part_preview_images(frame, preview_images, preview, "Shoulder")


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
