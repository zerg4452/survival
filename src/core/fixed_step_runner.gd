class_name FixedStepRunner
extends RefCounted
## 렌더 프레임 간격을 60Hz 고정 틱으로 바꾸는 누산기(D-003).
## step_fn 은 틱마다 한 번 호출된다. 엔진 루프와 분리되어 있어 헤드리스 테스트가 가능하다.

## 누산기 비교 허용 오차. 1/60 을 여러 번 더하고 뺄 때 생기는 오차로 틱이 한 번 밀리지 않게 한다.
const ACC_TOLERANCE: float = 1e-9

var acc: float = 0.0
var dropped_ticks: int = 0


func advance(frame_delta: float, step_fn: Callable) -> int:
	acc += maxf(frame_delta, 0.0)
	var ticks: int = 0
	while acc + ACC_TOLERANCE >= SimConstants.FIXED_DT:
		if ticks >= SimConstants.MAX_TICKS_PER_FRAME:
			dropped_ticks += int((acc + ACC_TOLERANCE) / SimConstants.FIXED_DT)
			acc = 0.0
			break
		step_fn.call()
		acc -= SimConstants.FIXED_DT
		ticks += 1
	return ticks


## 일시정지 복귀 등에서 밀린 시간을 버린다.
func reset() -> void:
	acc = 0.0
