extends Control

var closebuttonoffset = [14,5]
var closebutton
var open_sound = 'sound/menu_open'
var close_sound = 'sound/menu_close'
var close_played = false

func _ready():

	for i in [open_sound, close_sound]:
		resources.preload_res(i)
#	if resources.is_busy(): yield(resources, "done_work")

	rect_pivot_offset = Vector2(rect_size.x/2, rect_size.y/2)
	closebutton = load("res://files/Close Panel Button/CloseButton.tscn").instance()
	add_child(closebutton)
#	move_child(closebutton, 0)
	closebutton.raise()
	closebutton.connect("pressed", self, 'hide')
	RepositionCloseButton()

func RepositionCloseButton():
	var rect = get_global_rect()
	var pos = Vector2(rect.end.x - closebutton.rect_size.x - closebuttonoffset[0], rect.position.y + closebuttonoffset[1])
	closebutton.rect_global_position = pos

func show():
	if resources.is_busy(): yield(resources, "done_work")
	if !is_visible_in_tree():
		input_handler.PlaySound(open_sound)
		close_played = false
		input_handler.Open(self)
	#globals.call_deferred("EventCheck");

func hide():
	if resources.is_busy(): yield(resources, "done_work")
	if is_visible_in_tree() && close_played == false:
		input_handler.PlaySound(close_sound)
		close_played = true
		input_handler.Close(self)
