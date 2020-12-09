extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

# fix these values, maybe get rid of delta
const FRICTION = 500
const ACCELERATION = 500
const MAX_SPEED = 80

enum {
	MOVE,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

onready var animatedSprite = $AnimatedSprite
#onready var animationPlayer = $AnimationPlayer
#onready var animationTree = $AnimationTree
#onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var swordCollisionShape = $HitboxPivot/SwordHitbox/CollisionShape2D
onready var hitboxPivot = $HitboxPivot
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer
onready var lightSource = $Light

func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	#animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

#use _physics_process if you need access to certain physics variables
func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
			
		ATTACK:
			attack_state()

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		#animationTree.set("parameters/Idle/blend_position", input_vector)
		#animationTree.set("parameters/Run/blend_position", input_vector)
		#animationTree.set("parameters/Attack/blend_position", input_vector)
		animatedSprite.play("Walk")
		lightSource.offset.y = input_vector.y * 40
		lightSource.offset.x = input_vector.x * 40
		#animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		if velocity.x != 0:
			animatedSprite.flip_h = velocity.x > 0
			if animatedSprite.flip_h:
				hitboxPivot.rotation_degrees = 0 
			else:
				hitboxPivot.rotation_degrees = -180
	else:
		#animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		animatedSprite.play("Idle")
	
	move()
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func attack_state():
	velocity = Vector2.ZERO
	animatedSprite.play("Attack")
	swordCollisionShape.disabled = false
	#animationState.travel("Attack")
	
func move():
	#pass in linear velocity, what is a linear velocity?
	velocity = move_and_slide(velocity)

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.6)
	hurtbox.create_hit_effect()
	#var playerHurtSound = PlayerHurtSound.instance()
	#get_tree().current_scene.add_child(playerHurtSound)


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")


func _on_AnimatedSprite_animation_finished():
	swordCollisionShape.disabled = true
	state = MOVE
