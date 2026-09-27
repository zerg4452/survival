class_name GameContent
extends RefCounted
## 로드된 콘텐츠 묶음. errors 가 비어 있을 때만 사용한다.

var config: CombatConfig = null
var martials: Dictionary[StringName, MartialDefinition] = {}
var martial_order: Array[StringName] = []
var enemies: Dictionary[StringName, EnemyDefinition] = {}
var errors: Array[String] = []


func is_ok() -> bool:
	return errors.is_empty()


func martial(id: StringName) -> MartialDefinition:
	return martials.get(id, null)


func enemy(id: StringName) -> EnemyDefinition:
	return enemies.get(id, null)
