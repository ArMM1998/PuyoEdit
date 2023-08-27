extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	displayMessage("Animation Editor Started")

var timer = 90
var time = 0.0
var fadeout_time = 30
var free = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	self.visible = time > 0
	if self.visible:
		if time <= fadeout_time:
			#@warning_ignore("integer_division")
			self.modulate = Color(1,1,1,1*(time/fadeout_time))
		time -= 16*delta
	else:
		free = true

func displayMessage(string, priority = false):
	if free or priority:
		if not string.ends_with("."):
			string += "."
		
		self.text = string
		time = timer
		self.modulate = Color(1,1,1,1)
		
		if priority:
			free = false
