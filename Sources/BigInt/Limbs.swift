/// 絶対値（ワード列）の演算。
///
/// ワード列は下位のワードが先頭で、上位に 0 のワードを残さない（ゼロは空）。
/// 各関数は、引数がこの形であることを前提にし、結果もこの形で返す。
internal enum Limbs {

	internal static let wordBitWidth: Int = UInt.bitWidth


	/// 上位の 0 のワードを取り除く。
	internal static func normalize(
		_ x: inout [UInt],
	) {
		while x.last == 0 {
			x.removeLast()
		}
	}


	// MARK: 比較


	/// `a < b` なら -1、`a == b` なら 0、`a > b` なら 1。
	internal static func compare(
		_ a: [UInt],
		_ b: [UInt],
	) -> Int {
		if a.count != b.count {
			return a.count < b.count ? -1 : 1
		}

		for index in stride(from: a.count - 1, through: 0, by: -1) {
			if a[index] != b[index] {
				return a[index] < b[index] ? -1 : 1
			}
		}

		return 0
	}


	// MARK: ビット


	/// 絶対値のビット長。ゼロは 0。
	internal static func bitLength(
		_ x: [UInt],
	) -> Int {
		guard let top = x.last else { return 0 }
		return x.count * wordBitWidth - top.leadingZeroBitCount
	}

	/// 末尾の 0 のビットの数。ゼロは 0。
	internal static func trailingZeroBitCount(
		_ x: [UInt],
	) -> Int {
		for (index, word) in x.enumerated() where word != 0 {
			return index * wordBitWidth + word.trailingZeroBitCount
		}
		return 0
	}

	/// 2 の冪なら `true`。
	internal static func isPowerOfTwo(
		_ x: [UInt],
	) -> Bool {
		guard let top = x.last, top.nonzeroBitCount == 1 else { return false }
		return x.dropLast().allSatisfy { $0 == 0 }
	}

	/// `bits` ビット左にずらす。
	internal static func shiftLeft(
		_ x: [UInt],
		by bits: Int,
	) -> [UInt] {
		if x.isEmpty {
			return []
		}

		let wordShift: Int = bits / wordBitWidth
		let bitShift: Int = bits % wordBitWidth
		var result: [UInt] = .init(repeating: 0, count: wordShift)
		result.reserveCapacity(wordShift + x.count + 1)

		if bitShift == 0 {
			result.append(contentsOf: x)
			return result
		}

		var carry: UInt = 0

		for word in x {
			result.append((word << bitShift) | carry)
			carry = word >> (wordBitWidth - bitShift)
		}

		if carry != 0 {
			result.append(carry)
		}

		return result
	}

	/// `bits` ビット右にずらす（はみ出したビットは捨てる）。
	internal static func shiftRight(
		_ x: [UInt],
		by bits: Int,
	) -> [UInt] {
		let wordShift: Int = bits / wordBitWidth

		if wordShift >= x.count {
			return []
		}

		let bitShift: Int = bits % wordBitWidth
		var result: [UInt] = []
		result.reserveCapacity(x.count - wordShift)

		for index in wordShift ..< x.count {
			var word: UInt = x[index] >> bitShift

			if bitShift != 0 && index + 1 < x.count {
				word |= x[index + 1] << (wordBitWidth - bitShift)
			}

			result.append(word)
		}

		normalize(&result)
		return result
	}


	// MARK: 加減算


	internal static func add(
		_ a: [UInt],
		_ b: [UInt],
	) -> [UInt] {
		let (long, short): ([UInt], [UInt]) = a.count >= b.count
			? (a, b)
			: (b, a)
		var result: [UInt] = []
		result.reserveCapacity(long.count + 1)
		var carry: UInt = 0

		for index in 0 ..< long.count {
			let other: UInt = index < short.count ? short[index] : 0
			let (sum1, overflow1) = long[index].addingReportingOverflow(other)
			let (sum2, overflow2) = sum1.addingReportingOverflow(carry)
			result.append(sum2)
			carry = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
		}

		if carry != 0 {
			result.append(carry)
		}

		return result
	}

	/// `a - b`。`a >= b` であること。
	internal static func subtract(
		_ a: [UInt],
		_ b: [UInt],
	) -> [UInt] {
		var result: [UInt] = []
		result.reserveCapacity(a.count)
		var borrow: UInt = 0

		for index in 0 ..< a.count {
			let other: UInt = index < b.count ? b[index] : 0
			let (difference1, overflow1) = a[index]
				.subtractingReportingOverflow(other)
			let (difference2, overflow2) = difference1
				.subtractingReportingOverflow(borrow)
			result.append(difference2)
			borrow = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
		}

		precondition(borrow == 0, "Limbs.subtract: a < b")
		normalize(&result)
		return result
	}

	/// 1 を足す（その場で書き換える）。桁あふれは捨てる。
	internal static func increment(
		_ x: inout [UInt],
	) {
		for index in x.indices {
			let (sum, overflow) = x[index].addingReportingOverflow(1)
			x[index] = sum

			if !overflow {
				return
			}
		}
	}


	// MARK: 乗算


