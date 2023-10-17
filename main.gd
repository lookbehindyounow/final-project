extends Node

var enemy_scene=preload("res://enemy.tscn")
var bullet_scene=preload("res://bullet.tscn")
var missile_scene=preload("res://missile.tscn")
var explosion_scene=preload("res://explosion.tscn")
var enemies=[]
var initial_enemy_count=5
var current_camera=-1
var gaming=true

func _ready():
	# first on screen instance of these objects (even though they're hidden by obstacles) lags the thing like hell so getting it out the way immediately stops it from affecting gameplay
	var bull=bullet_scene.instantiate()
	var miss=missile_scene.instantiate()
	bull.position=Vector3(60,1,60)
	bull.linear_velocity=Vector3.DOWN*100
	miss.position=Vector3(60,1,60)
	miss.transform.basis=miss.transform.basis.rotated(miss.transform.basis.x,PI/2)
	add_child(bull)
	add_child(miss)
	await get_tree().create_timer(1.0).timeout
	
	for i in range(initial_enemy_count):
		enemies.append(enemy_scene.instantiate())
		enemies[i].transform.origin=Vector3(0,6,5)
		enemies[i].transform=enemies[i].transform.rotated(Vector3.UP,(i+1)*(PI/2)/(initial_enemy_count+1))
		add_child(enemies[i])
	current_camera=initial_enemy_count-1
	update_camera()

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		update_camera()

func _on_enemy_die(dead):
	for i in range(enemies.size()):
		if enemies[i]==dead:
			enemies.remove_at(i)
			if current_camera>=i:
				current_camera-=1
				if current_camera==i-1:
					update_camera()
			break
	explosion(dead.position,0.35)
	dead.queue_free()
	
	if enemies.size()==0:
		$UI/Endgame.text="Those triangles had families"
		$UI/Endgame.show()

func update_camera():
	current_camera+=1
	var guy
	if current_camera>=enemies.size():
		guy=$Player
		current_camera=-1
	else:
		guy=enemies[current_camera]
	guy.get_node("Camera3D").current=true
	$UI.guy=guy
	if $UI.missile:
		$UI.missile.watching=false
		$UI.missile=null

func _on_restart_pressed():
	get_tree().reload_current_scene()

func explosion(location,cycle_length=0.2):
	var boom=explosion_scene.instantiate()
	boom.cycle_length=cycle_length
	boom.position=location
	add_child(boom)
