# 구조와 데이터 계약 — M0

작성일: 2026-09-27 · 상태: 제안. 게임 규칙의 기준은 [GAME_DESIGN.md](GAME_DESIGN.md), 세부 결정은 [DECISIONS.md](DECISIONS.md)(D-xxx)다. 이 문서는 M0 구현에 필요한 최소 구조만 정한다. 후속 마일스톤에서 추가할 필드는 표시만 하고 지금 만들지 않는다.

## 1. 엔진과 버전

| 항목 | 값 |
|---|---|
| 엔진 | Godot 4 안정판, 표준 빌드(.NET 아님) — D-001 |
| 언어 | GDScript, 모든 변수·인자·반환에 타입 명시 |
| 정확한 버전 | `4.7.2.stable.official.ed1daf0bf` (2026-09-27 설치, D-001). M0-01에서 README.md에 기록하고 고정한다 |
| 렌더러 | 2D 도형만 쓰므로 Compatibility 또는 Forward+. 실제 선택을 README.md에 기록한다 |
| 테스트 | 자체 헤드리스 실행기 — D-005 |

가능하면 프로젝트 설정에서 GDScript의 타입 없는 선언 경고를 오류로 올린다. 해당 버전에 그 설정이 있는지는 M0-01에서 확인한다.

## 2. 층 구분

```text
표시·입력 (Node)          시뮬레이션 (RefCounted, 엔진 물리 미사용)
─────────────────         ─────────────────────────────────────
main.gd (화면 전환)        RunSimulation.step(input: InputFrame)
GameView                    ├─ RunState (판의 모든 가변 상태)
 ├─ FixedStepRunner ──────▶ ├─ PlayerSystem   이동·경공·내공 회복
 ├─ InputLatch              ├─ EnemySystem    추적·분리·접촉 피해
 ├─ WorldRenderer (_draw,   ├─ MainAttackSystem 대기·조준·자원·인스턴스
 │   F1 디버그 표시 포함)     ├─ Spawner
 ├─ Camera2D                └─ 순수 함수: Shapes, Targeting, Damage, Arena
 └─ CanvasLayer: Hud, OverlayMenu(일시정지·결과)
MainMenu
```

`FixedStepRunner`와 `InputLatch`는 `RefCounted`라서 엔진 루프 없이 테스트할 수 있다. `GameView._process`가 이 둘로 틱을 구동한다.

규칙:

- 시뮬레이션 코드는 `Node`, `Input`, `get_tree()`, 전역 `randf()`를 참조하지 않는다. 난수는 `RunState.rng`만 쓴다. 입력은 `InputFrame`으로만 받는다.
- 표시 계층은 `RunState`를 읽기만 한다. 규칙은 전부 시뮬레이션에 있다.
- 하나의 `Player`나 `GameManager`에 무공별 분기를 하드코딩하지 않는다. 주공 차이는 `MartialDefinition` 데이터와 도형 종류 두 가지(`SECTOR`, `RECT_FORWARD`)로 표현한다. M0에서 효과 시스템·ECS·플러그인 구조는 만들지 않는다.

## 3. 디렉터리

```text
project.godot
README.md               엔진 버전, 실행·테스트 명령
content/
  combat_config.json    플레이어·경공·전투 공통·전장·카메라·M0 스폰
  martials.json         주공 4종
  enemies.json          혈강시
src/
  main.gd   진입점, 화면 전환, 개발용 인자
  core/     sim_constants, combat_config, game_content, content_loader,
            input_frame, input_latch, fixed_step_runner,
            player_state, player_system, run_state, run_stats, run_result,
            run_simulation
  combat/   shape_def, shapes, targeting, damage, attack_instance,
            main_attack_system
  martial/  martial_definition, martial_runtime
  world/    arena, enemy_definition, enemy_state, enemy_system,
            spawner, spatial_grid
  ui/       input_setup, ui_theme, main_menu, hud, overlay_menu,
            world_renderer, game_view
scenes/     main.tscn (Main 노드 하나. 나머지 UI는 코드로 생성)
tests/      run_tests.gd, test_*.gd, support/(test_case, sim_fixture)
```

`progression/`과 `save/`는 M2·M3에서 만든다. 16.2의 분류를 따르되 비어 있는 폴더를 미리 만들지 않는다.

