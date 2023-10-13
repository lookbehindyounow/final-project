static func get_HUD_angles(transform,target_pos):
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	var clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var forward_angle=acos((target_pos-transform.origin).normalized().dot(transform.basis.z))
	
	return [clock_face,forward_angle]

static func find_intercept(transform,target_pos,target_velocity):
	# bullet speed is 50
	var targToPlayer_dot_targV=(transform.origin-target_pos).normalized().dot(target_velocity.normalized())
	var sin_target_travel_angle=target_velocity.length()*sqrt(1-(targToPlayer_dot_targV**2))/100
	var bullet_intercept_angle=PI-asin(sin_target_travel_angle)-acos(targToPlayer_dot_targV)
	var target_travel=sin_target_travel_angle*(transform.origin-target_pos).length()/sin(bullet_intercept_angle)
	var bullet_intercept_pos=target_pos+target_travel*target_velocity.normalized()
	
	return bullet_intercept_pos

static func track(transform,target_pos,target_velocity,enemy=true):
	var HUD_angles=get_HUD_angles(transform,target_pos)
	var ahead_HUD_angles=null
	
	if enemy:
		var bullet_intercept_pos=find_intercept(transform,target_pos,target_velocity)
		ahead_HUD_angles=get_HUD_angles(transform,bullet_intercept_pos)
	
	return [HUD_angles,ahead_HUD_angles,target_pos]

static func instruct_turn_old(clock_face):
	var rolling=0
	var pitching=0
	# could maybe reduce code here by using positive/negative dot products (against all transform basis axes) to figure out which way to go
	if abs(clock_face)>PI/20 && abs(clock_face)<0.95*PI: # if target not at top or bottom centre of clock face
		if abs(clock_face)<2*PI/3: # target in top 2/3 of clock face
			if clock_face>0:# top-right
				rolling+=1
			else: # top-left
				rolling-=1
		elif abs(clock_face)>=2*PI/3: # target in bottom 1/3 of clock face
			if clock_face>0: # bottom-right
				rolling-=1
			else: # bottom-left
				rolling+=1
	
	if abs(clock_face)<0.4*PI: # target in top 2/5 of clock face
		pitching-=1
	elif abs(clock_face)>0.8*PI: # target in botom 1/5 of clock face
		pitching+=1
	
	return [rolling,pitching]

static func instruct_turn_new(transform,target_pos):
	var rolling=0
	var pitching=0
	var target_direction=(target_pos-transform.origin).normalized()
	var targDir_dot_myUp=target_direction.dot(transform.basis.y)
	
	# xor?
	if targDir_dot_myUp>0: # target above
		if target_direction.dot(transform.basis.x)>0: # top-left
			rolling=targDir_dot_myUp-1
		else: # top-right
			rolling=1-targDir_dot_myUp
	else: # target below
		if target_direction.dot(transform.basis.x)>0: # bottom-left
			rolling=1-targDir_dot_myUp
		else: # bottom-right
			rolling=targDir_dot_myUp-1

	if targDir_dot_myUp: # target in top 2/5 of clock face (find value)
		pitching-=1
	elif targDir_dot_myUp: # target in botom 1/5 of clock face
		pitching+=1

	return [rolling,pitching]

static func autopilot(transform,speed,pitch_speed,HUD_points): # target is index of HUD point
	var accelerating=0
	
	var turn_instructions=instruct_turn_old(HUD_points[0][1][0]) # aim for player's ahead marker
#	var turn_instructions=instruct_turn_new(transform,HUD_points[0][2]) # aim for player's ahead marker
	
	if transform.origin.y<5+speed/pitch_speed: # if near ground
		if transform.origin.y<5+(speed/pitch_speed)*(1-sin(Vector3.DOWN.angle_to(transform.basis.z))): # if too near ground for current orientation
			if transform.basis.y.dot(Vector3.DOWN)<0: # upright
				turn_instructions[1]=-1 # pitch up
				if transform.basis.x.dot(Vector3.DOWN)>0: # leftside down
					turn_instructions[0]=1 # roll right
				else: # rightside down
					turn_instructions[0]=-1 # roll left
			else: # upside down
				turn_instructions[1]=1 # pitch down
				if transform.basis.x.dot(Vector3.DOWN)>0: # leftside down
					turn_instructions[0]=-1 # roll left
				else: # rightside down
					turn_instructions[0]=1 # roll right
	
	for point in HUD_points:
		var to_point=point[2]-transform.origin
		if to_point.length()<5:
			var avoid_instructions=instruct_turn_old(point[0][0])
			turn_instructions[0]=-avoid_instructions[0]
			turn_instructions[1]=-avoid_instructions[1]
			
			if to_point.dot(transform.basis.z)>0:
				accelerating=-1
			else:
				accelerating=1
	
	return [turn_instructions[0],turn_instructions[1],accelerating]

static func turn(basis,roll,pitch,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	return basis

static func shoot(shooter):
	var bullet=shooter.get_node("/root/Main").bullet_scene.instantiate()
	bullet.transform=shooter.transform
	bullet.position+=shooter.transform.basis.z	
	bullet.linear_velocity=bullet.transform.basis.z*100
	shooter.get_node("/root/Main").add_child(bullet)
