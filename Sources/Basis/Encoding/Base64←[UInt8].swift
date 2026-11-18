

extension Array where Element == UInt8 {


	public func encodeBase64(
		options: Base64.EncodingOptions = []
	) -> String {
		let dataLength = self.count
		if dataLength == 0 { return "" }
		
		let capacity = Base64.estimate(
			length: dataLength
		)
		
		let output = UnsafeMutableRawPointer.allocate(byteCount: capacity, alignment: 4)
		defer { output.deallocate() }
		
		let length: Int = self.withUnsafeBytes { (input: UnsafeRawBufferPointer) in
			let buffer = UnsafeMutableRawBufferPointer(start: output, count: capacity)
			
			return Base64.encode(
				input: input,
				output: buffer,
				options: options
			)
		}
		
		return String(
			decoding: UnsafeRawBufferPointer(start: output, count: length),
			as: Unicode.UTF8.self
		)
	}
	
	
	public func encodeBase64(
		options: Base64.EncodingOptions = []
	) -> [UInt8] {
		let dataLength = self.count
		if dataLength == 0 { return [] }
		
		return self.withUnsafeBytes { (input: UnsafeRawBufferPointer) in
			let capacity = Base64.estimate(
				length: dataLength
			)
			
			return [UInt8](capacity: capacity) { output in
				Base64.encode(
					input: input,
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
		options: Base64.DecodingOptions = []
	) throws -> String {
		let result: String? = try self
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
		
		if result != nil {
			return result!
		}
		else {
			// Slow path, unlikely that withContiguousStorageIfAvailable will fail but if it does, fall back to .utf8CString.
			// This will allocate and copy but it is the simplest way to get a contiguous buffer.
			let result: String = try self
				.withUnsafeBytes { (input: UnsafeRawBufferPointer) throws -> String in
					let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
					
					let output = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 4)
					defer { output.deallocate() }
					
					let length: Int = try Base64.decode(
						input: input,
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


	public func decodeBase64(
		options: Base64.DecodingOptions = []
	) throws -> [UInt8] {
		let result: [UInt8]? = try self
			.withContiguousStorageIfAvailable{ (input: UnsafeBufferPointer<UInt8>) -> [UInt8] in
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
			let result: [UInt8] = try self
				.withUnsafeBytes { (input: UnsafeRawBufferPointer) throws -> [UInt8] in
					let capacity = (input.count * 3) / 4    // Every 4 valid ASCII bytes maps to 3 output bytes.
					
					return try [UInt8](capacity: capacity) { output in
						try Base64.decode(
							input: input,
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