## 4. 상수 (`sim_constants.gd`)

```text
FIXED_DT = 1.0 / 60.0
MAX_TICKS_PER_FRAME = 8
EPS = 1e-6
```

게임 수치는 여기 두지 않고 `content/`에 둔다.

## 5. 데이터 계약

### 5.1 `content/martials.json` → `MartialDefinition`

값은 GAME_DESIGN 6장 표를 그대로 옮긴다. 예시:

```json
{
  "id": "pajin_spear",
  "family": "SPEAR",
  "slot": "MAIN",
  "display_name": "파진창법",
  "damage": 48.0,
  "interval": 1.15,
  "mp_cost": 14.0,
  "max_targets": 4,
  "active_time": 0.1,
  "passive_defense": 0.0,
  "shape": { "kind": "RECT_FORWARD", "x_min_exclusive": 1.0, "x_max": 4.5, "half_width": 0.4 }
}
```

부채꼴 예: `"shape": { "kind": "SECTOR", "radius": 2.0, "angle_deg_total": 90.0 }`(D-006).

| 필드 | 형식 | 비고 |
|---|---|---|
| `id` | StringName | 고정 ID. 표시 이름을 바꿔도 변경하지 않는다(16.2). `cheongun_sword`, `swaeam_blade`, `pajin_spear`, `yeonhwan_fist` |
| `family` | enum | SWORD, BLADE, SPEAR, FIST |
| `slot` | enum | M0는 MAIN만 |
| `damage`, `interval`, `mp_cost` | float | 모두 > 0 |
| `max_targets` | int | ≥ 1 |
| `active_time` | float | ≥ 0. D-010 |
| `passive_defense` | float | 연환권법만 10. D-013 |
| `shape` | object | 종류별 필드. 누락되면 로드 오류 |

M2에서 추가: `five_star_effect_id`, `apex_effect_id`, 숙련도 성장 규칙 참조.

기본 초식 비율 0.65는 모든 주공에 공통인 규칙(7.1)이므로 `combat_config.json`의 `combat.basic_damage_ratio`에 둔다.

### 5.2 `content/enemies.json` → `EnemyDefinition`

`id` = `blood_jiangshi`. 필드: `max_hp` 20, `move_speed` 1.6, `contact_damage` 8, `contact_interval` 1.0, `body_radius` 0.35(D-014), `exp` 1. `exp`는 M1에서 쓰지만 13.2의 정의값이므로 지금 적어 둔다.

### 5.3 `content/combat_config.json`

```text
player:  max_hp 100, move_speed 4.0, body_radius 0.35, hit_invuln 0.35,
         base_defense 0, max_mp 100, mp_regen 12.0
dash:    distance 2.5, duration 0.18, iframe 0.12, charges 1, recharge 4.0
combat:  basic_damage_ratio 0.65, defense_min 0, defense_max 300,
         contact_margin 0.1   (치명타는 M0에 없음. 확률 0을 숨겨 두지 않는다)
arena:   size 51, wall 1, start [25.5, 25.5]
camera:  visible_rows 15
m0_spawn: enemy_id blood_jiangshi, rate 1.5, min_dist 8, max_dist 13, tries 16, telegraph 0.8,
          normal_cap 300, debt_cap 2.0
```

### 5.4 `MartialRuntime` (판 안 상태)

| 필드 | 형식 | 초기값 |
|---|---|---|
| `definition` | MartialDefinition | 선택한 주공 |
| `cooldown_remaining` | float | 0.0 (D-009) |
| `last_aim_x`, `last_aim_y` | float(64비트) | 1.0, 0.0. 경계 판정 정밀도 때문에 Vector2 대신 스칼라 두 개로 둔다(D-007). `last_aim_dir()`로 Vector2를 얻는다 |
| `last_target_pos`, `last_fire_tick` | Vector2, int | 표시·디버그용 |

M2에서 추가: `mastery_points: int`, `five_star_unlocked: bool`, `apex_unlocked: bool`, `effective_hit_counter: int`, `focus_training_count: int`, `last_body_hit_tick: int`.

### 5.5 `RunState`

