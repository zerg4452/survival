class_name MainAttackSystem
extends RefCounted
## 주공 자동 공격: 대기시간·조준·내공·인스턴스 생성과 판정(GAME_DESIGN 5~7장, D-008~D-012).


## 틱 처리 6단계. 준비 상태이고 목표가 있으면 인스턴스를 만든다. 목표가 없으면 아무것도 바꾸지 않는다.
static func try_fire(state: RunState, cfg: CombatConfig) -> AttackInstance:
	var rt: MartialRuntime = state.main_martial
	var def: MartialDefinition = rt.definition
	var p: PlayerState = state.player
	if rt.cooldown_remaining > SimConstants.EPS:
		return null
	var target: EnemyState = Targeting.pick_primary(state.enemies, p.pos, def.shape)
	if target == null:
		return null

	var vx: float = target.pos.x - p.pos.x
	var vy: float = target.pos.y - p.pos.y
	var d: float = sqrt(vx * vx + vy * vy)
	if d >= 1e-6:
		rt.last_aim_x = vx / d
		rt.last_aim_y = vy / d

	var pay: Dictionary = Damage.pay_or_basic(p.mp, def.mp_cost)
	var paid: bool = pay["paid"]
	p.mp = pay["mp_after"]

	var inst: AttackInstance = AttackInstance.new()
	inst.instance_id = state.alloc_id()
	inst.source_id = def.id
	inst.effect_kind = AttackInstance.EffectKind.MAIN_NORMAL if paid else AttackInstance.EffectKind.MAIN_BASIC
	inst.can_trigger_procs = false
	inst.created_tick = state.tick
	inst.origin = p.pos
	inst.dir_x = rt.last_aim_x
	inst.dir_y = rt.last_aim_y
	inst.shape = def.shape
	inst.damage = def.damage * (1.0 if paid else cfg.basic_damage_ratio)
	inst.max_targets = def.max_targets
	inst.remaining_active = def.active_time
	inst.forced_first_target_id = target.id

	state.attacks.append(inst)
	state.log_attack(inst)
	rt.cooldown_remaining = def.interval
	rt.last_target_pos = target.pos
	rt.last_fire_tick = state.tick
	if paid:
		state.stats.normal_attacks += 1
	else:
		state.stats.basic_attacks += 1
	return inst


## 틱 처리 7단계. 생성 순서대로 활성 인스턴스를 판정한다. 같은 적은 인스턴스당 1회.
static func resolve(state: RunState) -> void:
	for inst: AttackInstance in state.attacks:
		var is_new: bool = inst.created_tick == state.tick
		if not is_new and inst.remaining_active <= SimConstants.EPS:
			continue
		var hits: Array[EnemyState] = Targeting.select_hits(state.enemies, inst)
		inst.forced_first_target_id = -1
		for e: EnemyState in hits:
			inst.hit_ids[e.id] = true
			inst.hit_count += 1
			apply_damage_to_enemy(state, e, inst.damage)


## 패링 창(D-025): 마지막 주공 발동 후 window 초 이내, 또는 다음 발동까지 window 초 이내.
## 접촉 거리(0.8칸)는 권법 사거리 안이므로 대기시간이 끝나면 반드시 발동한다. 그래서 "다음 발동"을 대기시간으로 판단한다.
static func in_parry_window(state: RunState, window: float) -> bool:
	var rt: MartialRuntime = state.main_martial
	var since: float = float(state.tick - rt.last_fire_tick) * SimConstants.FIXED_DT
	if since <= window + SimConstants.EPS:
		return true
	return rt.cooldown_remaining <= window + SimConstants.EPS


## 적 방어력은 M0 에서 0 이므로 방어식 결과는 원 피해와 같다.
static func apply_damage_to_enemy(state: RunState, e: EnemyState, dmg: float) -> void:
	if not e.alive:
		return
	state.stats.damage_dealt += minf(dmg, e.hp)
	e.hp -= dmg
	e.last_hit_tick = state.tick
	if e.hp <= SimConstants.EPS:
		e.alive = false
		state.stats.kills += 1
		state.deaths_this_tick.append(e.id)
		state.log_death(e.pos)
