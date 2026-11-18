

extension Array where Element == UInt8 {
	
	
	@inlinable
	public var reader: BinaryReader {
		self[...].reader
	}
	
	
	@inlinable
	public func dump(
		separator: String = " "
	) -> String {
		self[...].dump(separator: separator)
	}
	
	
}


extension ArraySlice where Element == UInt8 {
	
	
	@inlinable
	public var reader: BinaryReader {
		BinaryReader(self)
	}
	
	
	@inlinable
	public func dump(
		separator: String = " "
	) -> String {
		let strings: [String] = self.map{ POSIX.format("%02X", $0) }
		
		return strings.joined(separator: separator)
	}
	
	
}


extension Binary {
	
	
	@inlinable
	public func dump(
		separator: String = " "
	) -> String {
		let strings: [String] = self.map{ POSIX.format("%02X", $0) }
		
		return strings.joined(separator: separator)
	}
	
	
}