| 필드 | 형식 | 비고 |
|---|---|---|
| `seed` | int | D-020 |
| `rng` | RandomNumberGenerator | `seed`로 초기화. 스폰만 사용 |
| `tick` | int | 시간의 원본 |
| `phase` | enum | RUNNING, PAUSED, RESULT. CHOICE는 M1에서 추가 |
| `player` | PlayerState | 아래 |
| `main_martial` | MartialRuntime | |
| `enemies` | Array[EnemyState] | ID 오름차순 유지 |
| `attacks` | Array[AttackInstance] | 생성 순 |
| `spawn_acc` | float | D-017 |
| `next_entity_id` | int | 적·공격 인스턴스 공용. 재사용하지 않는다 |
| `debug_used` | bool | D-022 |
| `stats` | RunStats | 처치 수, 가한/받은 피해, 정상/기본 초식 발동 수, 경공 사용 수 |
| `result` | RunResult 또는 null | 사유(M0는 DEATH만), 종료 틱, 생존 시간, 처치 수, 마지막 피해 원인 |
| `last_damage_source` | String | 결과 화면용 |
| `deaths_this_tick` | Array[int] | 이번 틱에 사망이 확정된 적 ID. 틱 시작마다 비운다 |
| `attack_log`, `death_log` | 배열(상한 32, 64) | 표시 전용 기록. 규칙에 쓰지 않는다(D-023) |
| `auto_spawn`, `enemy_hp_mult`, `debug_invincible` | bool, float, bool | 디버그 조작 상태(D-022). 테스트에서도 사용 |

`PlayerState`: `pos: Vector2`, `hp`, `max_hp`, `mp`, `max_mp`, `mp_regen`, `move_speed`, `body_radius`, `defense`(= base + 주공 `passive_defense`), `hit_invuln_remaining`, `move_input: Vector2`(이번 틱 입력), `last_move_dir: Vector2`, `dash_max_charges: int`, `dash_charges: int`, `dash_recharge_remaining`, `dash_remaining`, `dash_dir: Vector2`, `dash_iframe_remaining`.

`EnemyState`: `id: int`, `definition`, `pos: Vector2`, `hp`, `max_hp`, `alive: bool`(한 번만 false가 됨), `active: bool`(스폰 예고 종료), `telegraph_remaining`, `contact_cooldown_remaining`, `last_hit_tick`(표시용).

M2~M3에서 추가: 장착 목록(4슬롯), 선택 상태, 판당 부활 소진 여부, 판 시작 경지 스냅샷. `ProfileState`는 M3에서 만든다.

### 5.6 `AttackInstance`

16.3의 이벤트 필드를 M0에 필요한 만큼만 둔다.

| 필드 | 비고 |
|---|---|
| `instance_id` | `next_entity_id`에서 발급 |
| `source_id` | 주공 정의 ID |
| `effect_kind` | MAIN_NORMAL, MAIN_BASIC (D-011) |
| `can_trigger_procs` | M0는 항상 false. 파생 효과가 생기는 M2부터 사용한다 |
| `created_tick` | 생성 틱. 생성 틱에는 활성 시간과 무관하게 판정한다 |
| `origin`, `dir_x`, `dir_y` | 생성 시 고정. 방향은 64비트 스칼라(D-007), `dir()`로 Vector2를 얻는다 |
| `shape`, `damage`, `max_targets` | 생성 시 확정한 값 |
| `remaining_active` | `active_time`에서 시작 |
| `hit_ids`, `hit_count` | Dictionary[int, bool]와 명중 수. 인스턴스당 1회 명중과 활성 시간 전체의 최대 대상 수를 보장(T16) |
| `forced_first_target_id` | 주 목표. 생성 틱에 무조건 포함 (D-008) |

## 6. 순수 함수 (테스트 대상)

```text
Shapes.contains(shape, origin, dir, point) -> bool
    국소 좌표를 64비트 스칼라로 계산(D-007).
    SECTOR: d <= radius AND (d < 1e-6 OR dot(dir, v)/d >= cos(angle_total/2))
    RECT_FORWARD: x_min_exclusive < lx <= x_max AND abs(ly) <= half_width
Shapes.aim_range_ok(shape, d) -> bool
    SECTOR: d <= radius ; RECT_FORWARD: x_min_exclusive < d <= x_max
Targeting.pick_primary(enemies, origin, shape) -> EnemyState 또는 null   (D-008)
Targeting.select_hits(enemies, instance) -> Array   (거리·ID 순, 상한·hit_ids 반영)
Damage.pay_or_basic(mp, cost, eps) -> {paid: bool, mp_after: float}   (D-007, D-011)
Damage.after_defense(raw, defense) -> float   raw × 100 / (100 + clamp(defense, 0, 300))
Arena.clamp_circle(pos, radius) -> Vector2    내부 [1 + r, 50 - r]
```

