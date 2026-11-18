@testable import BigDecimal
import UnitTesting


/// 金額の計算での使い方。
@Suite struct BigDecimalで金額を計算する {

	private func yen(_ text: String) -> BigDecimal {
		BigDecimal(text)!
	}

	@Test func 二進の浮動小数点数で起きる税額のずれが起きない() {
		// $0.70 の 5% の税：2 進では 0.73499999… となり $0.73 になるが、正しくは $0.74
		let price: BigDecimal = yen("0.70")
		let rate: BigDecimal = yen("1.05")
		let total: BigDecimal = (price * rate).rounded(scale: 2, .toNearestOrAwayFromZero)

		#expect((price * rate).description == "0.7350")
		#expect(total.description == "0.74")
	}

	@Test func 通貨の桁に丸める() {
		let amount: BigDecimal = yen("1234.5")

		// 円は小数なし、ドルは 2 桁
		#expect(amount.rounded(scale: 0, .toNearestOrAwayFromZero).description == "1235")
		#expect(amount.rounded(scale: 0, .toNearestOrEven).description == "1234")
		#expect(amount.rounded(scale: 2, .toNearestOrEven).description == "1234.50")
	}

	@Test func 割り切れない除算は丸め方を指定しないとできない() {
		let total: BigDecimal = yen("100")
		let people: BigDecimal = 3

		#expect(total.dividedExactly(by: people) == nil)
		#expect(total.divided(by: people, scale: 0, rounding: .down).description == "33")
	}

	@Test func 割り勘の端数を最後の人に寄せる() {
		let total: BigDecimal = yen("100")
		let share: BigDecimal = total.divided(by: 3, scale: 0, rounding: .down)
		let last: BigDecimal = total - share * 2

		#expect([share, share, last].map(\.description) == ["33", "33", "34"])
		#expect(share + share + last == total)
	}

	@Test func 帳票の桁数を保つ() {
		let prices: [BigDecimal] = [yen("19.99"), yen("5.01"), yen("0.10")]
		let sum: BigDecimal = prices.reduce(0, +)

		#expect(sum.description == "25.10")
		#expect(sum == yen("25.1"))
		#expect(!sum.isIdentical(to: yen("25.1")))
	}

}
