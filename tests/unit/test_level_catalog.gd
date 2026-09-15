extends TestCase

var catalog: LevelCatalog


func before_each() -> void:
	catalog = LevelCatalog.new()
	for id in [&"one", &"two", &"three"]:
		var info := LevelInfo.new()
		info.id = id
		catalog.levels.append(info)


func test_get_level_returns_matching_entry() -> void:
	assert_eq(catalog.get_level(&"two").id, &"two")
	assert_null(catalog.get_level(&"missing"))


func test_next_level_stops_at_last() -> void:
	assert_eq(catalog.next_level(&"one").id, &"two")
	assert_null(catalog.next_level(&"three"), "last level has no next")
	assert_null(catalog.next_level(&"missing"), "unknown level has no next")


func test_previous_level_stops_at_first() -> void:
	assert_eq(catalog.previous_level(&"three").id, &"two")
	assert_null(catalog.previous_level(&"one"))


func test_default_catalog_is_valid() -> void:
	var shipped := LevelCatalog.load_default()
	assert_not_null(shipped, "default catalog loads")
	assert_true(shipped.levels.size() > 0, "default catalog lists levels")
	var seen := {}
	for level in shipped.levels:
		assert_false(seen.has(level.id), "duplicate level id %s" % level.id)
		seen[level.id] = true
		assert_true(ResourceLoader.exists(level.scene_path), "scene exists for %s: %s" % [level.id, level.scene_path])
