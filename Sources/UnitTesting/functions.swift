

@inlinable
public func hereDirectory(
	file: String = #filePath
) -> Directory {
	File(at: file).parent
}


@inlinable
public func with<Value>(
	_ value: Value,
	block: @escaping (Value) -> Void
) {
	block(value)
}
