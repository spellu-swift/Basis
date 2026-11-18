

extension String.SubSequence {
	

	/// Index with using position of Int type
	public func index(
		at position: Int
	) -> String.Index {
		return index(
			(position.signum() >= 0 ? startIndex : endIndex),
			offsetBy: position
		)
	}
	
	
	public func range(
		lowerBound: Int,
		upperBound: Int
	) -> Range<String.Index> {
		.init(uncheckedBounds: (
			self.index(at: lowerBound),
			self.index(at: upperBound)
		))
	}
	
	
	public func range(
		lowerIndex: String.Index,
		upperIndex: String.Index
	) -> Range<String.Index> {
		.init(uncheckedBounds: (lowerIndex, upperIndex))
	}
	
	
	public func split(
		string separator: String,
		maxSplits: Int = Int.max,
		omittingEmptySubsequences: Bool = true
	) -> [String.SubSequence] {
		var result: [String.SubSequence] = []
		
		var searchIndex: String.Index = self.startIndex
		
		for _ in 0..<maxSplits {
			let searchRange: Range<String.Index> = self.range(lowerIndex: searchIndex, upperIndex: self.endIndex)
			
			if let range: Range<String.Index> = self[searchRange].firstRange(of: separator) {
				// 見つかった Index == 0
				if range.lowerBound == searchIndex {
					// 空でも追加するなら
					if omittingEmptySubsequences == false {
						result.append(self[searchIndex..<searchIndex])
					}
				}
				else {
					// 見つかる直前を追加
					result.append(self[searchIndex..<range.lowerBound])
				}
				
				searchIndex = range.upperBound
			}
			else {
				break
			}
		}
		
		// 最後を追加
		result.append(self[searchIndex..<self.endIndex])
		
		return result
	}


}


extension String.SubSequence {


	@inlinable
	public var asString: String {
		String(self)
	}
	

}
