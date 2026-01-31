extends Control

@export var input_audio_analyzer: AudioAnalyzer
@export var expected_audio_analyzer: AudioAnalyzer
@export var correctness_label: Label

@export var input_frame_data: Dictionary = {}
@export var expected_frame_data: Dictionary = {}

@export var frame_data: Dictionary = {}
@export var epsilon: float = 0.002

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_audio_analyzer.frame_analyzed.connect(_on_frame_analyzed)
	expected_audio_analyzer.frame_analyzed.connect(_on_frame_analyzed)
	expected_audio_analyzer.stream_finished.connect(_on_stream_finished)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	#var is_close_enough = true
	#var diff = []
	#var correct_frequencies = 0.0
	#var total_frequencies = 0.0
	#
	#for frame_number in frame_data:
		#var data: Dictionary = frame_data[frame_number]
		#var diffs = {}
		#for analyzer_name in data:
			#if diffs.has(frame_number):
				##total_frequencies = diffs[frame_number].size()
				##for i in total_frequencies:
				#for i in diffs[frame_number].size():
					#total_frequencies += 1
					#diffs[frame_number][i] -= data[analyzer_name][i]
					#if absf(diffs[frame_number][i]) <= epsilon:
						#correct_frequencies += 1
						##is_close_enough = false
						##break
			#else:
				#diffs[frame_number] = data[analyzer_name]
			#
			##if not is_close_enough:
				##break
	#if total_frequencies > 0:
		#correctness_label.text = "%d" % ((correct_frequencies / total_frequencies)* 100)
		##correctness_label.text = str(correct_frequencies)

func update_frame_correctness(frame_number: int):
	var diff = []
	var correct_frequencies = 0.0
	var total_frequencies = 0.0
	
	var data: Dictionary = frame_data[frame_number]
	var diffs = {}
	for analyzer_name in data:
		if diffs.has(frame_number):
			for i in diffs[frame_number].size():
				total_frequencies += 1
				diffs[frame_number][i] -= data[analyzer_name][i]
				if absf(diffs[frame_number][i]) <= epsilon:
					correct_frequencies += 1
					#is_close_enough = false
					#break
		else:
			diffs[frame_number] = data[analyzer_name]
		
	if total_frequencies > 0:
		correctness_label.text = "%d%%" % ((correct_frequencies / total_frequencies) * 100)

func _on_frame_analyzed(analyzer_name: StringName, frame_number: int, fft: Array[float]) -> void:
	#var data = frame_data.get_or_add(analyzer_name, {})
	#data[frame_number] = fft
	var data: Dictionary = frame_data.get_or_add(frame_number, {})
	data[analyzer_name] = fft
	
	if data.keys().size() == 2:
		await get_tree().process_frame
		update_frame_correctness.call_deferred(frame_number)

func _on_stream_finished() -> void:
	await get_tree().create_timer(1).timeout
	input_audio_analyzer.reset.call_deferred()
	expected_audio_analyzer.reset.call_deferred(	)
	pass
