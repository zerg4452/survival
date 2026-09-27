# 무협 서바이버 기획·개발 지시 패키지 v0.1

작성일: 2026-09-27

사용자 초안을 보강한 제안 문서 묶음이다. **실행 가능한 게임이나 검증 완료된 밸런스 데이터는 포함하지 않는다.**

## 개발 환경 (M0)

| 항목 | 값 |
|---|---|
| 엔진 | Godot `4.7.2.stable.official.ed1daf0bf` 표준 빌드(.NET 아님). 자동 업그레이드하지 않는다 |
| 설치 | winget `GodotEngine.GodotEngine` 4.7.2 (DECISIONS D-001) |
| 렌더러 | GL Compatibility |
| 언어 | GDScript, 타입 없는 선언은 오류(`untyped_declaration=2`) |

Windows에서는 콘솔 출력과 종료 코드를 받을 수 있도록 `godot_console`을 쓴다. 명령은 모두 프로젝트 폴더에서 실행한다.

처음 한 번(또는 `class_name`을 추가·변경한 뒤)에는 프로젝트를 가져온다.

```bash
godot_console --headless --path . --import
```

자동 테스트는 실패가 있으면 종료 코드 1을 낸다.

```bash
godot_console --headless --path . --script res://tests/run_tests.gd
```

특정 테스트만 실행할 때는 이름 일부를 넘긴다.

```bash
godot_console --headless --path . --script res://tests/run_tests.gd -- --filter=test_shapes
```

## M0 전투 실험실 실행

게임 창을 연다(에디터 없이 디버그 빌드로 실행).

```bash
godot --path .
```

에디터에서 열려면 `godot --path . --editor`를 실행한 뒤 F5를 누른다.

- 시작 화면: 마우스 또는 1~4 키로 주공을 고른다.
- 조작: 이동 WASD/방향키, 경공 Space, 일시정지 Esc(계속·재시작·메뉴로). 결과 화면에서 R은 재시작, Esc는 메뉴다.
- 디버그(디버그 빌드에서만 동작):

  | 키 | 기능 |
  |---|---|
  | F1 | 판정 표시와 정보 패널 |
  | F2 | 자동 스폰 켜기/끄기 |
  | F3 | 적 20마리 소환 |
  | F4 | 적 전멸 |
  | F5 | 내공 0 |
  | F6 | 이후 스폰되는 적의 체력 배율 ×1/×3/×10 |
  | F7 | 무적 |
  | F8 | 고정 대형 배치 |
  | F9 | 다음 판부터 고정 시드 12345 사용 |

  F9를 뺀 조작을 쓴 판은 HUD와 결과에 `DEBUG`가 표시된다.

- 폰트: 폰트 파일을 포함하지 않는다. `SystemFont`로 운영체제 폰트를 이름으로 지정한다(Windows는 맑은 고딕). 한글 폰트가 없는 환경에서는 글자가 보이지 않을 수 있다.

### 개발용 자동 실행 (DECISIONS D-023)

헤드리스 스모크: 메뉴를 건너뛰고 고정 시드로 지정 시간만큼 자동 진행한 뒤 종료한다.

```bash
godot_console --headless --path . --fixed-fps 60 -- --autoplay=pajin_spear --seconds=20
```

화면 캡처는 창이 잠깐 뜬다. 60, 150, 300틱과 결과 화면을 PNG로 저장한다.

```bash
godot_console --path . -- --autoplay=cheongun_sword --seconds=6 --capture=C:/temp/cap
```

주공 ID는 `cheongun_sword`, `swaeam_blade`, `pajin_spear`, `yeonhwan_fist`다. 자동 실행은 직접 플레이 검증을 대신하지 않는다.

### M0 알려진 제한

- 표시 보간이 없다. 60Hz 틱을 그대로 그리므로 고주사율 화면에서 움직임이 약간 끊겨 보일 수 있다.
- 적 300마리 밀집 시 헤드리스 시뮬레이션이 약 3.4ms/틱이다(개발 PC, 2026-09-27 측정). 정식 성능 측정(T24)은 M4 범위다.
- 사운드와 옵션 화면이 없다(M4 범위).

## 파일

- GAME_DESIGN.md: 원안 검토, 전투·무공·수련·도감·경지·전장·UI·구조·검증 기준.
- AI_WORK_ORDERS.md: Opus 설계 검토, Codex M0 구현, Opus 리뷰, Codex 수정용 복사 가능한 프롬프트와 마일스톤.
- AGENTS.md: 새 프로젝트에서 사용할 공통 개발 지침 예시.
- CLAUDE.md: 같은 기준 문서를 읽도록 연결하는 Claude Code 지침 예시.

## 권장 사용 순서

GAME_DESIGN.md의 핵심 가정을 읽고, AI_WORK_ORDERS.md의 Opus 설계 프롬프트를 먼저 전달한다. 이후 Codex에게 M0만 구현하도록 지시한다. 결과를 리뷰하고 해당 단계의 문제를 수정한 다음 M1로 진행한다. 전체 게임을 한 번에 구현하라고 지시하지 않는다.

기존 저장소가 있다면 AGENTS.md와 CLAUDE.md를 그대로 덮어쓰지 말고 필요한 부분만 병합한다. 엔진·플랫폼·숙련도 영구 보존 여부는 사용자 초안의 확정 사항이 아니며, 현재 문서의 제안 가정임을 유지한다.

ARCHITECTURE.md, TASKS.md, REVIEW.md, DECISIONS.md는 2026-09-27 설계 검토 단계에서 작성한 M0용 제안 문서다. 사용자가 승인한 결정은 DECISIONS.md에 "사용자 확인"으로 표시되어 있다.

## 특히 확인할 설계 결정

판마다 숙련도는 0으로 시작하되 최초 극성 달성 ID를 영구 도감에 저장한다. 그 고유 ID 수가 진원진기다. 따라서 4~5개 장착 슬롯으로도 여러 판에 걸쳐 10단계 경지를 목표로 할 수 있다. 프로토타입 무공은 10개이며 24개를 요구하는 최고 경지의 전체 콘텐츠는 후속 범위다.

수치는 초기 실험값이다. 문서의 수식·기준 간 정적 일관성 확인과, 실제 게임을 실행한 테스트는 서로 다르다. 이 패키지만으로 프레임 성능·무공 밸런스·재미가 검증된 것은 아니다.