	/// 筆算による乗算。
	internal static func multiply(
		_ a: [UInt],
		_ b: [UInt],
	) -> [UInt] {
		if a.isEmpty || b.isEmpty {
			return []
		}

		var result: [UInt] = .init(repeating: 0, count: a.count + b.count)

		for i in 0 ..< a.count where a[i] != 0 {
			let multiplier: UInt = a[i]
			var carry: UInt = 0

			for j in 0 ..< b.count {
				// multiplier * b[j] + result[i + j] + carry は 128 ビットに収まる
				let (high, low) = multiplier.multipliedFullWidth(by: b[j])
				let (sum1, overflow1) = low.addingReportingOverflow(result[i + j])
				let (sum2, overflow2) = sum1.addingReportingOverflow(carry)
				result[i + j] = sum2
				carry = high &+ (overflow1 ? 1 : 0) &+ (overflow2 ? 1 : 0)
			}

			result[i + b.count] = carry
		}

		normalize(&result)
		return result
	}

	/// `x = x * multiplier + addend`（その場で書き換える）。
	internal static func multiplyAdd(
		_ x: inout [UInt],
		_ multiplier: UInt,
		_ addend: UInt,
	) {
		var carry: UInt = addend

		for index in x.indices {
			let (high, low) = x[index].multipliedFullWidth(by: multiplier)
			let (sum, overflow) = low.addingReportingOverflow(carry)
			x[index] = sum
			carry = high &+ (overflow ? 1 : 0)
		}

		if carry != 0 {
			x.append(carry)
		}

		normalize(&x)
	}


	// MARK: 除算


	/// 1 ワードで割る。`divisor` は 0 でないこと。
	internal static func divide(
		_ x: [UInt],
		by divisor: UInt,
	) -> (quotient: [UInt], remainder: UInt) {
		precondition(divisor != 0, "Division by zero")
		var quotient: [UInt] = .init(repeating: 0, count: x.count)
		var remainder: UInt = 0

		for index in stride(from: x.count - 1, through: 0, by: -1) {
			(quotient[index], remainder) = divisor.dividingFullWidth(
				(high: remainder, low: x[index])
			)
		}

		normalize(&quotient)
		return (quotient, remainder)
	}

	/// Knuth のアルゴリズム D（TAOCP 4.3.1）による除算。
	/// `divisor` は空でないこと。
	internal static func divide(
		_ x: [UInt],
		by divisor: [UInt],
	) -> (quotient: [UInt], remainder: [UInt]) {
		precondition(!divisor.isEmpty, "Division by zero")

		if compare(x, divisor) < 0 {
			return ([], x)
		}

		if divisor.count == 1 {
			let (quotient, remainder) = divide(x, by: divisor[0])
			return (quotient, remainder == 0 ? [] : [remainder])
		}

		// 除数の最上位ワードの最上位ビットが立つように、両方を左にずらす
		let shift: Int = divisor[divisor.count - 1].leadingZeroBitCount
		let v: [UInt] = shiftLeft(divisor, by: shift)
		var u: [UInt] = shiftLeft(x, by: shift)

		while u.count < x.count + 1 {
			u.append(0)
		}

		let n: Int = v.count
		let m: Int = x.count - n
		let vTop: UInt = v[n - 1]
		let vNext: UInt = v[n - 2]
		var quotient: [UInt] = .init(repeating: 0, count: m + 1)

		for j in stride(from: m, through: 0, by: -1) {
			// 商の 1 ワードを上位 2 ワード ÷ 除数の最上位ワードで見積もる
			var estimate: UInt
			var rest: UInt
			var restOverflow: Bool

			if u[j + n] >= vTop {
				estimate = .max
				(rest, restOverflow) = u[j + n - 1].addingReportingOverflow(vTop)
			}
			else {
				(estimate, rest) = vTop.dividingFullWidth(
					(high: u[j + n], low: u[j + n - 1])
				)
				restOverflow = false
			}

			// 見積もりが大きすぎるときは減らす（多くとも 2 回）
			while !restOverflow {
				let (high, low) = estimate.multipliedFullWidth(by: vNext)

				if high > rest || (high == rest && low > u[j + n - 2]) {
					estimate -= 1
					(rest, restOverflow) = rest.addingReportingOverflow(vTop)
				}
				else {
					break
				}
			}

			// u[j ... j + n] から estimate * v を引く
			var carry: UInt = 0
			var borrow: UInt = 0

			for i in 0 ..< n {
				let (high, low) = estimate.multipliedFullWidth(by: v[i])
				let (product, overflow) = low.addingReportingOverflow(carry)
				carry = high &+ (overflow ? 1 : 0)
				let (difference1, overflow1) = u[i + j]
					.subtractingReportingOverflow(product)
				let (difference2, overflow2) = difference1
					.subtractingReportingOverflow(borrow)
				u[i + j] = difference2
				borrow = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
			}

			let (top1, topOverflow1) = u[j + n].subtractingReportingOverflow(carry)
			let (top2, topOverflow2) = top1.subtractingReportingOverflow(borrow)
			u[j + n] = top2

			// 引きすぎて負になったら、1 回分を足し戻す
			if topOverflow1 || topOverflow2 {
				estimate -= 1
				var addCarry: UInt = 0

				for i in 0 ..< n {
					let (sum1, overflow1) = u[i + j].addingReportingOverflow(v[i])
					let (sum2, overflow2) = sum1.addingReportingOverflow(addCarry)
					u[i + j] = sum2
					addCarry = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
				}

				u[j + n] = u[j + n] &+ addCarry
			}

			quotient[j] = estimate
		}

		normalize(&quotient)
		var remainder: [UInt] = Array(u[0 ..< n])
		normalize(&remainder)
		return (quotient, shiftRight(remainder, by: shift))
	}

}
