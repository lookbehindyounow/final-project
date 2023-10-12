extends Control
var screen_dimensions
var icon_scene=preload("res://icon.tscn")
var icons=[]

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"))

func _ready():
	screen_dimensions=get_node("/root").size

func _process(delta):
	var HUD_points=[]
	var enemies=get_node("/root/Main").enemies
	var camera=get_node("/root/Main").current_camera
	if camera==-1:
		HUD_points=get_node("/root/Main/Player").HUD_points
	else:
		HUD_points=enemies[camera].HUD_points
	
	for entity in icons:
		for icon in entity:
			icon.queue_free()
	icons=[]
	for i in range(HUD_points.size()):
		icons.append([icon_scene.instantiate()])
		# angle between top of HUD circle & forward is 0.65 rad
		var point_radius=min(1,HUD_points[i][0][1]/0.65)
		icons[i][0].position=Vector2(screen_dimensions/2)+((point_radius*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][0][0]))
		if point_radius<1:
			icons[i][0].set_type("hollow")
		if not HUD_points[i][2]:
			icons[i][0].set_colour("#00f")
		add_child(icons[i][0])
		
		if HUD_points[i][2]:
			if HUD_points[i][1][1]<0.65:
				icons[i].append(icon_scene.instantiate())
				icons[i][1].position=Vector2(screen_dimensions/2)+(((HUD_points[i][1][1]/0.65)*screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_points[i][1][0]))
				icons[i][1].set_type("ahead")
				add_child(icons[i][1])
