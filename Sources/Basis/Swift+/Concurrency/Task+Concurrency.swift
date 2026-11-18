

extension Task where Success == Never, Failure == Never {

	/// 秒指定でタスクをsleepする。
	@inlinable
	public static func sleep(
		seconds: Double,
	) async throws {
		try await sleep(.seconds(seconds))
	}

	/// タスクをsleepする。
	@inlinable
	public static func sleep(
		_ time: TimeIntervalRepresentation,
	) async throws {
		try await sleep(nanoseconds: time.asNanoSeconds)
	}

}


extension Task where Failure == Swift.Error {
	
	/// 処理をバックグラウンドで実行する
	@discardableResult
	public static func background(
		priority: TaskPriority? = nil,
		perform: @escaping @Sendable () async throws -> Success
	) async throws -> Success {
		let result = await Task<Success, Swift.Error>.detached(
			priority: priority
		) {
			try await perform()
		}.result
		
		switch result {
			case .success(let value):
				return value
				
			case .failure(let error):
				throw error
		}
	}
	
}


extension Task where Success == Void, Failure == Never {

	@discardableResult
	public static func background<Result>(
		priority: TaskPriority? = nil,
		perform: @escaping @Sendable () async throws -> Result,
		failure: (@MainActor (any Error) -> Void)? = nil,
		canceled: (@MainActor () -> Void)? = nil,
	) -> Self {
		background(
			priority: priority,
			perform: perform,
			success: {_ in},
			failure: failure
		)
	}
	
	/// 処理をバックグラウンドで実行する。
	/// 処理が成功した場合: successをMainActorで実行する。
	/// 処理が失敗した場合: failureをMainActorで実行する。
	@discardableResult
	public static func background<Result>(
		priority: TaskPriority? = nil,
		perform: @escaping @Sendable () async throws -> Result,
		success: @escaping @MainActor (Result) throws -> Void,
		failure: (@MainActor (any Error) -> Void)? = nil,
		canceled: (@MainActor () -> Void)? = nil,
	) -> Self {
		Task.detached(
			priority: priority
		) {
			do {
				let result = try await perform()
				
				Task { @MainActor in
					do {
						try success(result)
					}
					catch {
						if let failure = failure {
							failure(error)
						}
						else {
							debugPrint(#function, "Uncaught Error", error)
						}
					}
				}
			}
			catch let error {
				if error is CancellationError {
					if let canceled = canceled {
						Task { @MainActor in
							canceled()
						}
					}
				}
				else {
					if let failure = failure {
						Task { @MainActor in
							failure(error)
						}
					}
					else {
						debugPrint(#function, "Uncaught Error", error)
					}
				}
			}
		}
	}

}
