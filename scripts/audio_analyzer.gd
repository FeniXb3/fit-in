extends Control
class_name AudioAnalyzer

signal frame_analyzed(analyzer_name: StringName, frame_number: int, fft: Array[float])
signal stream_finished

@onready var stream_player: AudioStreamPlayer = %StreamPlayer
@onready var visualization: ColorRect = %Visualization
@export_range(0, 1) var alpha: float = 1:
	set(value):
		alpha = value
		modulate.a = value
@export var color_bottom: Color = Color.GREEN
@export var color_top: Color = Color.RED
@export var outline_only: bool
@export_range(0.0, 0.7) var inactive_mask: float = 0.2

@export var base_visualization_material: ShaderMaterial
@export var stream: AudioStream
@export var bus_name: StringName
@export var columns: int = 128:
	set(value):
		columns = value
		if is_inside_tree():
			await get_tree().process_frame
		_resize_values(value)
		if visualization_material:
			visualization_material.set_shader_parameter("columns_count", value)

var spectrum: AudioEffectSpectrumAnalyzerInstance
var bus_index: int
var analyzer_effect_index: int
var visualization_material: ShaderMaterial

var min_values := []
var max_values := []
var frame_number := 0


const FREQ_MAX = 11050.0
const MIN_DB = 60
const ANIMATION_SPEED = 0.1
const HEIGHT_SCALE = 8.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	for i in AudioServer.get_bus_effect_count(bus_index):
		var effect = AudioServer.get_bus_effect_instance(bus_index, i)
		if effect is AudioEffectSpectrumAnalyzerInstance:
			spectrum = effect
			analyzer_effect_index = i
			break
	
	visualization_material = base_visualization_material.duplicate()
	visualization.material = visualization_material
	_resize_values(columns)
	visualization_material.set_shader_parameter("columns_count", columns)
	stream_player.bus = bus_name
	stream_player.stream = stream
	stream_player.play()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var prev_frequence = 0
	var data = []
	for i in range(1, columns + 1):
		var frequence = i * FREQ_MAX / columns
		var freq_magnitude = spectrum.get_magnitude_for_frequency_range(prev_frequence, frequence)
		var energy = clamp((MIN_DB + linear_to_db(freq_magnitude.length())) / MIN_DB, 0.0, 1.0)
		data.append(energy * HEIGHT_SCALE)
		prev_frequence = frequence
		
	if columns != max_values.size():
		return
		
	for i in range(columns):
		if data[i] > max_values[i]:
			max_values[i] = data[i]
		else:
			max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)
		if data[i] <= 0.0:
			min_values[i] = lerp(min_values[i], 0.0, ANIMATION_SPEED)
	var fft: Array[float] = []
	for i in range(columns):
		fft.append(lerp(min_values[i], max_values[i], ANIMATION_SPEED))
		
	visualization_material.set_shader_parameter("freq_data", fft)
	visualization_material.set_shader_parameter("alpha", modulate.a)
	visualization_material.set_shader_parameter("color_top", color_top)
	visualization_material.set_shader_parameter("color_bottom", color_bottom)
	visualization_material.set_shader_parameter("outline_only", outline_only)
	visualization_material.set_shader_parameter("inactive_mask", inactive_mask)
	
	frame_number += 1
	
	frame_analyzed.emit(name, frame_number, fft)
	
func _resize_values(count: int):
	min_values.resize(count)
	max_values.resize(count)
	min_values.fill(0.0)
	max_values.fill(0.0)


func _on_stream_player_finished() -> void:
	#stream_player.play()
	stream_finished.emit()
	
func play() -> void:
	stream_player.play()

func reset() -> void:
	frame_number = 0
	if stream is not AudioStreamMicrophone:
		play()
