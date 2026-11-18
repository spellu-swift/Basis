import BasisExperimental
import UnitTesting


@Default
@Orderable
private struct D {
	var tuple: Pair<Int, Int> = .init(1, 2)
}


@Suite struct PairTests {

	@Test func Orderableマクロで比較できる() {
		let v1: D = .default
		let v2: D = .default
		
		#expect((v1 <=> v2) == .equal)
	}

}
