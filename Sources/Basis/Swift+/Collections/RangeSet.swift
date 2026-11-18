///
/// 範囲の集合。標準ライブラリの`RangeSet`（macOS 15・iOS 18以降）の下位互換。
///
/// 重ならず、隣り合わない半開区間を、昇順に並べて保持する。
/// 同じ名前なので、`import Basis`したモジュールでは標準ライブラリの`RangeSet`より優先される。
///
public struct RangeSet<Bound : Comparable> {

	@usableFromInline
	internal var _ranges: [Range<Bound>]

	@inlinable
	public init(
	) {
		_ranges = []
	}

	@inlinable
	public init(
		_ range: Range<Bound>,
	) {
		_ranges = range.isEmpty ? [] : [range]
	}

	public init<S : Sequence>(
		_ ranges: S,
	) where S.Element == Range<Bound> {
		_ranges = Self.normalized(Array(ranges))
	}

	/// 範囲の一覧。昇順で、重ならず隣り合わない。
	@inlinable
	public var ranges: Ranges {
		Ranges(_ranges)
	}

	@inlinable
	public var isEmpty: Bool {
		_ranges.isEmpty
	}

	/// 値が含まれているか。
	public func contains(
		_ value: Bound,
	) -> Bool {
		var lower: Int = 0
		var upper: Int = _ranges.count

		while lower < upper {
			let middle: Int = (lower + upper) / 2
			let range: Range<Bound> = _ranges[middle]

			if value < range.lowerBound {
				upper = middle
			}
			else if value >= range.upperBound {
				lower = middle + 1
			}
			else {
				return true
			}
		}

		return false
	}

}


// MARK: - Ranges


extension RangeSet {

	/// 範囲の一覧。
	public struct Ranges : RandomAccessCollection {

		@usableFromInline
		internal let _ranges: [Range<Bound>]

		@inlinable
		internal init(
			_ ranges: [Range<Bound>],
		) {
			_ranges = ranges
		}

		@inlinable
		public var startIndex: Int {
			_ranges.startIndex
		}

		@inlinable
		public var endIndex: Int {
			_ranges.endIndex
		}

		@inlinable
		public subscript(
			position: Int,
		) -> Range<Bound> {
			_ranges[position]
		}

	}

}


// MARK: - 範囲の追加と削除


extension RangeSet {

	public mutating func insert(
		contentsOf range: Range<Bound>,
	) {
		formUnion(RangeSet(range))
	}

	public mutating func remove(
		contentsOf range: Range<Bound>,
	) {
		subtract(RangeSet(range))
	}

}


// MARK: - 集合演算


extension RangeSet {

	public func union(
		_ other: Self,
	) -> Self {
		var result: Self = .init()
		result._ranges = Self.normalized(_ranges + other._ranges)
		return result
	}

	public mutating func formUnion(
		_ other: Self,
	) {
		self = union(other)
	}

	public func intersection(
		_ other: Self,
	) -> Self {
		var result: [Range<Bound>] = []
		var i: Int = 0
		var j: Int = 0

		while i < _ranges.count && j < other._ranges.count {
			let a: Range<Bound> = _ranges[i]
			let b: Range<Bound> = other._ranges[j]
			let lower: Bound = Swift.max(a.lowerBound, b.lowerBound)
			let upper: Bound = Swift.min(a.upperBound, b.upperBound)

			if lower < upper {
				result.append(lower ..< upper)
			}

			if a.upperBound < b.upperBound {
				i += 1
			}
			else {
				j += 1
			}
		}

		var set: Self = .init()
		set._ranges = result
		return set
	}

	public mutating func formIntersection(
		_ other: Self,
	) {
		self = intersection(other)
	}

	public func subtracting(
		_ other: Self,
	) -> Self {
		var result: [Range<Bound>] = []
		var j: Int = 0

		for range in _ranges {
			var lower: Bound = range.lowerBound

			// rangeより前で終わる範囲を飛ばす
			while j < other._ranges.count && other._ranges[j].upperBound <= lower {
				j += 1
			}

			var k: Int = j

			while k < other._ranges.count && other._ranges[k].lowerBound < range.upperBound {
				let cut: Range<Bound> = other._ranges[k]

				if lower < cut.lowerBound {
					result.append(lower ..< cut.lowerBound)
				}

				lower = Swift.max(lower, cut.upperBound)
				k += 1
			}

			if lower < range.upperBound {
				result.append(lower ..< range.upperBound)
			}
		}

		var set: Self = .init()
		set._ranges = result
		return set
	}

	public mutating func subtract(
		_ other: Self,
	) {
		self = subtracting(other)
	}

	public func symmetricDifference(
		_ other: Self,
	) -> Self {
		union(other).subtracting(intersection(other))
	}

	public mutating func formSymmetricDifference(
		_ other: Self,
	) {
		self = symmetricDifference(other)
	}

	/// 昇順に並べ、空の範囲を除き、重なる・隣り合う範囲をまとめる。
	internal static func normalized(
		_ ranges: [Range<Bound>],
	) -> [Range<Bound>] {
		let sorted: [Range<Bound>] = ranges
			.filter { !$0.isEmpty }
			.sorted { $0.lowerBound < $1.lowerBound }

		var result: [Range<Bound>] = []

		for range in sorted {
			if let last = result.last, range.lowerBound <= last.upperBound {
				result[result.count - 1] = last.lowerBound ..< Swift.max(last.upperBound, range.upperBound)
			}
			else {
				result.append(range)
			}
		}

		return result
	}

}


// MARK: - プロトコル


extension RangeSet : Equatable {}

extension RangeSet : Hashable where Bound : Hashable {}

extension RangeSet : Sendable where Bound : Sendable {}

extension RangeSet.Ranges : Equatable {}

extension RangeSet.Ranges : Hashable where Bound : Hashable {}

extension RangeSet.Ranges : Sendable where Bound : Sendable {}


extension RangeSet : CustomStringConvertible {

	public var description: String {
		"[" + _ranges.map { "\($0)" }.joined(separator: ", ") + "]"
	}

}
