extends GdUnitTestSuite
## The news at the top of the screen: news that comes while other news is up joins it on a
## line of its own; nothing is said twice; and past what fits, the oldest line gives way.


func test_the_first_news_is_a_line_alone() -> void:
	assert_array(Array(NoticeLines.joined(PackedStringArray(), "New quest: The Lost Shuttle"))).is_equal(["New quest: The Lost Shuttle"])


func test_more_news_joins_what_is_showing_below_it() -> void:
	var showing: PackedStringArray = ["Combat rose to level 2."]
	var both: PackedStringArray = NoticeLines.joined(showing, "Quest updated: A Place of Your Own")
	assert_array(Array(both)).is_equal(["Combat rose to level 2.", "Quest updated: A Place of Your Own"])
	assert_array(Array(showing)).override_failure_message("what was handed in is left as it was").is_equal(["Combat rose to level 2."])


func test_news_already_showing_is_not_said_twice() -> void:
	var showing: PackedStringArray = ["Quest updated: A Place of Your Own", "Farming rose to level 2."]
	assert_array(Array(NoticeLines.joined(showing, "Quest updated: A Place of Your Own"))).is_equal(Array(showing))
	assert_array(Array(NoticeLines.joined(showing, ""))).override_failure_message("no words, no line").is_equal(Array(showing))


func test_past_what_fits_the_oldest_gives_way() -> void:
	assert_int(NoticeLines.MOST).is_equal(3)
	var showing: PackedStringArray = []
	for news: String in ["one", "two", "three", "four"]:
		showing = NoticeLines.joined(showing, news)
	assert_array(Array(showing)).is_equal(["two", "three", "four"])
	assert_array(Array(NoticeLines.joined(["one", "two"], "three", 2))).is_equal(["two", "three"])
	assert_array(Array(NoticeLines.joined(["one", "two"], "three", 0))).override_failure_message("there is always room for the latest").is_equal(["three"])
