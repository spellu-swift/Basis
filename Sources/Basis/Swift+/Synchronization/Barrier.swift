import Libc


/// 値を排他的に読み書きする。
///
/// 値を`sending`で受け渡すので、Sendableでない値も守れる。
/// 中の値には、ブロックの中でしか触れられない。
public final class Barrier<Value> : @unchecked Sendable {
	
	
	public init(
		_ value: sending Value
	) {
		self.resource = .init(value)
	}

	
	internal var resource: Resource

	
	public enum ReadAction<Result> {
		case ok(Result)
		case wait
	}
	
	
	public enum WriteAction {
		case notify
		case notifyAll
		case through
	}
	
	
	public func atomic<Result>(
		block: (inout sending Value) throws -> sending Result
	) rethrows -> sending Result {
		resource.lock()

		defer {
			resource.unlock()
		}

		return try block(&resource.value)
	}
	
	
	public func read<Result>(
		block: (inout sending Value) -> sending ReadAction<Result>
	) -> sending Result {
		resource.lock()
		
		defer {
			resource.unlock()
		}
		
		while true {
			let result: ReadAction = block(
				&resource.value
			)
			
			switch result {
				case .ok(let result):
					return result
					
				case .wait:
					_ = resource.wait()
			}
		}
	}
	
	
	public func read<Result>(
		limit seconds: Double,
		block: (inout sending Value) -> sending ReadAction<Result>
	) -> sending Result? {
		resource.lock()
		
		defer {
			resource.unlock()
		}
		
		while true {
			let result: ReadAction = block(
				&resource.value
			)
			
			switch result {
				case .ok(let result):
					return result
					
				case .wait:
					switch resource.wait(seconds: seconds) {
						case .notified:
							break
						case .timedout:
							return nil
					}
			}
		}
	}


	public func write(
		block: (inout sending Value) -> WriteAction
	) -> Void {
		resource.lock()
		
		defer {
			resource.unlock()
		}
		
		let result: WriteAction = block(
			&resource.value
		)
		
		switch result {
			case .notify:
				resource.notify()
				
			case .notifyAll:
				resource.notifyAll()
				
			case .through:
				break
		}
	}

	
}


extension Barrier {

	public struct Resource : @unchecked Sendable, ~Copyable {

		public var value: Value
		
		private let mutex: UnsafeMutablePointer<pthread_mutex_t>
		= UnsafeMutablePointer.allocate(capacity: 1)
		
		private let condition: UnsafeMutablePointer<pthread_cond_t>
		= UnsafeMutablePointer.allocate(capacity: 1)

		public init(
			_ value: Value
		) {
			self.value = value
			pthread_mutex_init(self.mutex, nil)
			pthread_cond_init(self.condition, nil)
		}
		
		deinit {
			pthread_cond_destroy(self.condition)
			self.condition.deallocate()
			
			pthread_mutex_destroy(self.mutex)
			self.mutex.deallocate()
		}

	}
	
}


extension Barrier.Resource {
	
	internal func lock(
	) {
		pthread_mutex_lock(self.mutex)
	}
	
	internal func unlock(
	) {
		pthread_mutex_unlock(self.mutex)
	}
	
	public func wait(
		seconds: Double? = nil
	) -> WaitResult {
		let result: Int32

		if
			let seconds
		{
			let limit = ClockTime
				.now
				.plus(
					nanos: Int(seconds * 1_000_000_000)
				)
			
			var timeoutAbs = timespec(
				tv_sec: limit.seconds,
				tv_nsec: limit.nano
			)

			result = pthread_cond_timedwait(self.condition, self.mutex, &timeoutAbs)
		}
		else {
			result = pthread_cond_wait(self.condition, self.mutex)
		}
		
		switch result {
			case 0:
				return .notified

			case ETIMEDOUT:
				return .timedout
			
			default:
				let error = POSIXError.system(errno)
				
				fatalError(error.readableMessage)
		}
	}
	
	public enum WaitResult {
		case notified
		case timedout
	}

	public func notify(
	) {
		pthread_cond_signal(self.condition)
	}
	
	public func notifyAll(
	) {
		pthread_cond_broadcast(self.condition)
	}
	
}


