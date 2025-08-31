extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$"Panel/VBoxContainer/Node Count".text = "[font_size=36]Nodes connected: %d" % Globals.num_nodes
	$"Panel/VBoxContainer/Death Count".text = "[font_size=36]Deaths: %d" % Globals.num_deaths
	var time_elapsed : float = Time.get_unix_time_from_system() - Globals.start_time 
	$"Panel/VBoxContainer/Total Time".text = "[font_size=36]Total time: %s" % Time.get_time_string_from_unix_time(time_elapsed)
	
	DialogueManager.show_dialogue_balloon(Globals.dialogue, "winner")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
