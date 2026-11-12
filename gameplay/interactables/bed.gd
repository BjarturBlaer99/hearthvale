class_name Bed
extends Talkable
## The hero's bed (P2b, GDD §6): face it and press interact, and it asks whether to sleep. Its
## words are a conversation in data (data/dialogue/bed.json); sleeping is that conversation's
## `sleep` effect. Draws nothing: the bed is a tile of the room. Position = its cell's top-left
## corner.


func prompt() -> String:
	return "Go to bed"