## 7. 틱 처리 순서

D-018을 따른다. `RunSimulation.step()`은 `phase == RUNNING`일 때만 상태를 바꾼다.

## 8. 시뮬레이션 구동과 입력

- `GameView._process(delta)` → `FixedStepRunner.advance(delta, step_fn)`: `acc += delta`. `acc >= FIXED_DT`이고 처리한 틱이 `MAX_TICKS_PER_FRAME` 미만인 동안 `step_fn`을 호출하고 `acc -= FIXED_DT`. 상한에 걸리면 남은 `acc`를 버리고 `dropped_ticks`를 올린다. `step_fn`은 `InputFrame.make(현재 이동, latch.consume_dash())`로 `sim.step`을 부른다.
- `InputFrame`: `move: Vector2`(정규화 전 원시 값), `dash_pressed: bool`. 이동은 현재 눌린 상태이고, 경공은 `InputLatch`가 실제로 도는 첫 틱에서만 소비한다(D-003).
- Esc, 메뉴, 재시작은 틱 사이에 표시 계층에서 `phase`를 바꾸거나 새 `RunState`를 만든다. 일시정지에서 복귀하면 `acc = 0`.
- 표시 보간은 M0에서 구현하지 않았다. 144Hz 화면에서 끊김이 거슬리면 이전 틱과 현재 틱의 위치를 `acc / FIXED_DT`로 보간한다. 보간은 표시에만 쓰고 시뮬레이션 상태를 바꾸지 않는다.

## 9. 적 이동과 공간 격자

- 격자: 1칸 크기의 버킷에 매 틱 살아 있는 적을 다시 넣는다. 적끼리 분리할 때는 주변 3×3 버킷만 조사한다. 적 전체를 서로 전수 비교하지 않는다(16.4).
- 이동: 플레이어 방향 단위벡터 × 속도 × dt. 접촉 거리 안이면 멈춘다. 그다음 겹친 이웃과 겹침의 절반씩 밀어낸다(틱당 1회, ID 순서). 플레이어 몸체 밖으로 밀어낸 뒤 전장 경계로 클램프한다(D-014).
- 공격 대상 검색: M0는 활성 인스턴스가 최대 1~2개라 적 목록 선형 탐색도 허용한다. 격자를 재사용해도 된다. 성능 문제는 측정한 뒤에만 최적화한다.

## 10. 표시

- 1칸 = `WorldRenderer.PPC` = 64px. 카메라 줌은 세로 15칸 기준(D-021).
- `WorldRenderer`는 벽, 플레이어 원, 적 원, 예고 중인 적(끊어진 링), 최근 공격 도형(표시 전용 기록 `attack_log`에서 9틱 동안, D-023)을 `_draw()`로 그린다. 적 300마리까지 개별 노드를 만들지 않는다.
- 색만으로 구분하지 않는다(15장). 정상 초식은 외곽선과 반투명 면, 기본 초식은 외곽선 없는 면, 적 예고는 끊어진 링으로 모양을 다르게 한다.
- F1 디버그 표시(`WorldRenderer.show_debug`와 `Hud` 우측 패널): 격자, 플레이어 반경과 접촉 거리, 창 사각 영역, 주 목표 조준선, 적 중심점, 틱, 틱당 시뮬레이션 ms, FPS, 버린 틱 수, 정상/기본 초식 수, 시드.

## 11. 테스트 실행

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Windows에서는 콘솔 출력과 종료 코드를 받기 위해 `godot` 대신 `godot_console`을 쓴다(2026-09-27 확인). 전역 `class_name` 등록 때문에 첫 실행 전에 프로젝트 가져오기(`--import` 또는 에디터 1회 실행)가 필요할 수 있다. M0-01에서 실제 명령을 확인해 README.md에 적는다. 위 명령은 확인 전 제안이다.
