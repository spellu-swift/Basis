import Basis


///
/// Snowflake-Like ID生成器
///
/// timestamp:  44 bits - 任意のEphoch時間からのミリ秒
/// instance:    9 bits - 生成器のID
/// sequence:   10 bits - シーケンス番号
///
/// Total: 63 bits
///
public final class IDGenerator {
	
	public init(
		epoch: Int64,
		instance: Int64 = 0,
		time: (() -> Int64)? = nil,
	) {
		precondition(epoch >= 0)
		precondition(instance >= 0 && instance < (1 << 10))
		
		self.epoch = epoch
		self.instance = instance
		self.sequence = 0
		self.time = time ?? {
			let time = POSIX.gettime()
			return Int64(time.tv_sec * 1000 + time.tv_nsec / 1_000_000)
		}
	}
		
	let epoch: Int64
	let instance: Int64
	var sequence: Int64
	let time: () -> Int64
	
	public var new: Int64 {
		let sequence: Int64 = self.sequence
		
		let id: Int64 = (time() - epoch) << (9 + 10) | instance << 10 | sequence
		
		self.sequence = (sequence + 1) % (1 << 10)
		
		return id
	}
	
}


extension IDGenerator {
	
	public static let EPOCH_2020: Int64 = 1_577_836_800_000

	public static let EPOCH_2025: Int64 = 1_735_689_600_000

	@inlinable
	public static func epoch2020(
		instance: Int64 = 0,
		time: (() -> Int64)? = nil,
	) -> Self {
		.init(
			epoch: EPOCH_2020,
			instance: instance,
			time: time,
		)
	}
	
	@inlinable
	public static func epoch2025(
		instance: Int64 = 0,
		time: (() -> Int64)? = nil,
	) -> Self {
		.init(
			epoch: EPOCH_2025,
			instance: instance,
			time: time,
		)
	}
	
}
