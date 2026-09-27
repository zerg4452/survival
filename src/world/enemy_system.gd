class_name EnemySystem
extends RefCounted
## 적 이동(추적·분리·플레이어 몸체 밖으로·벽)과 접촉 피해(GAME_DESIGN 13.2, D-014, D-015).

## 겹친 위치가 정확히 같을 때 밀어낼 방향을 ID 로 정하는 각도 간격(황금각, 라디안).
const TIE_ANGLE: float = 2.39996323

var grid: SpatialGrid = SpatialGrid.new(1.0)


## 틱 처리 5단계. 적 ID 오름차순으로 처리한다.
func move_enemies(state: RunState, cfg: CombatConfig, dt: float) -> void:
	var p: PlayerState = state.player
	for e: EnemyState in state.enemies:
		if not e.is_targetable():
			continue
		var to: Vector2 = p.pos - e.pos
		var d: float = to.length()
		var stop: float = p.body_radius + e.definition.body_radius
		if d > stop:
			var step: float = minf(e.definition.move_speed * dt, d - stop)
			e.pos += to * (step / d)

	grid.rebuild(state.enemies)
	for e: EnemyState in state.enemies:
		if not e.is_targetable():
			continue
		for o: EnemyState in grid.neighbors(e.pos):
			if o.id <= e.id:
				continue
			var delta: Vector2 = o.pos - e.pos
			var min_d: float = e.definition.body_radius + o.definition.body_radius
			var d2: float = delta.length_squared()
			if d2 >= min_d * min_d:
				continue
			var dd: float = sqrt(d2)
			var n: Vector2 = delta / dd if dd > 1e-6 else Vector2.RIGHT.rotated(float(e.id + o.id) * TIE_ANGLE)
			var push: float = (min_d - dd) * 0.5
			e.pos -= n * push
			o.pos += n * push

	# 경공 중에는 적 몸체를 통과한다(GAME_DESIGN 7.2). 끝난 뒤 겹쳐 있으면 그때 밀어낸다(D-014).
	var push_out: bool = not p.is_dashing()
	for e: EnemyState in state.enemies:
		if not e.is_targetable():
			continue
		if push_out:
			var away: Vector2 = e.pos - p.pos
			var min_pd: float = p.body_radius + e.definition.body_radius
			var ad: float = away.length()
			if ad < min_pd:
				var n: Vector2 = away / ad if ad > 1e-6 else Vector2.RIGHT.rotated(float(e.id) * TIE_ANGLE)
				e.pos = p.pos + n * min_pd
		e.pos = Arena.clamp_circle(cfg, e.pos, e.definition.body_radius)


## 틱 처리 9단계. 무적에 막힌 접촉은 적의 대기시간을 소모하지 않는다(D-015).
static func contact_damage(state: RunState, cfg: CombatConfig) -> void:
	var p: PlayerState = state.player
	for e: EnemyState in state.enemies:
		if not e.is_targetable():
			continue
		if e.contact_cooldown_remaining > SimConstants.EPS:
			continue
		var reach: float = p.body_radius + e.definition.body_radius + cfg.contact_margin
		if e.pos.distance_squared_to(p.pos) > reach * reach:
			continue
		if p.is_invulnerable() or state.debug_invincible:
			continue
		var dmg: float = Damage.after_defense(e.definition.contact_damage, p.defense, cfg)
		p.hp -= dmg
		state.stats.damage_taken += dmg
		state.stats.contact_hits += 1
		state.last_damage_source = "%s 접촉" % e.definition.display_name
		p.hit_invuln_remaining = cfg.player_hit_invuln
		e.contact_cooldown_remaining = e.definition.contact_interval
