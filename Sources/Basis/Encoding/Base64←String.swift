

extension String {
	
	
	@inlinable
	public var base64Binary: Binary {
		encodeBase64(options: [], as: Binary.self)
	}
	
	
	@inlinable
	public var base64String: String {
		encodeBase64(options: [], as: String.self)
	}
	
	
	public func encodeBase64(
		options: Base64.EncodingOptions = [],
		as: String.Type = String.self
	) -> String {
		let result: String? = self
			.utf8
			.withContiguousStorageIfAvailable{ (input: UnsafeBufferPointer<String.UTF8View.Element>) -> String in
				let capacity = Base64.estimate(
					length: input.count
				)
				
				let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
				defer { output.deallocate() }
				
				let length: Int = Base64.encode(
					input: UnsafeRawBufferPointer(
						start: input.baseAddress,
						count: input.count
					),
					output: output,
					options: options
				)
				
				return String(
					decoding: UnsafeMutableRawBufferPointer(
						start: output.baseAddress,
						count: length
					),
					as: Unicode.UTF8.self
				)
			}
		
		
		if result != nil {
			return result!
		}
		
		// Slow path, unlikely that withContiguousStorageIfAvailable will fail but if it does, fall back to .utf8CString.
		// This will allocate and copy but it is the simplest way to get a contiguous buffer.
		return self
			.utf8CString
			.withUnsafeBufferPointer { (input: UnsafeBufferPointer<CChar>) -> String in
				let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
				
				let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
				defer { output.deallocate() }
				
				let length: Int = Base64.encode(
					input: UnsafeRawBufferPointer(
						start: input.baseAddress,
						count: input.count
					),
					output: output,
					options: options
				)
				
				return String(
					decoding: UnsafeMutableRawBufferPointer(
						start: output.baseAddress,
						count: length
					),
					as: Unicode.UTF8.self
				)
			}
	}
	

	@inlinable
	public func encodeBase64(
		options: Base64.EncodingOptions = [],
		as: Binary.Type = Binary.self
	) -> Binary {
		Binary(encodeBase64(options: options))
	}
	
	
	@usableFromInline
	func encodeBase64(
		options: Base64.EncodingOptions = []
	) -> [UInt8] {
		let result: [UInt8]? = self
			.utf8
			.withContiguousStorageIfAvailable{ (input: UnsafeBufferPointer<UInt8>) -> [UInt8] in
				let capacity = Base64.estimate(
					length: input.count
				)
				
				let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
				defer { output.deallocate() }
				
				return [UInt8](capacity: capacity) { output in
					Base64.encode(
						input: UnsafeRawBufferPointer(
							start: input.baseAddress,
							count: input.count
						),
						output: UnsafeMutableRawBufferPointer(
							start: output.baseAddress,
							count: output.count
						),
						options: options
					)
				}
			}
		
		
		if result != nil {
			return result!
		}
		
		// Slow path, unlikely that withContiguousStorageIfAvailable will fail but if it does, fall back to .utf8CString.
		// This will allocate and copy but it is the simplest way to get a contiguous buffer.
		return self
			.utf8CString
			.withUnsafeBufferPointer { (input: UnsafeBufferPointer<CChar>) -> [UInt8] in
				let capacity = Base64.estimate(
					length: input.count
				)
				
				let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
				defer { output.deallocate() }
				
				return [UInt8](capacity: capacity) { output in
					Base64.encode(
						input: UnsafeRawBufferPointer(
							start: input.baseAddress,
							count: input.count
						),
						output: UnsafeMutableRawBufferPointer(
							start: output.baseAddress,
							count: output.count
						),
						options: options
					)
				}
			}
	}
	
	
	public func decodeBase64(
		options: Base64.DecodingOptions = [],
		as: String.Type = String.self
	) throws -> String {
		let result: String? = try self
			.utf8
			.withContiguousStorageIfAvailable{ (input: UnsafeBufferPointer<String.UTF8View.Element>) throws -> String in
				let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
				
				let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
				defer { output.deallocate() }
				
				let length: Int = try Base64.decode(
					input: UnsafeRawBufferPointer(
						start: input.baseAddress,
						count: input.count
					),
					output: output,
					options: options
				)
				
				return String(
					decoding: UnsafeMutableRawBufferPointer(
						start: output.baseAddress,
						count: length
					),
					as: Unicode.UTF8.self
				)
			}
		
		if let result {
			return result
		}
		else {
			// Slow path, unlikely that withContiguousStorageIfAvailable will fail but if it does, fall back to .utf8CString.
			// This will allocate and copy but it is the simplest way to get a contiguous buffer.
			let result: String = try self
				.utf8CString
				.withUnsafeBufferPointer { (input: UnsafeBufferPointer<CChar>) throws -> String in
					let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
					
					let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
					defer { output.deallocate() }
					
					let length: Int = try Base64.decode(
						input: UnsafeRawBufferPointer(
							start: input.baseAddress,
							count: input.count - 1    // -1 to ignore the terminating NUL,
						),
						output: output,
						options: options
					)
					
					return String(
						decoding: UnsafeMutableRawBufferPointer(
							start: output.baseAddress,
							count: length
						),
						as: Unicode.UTF8.self
					)
				}
			
			return result
		}
	}
	
	
	@inlinable
	public func decodeBase64(
		options: Base64.DecodingOptions = [],
		as: Binary.Type = Binary.self
	) throws -> Binary {
		try Binary(decodeBase64(options: options))
	}
	
	
	@usableFromInline
	func decodeBase64(
		options: Base64.DecodingOptions = []
	) throws -> [UInt8] {
		let result: [UInt8]? = try self
			.utf8
			.withContiguousStorageIfAvailable{ (input: UnsafeBufferPointer<String.UTF8View.Element>) -> [UInt8] in
				let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
				
				return try [UInt8](capacity: capacity) { output in
					try Base64.decode(
						input: UnsafeRawBufferPointer(
							start: input.baseAddress,
							count: input.count
						),
						output: UnsafeMutableRawBufferPointer(
							start: output.baseAddress,
							count: output.count
						),
						options: options
					)
				}
			}
		
		if result != nil {
			return result!
		}
		else {
			// Slow path, unlikely that withContiguousStorageIfAvailable will fail but if it does, fall back to .utf8CString.
			// This will allocate and copy but it is the simplest way to get a contiguous buffer.
			let result: [UInt8] = try self
				.utf8CString
				.withUnsafeBufferPointer { (input: UnsafeBufferPointer<CChar>) throws -> [UInt8] in
					let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
					
					return try [UInt8](capacity: capacity) { output in
						try Base64.decode(
							input: UnsafeRawBufferPointer(
								start: input.baseAddress,
								count: input.count - 1    // -1 to ignore the terminating NUL,
							),
							output: UnsafeMutableRawBufferPointer(
								start: output.baseAddress,
								count: output.count
							),
							options: options
						)
					}
				}
			
			return result
		}
	}
	
	
}
