extends Control

signal confirmed

func setup(refund_value: int) -> void:
	%RefundLabel.text = "Recuperarás $%d" % refund_value

func _ready() -> void:
	%CancelButton.pressed.connect(_on_cancel)
	%SellButton.pressed.connect(_on_sell)
	%SellButton.grab_focus()

func _on_cancel() -> void:
	queue_free()

func _on_sell() -> void:
	confirmed.emit()
	queue_free()