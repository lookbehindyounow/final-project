extends RigidBody3D
var life=10
signal hit
var target=null
var target_angles=null
var watching=false

func _ready():
	contact_monitor=true
	max_contacts_reported=1
	continuous_cd=true
	if target:
		target.missiles_following.append(self)

func _process(delta):
	life-=delta
	if life<0:
		explode()
	
	if get_colliding_bodies():
		if get_colliding_bodies()[0].is_in_group("jets"):
			hit.connect(get_colliding_bodies()[0]._on_missile_hit)
			hit.emit()
		explode()
	
	if target:
		target_angles=target.Jet.get_HUD_angles(transform,target.position)
		var pitching=-3*target_angles[1]*cos(target_angles[0])
		var yawing=-3*target_angles[1]*sin(target_angles[0])
		transform.basis=target.Jet.turn(transform.basis,0,pitching,yawing,delta)
		if target_angles[1]>PI/2:
			target.missiles_following.erase(self)
			target=null
			target_angles=null
	position+=20*delta*transform.basis.z

func explode():
	if watching:
		get_node("/root/Main/UI").missile=null
	if target:
		target.missiles_following.erase(self)
	get_node("/root/Main").explosion(position)
	queue_free()
