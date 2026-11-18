

@MainActor
extension MainActor {
	
	/// delay時間を経過したあとでoperationを実行する。
	///
	/// USECASE: UIフォーカス設定。
	public static func run(
		delay: TimeIntervalRepresentation? = nil,
		operation: @escaping @MainActor () -> Void,
	) {
		guard
			let delay
		else {
			operation()
			return
		}

		_ = Task { @MainActor in
			try await Task.sleep(delay)
			
			operation()
		}
	}
	
	/// delay時間を経過したあとでoperationを実行する。
	/// delayを経過せずに同じidで本メソッドを呼び出した場合、前のoperationはキャンセルされ新しいoperationのdelayが始まる。
	///
	/// USECASE: UI状態の保存。
	public static func run(
		id: String,
		delay: TimeIntervalRepresentation? = nil,
		operation: @escaping @MainActor () -> Void,
	) {
		if
			let task = tasks[id]
		{
			task.cancel()
		}
		
		guard
			let delay
		else {
			operation()
			return
		}
		
		let task: Task<Void, any Error>
		= Task { @MainActor in
			try await Task.sleep(delay)
			
			operation()
			
			tasks[id] = nil
		}
		
		tasks[id] = task
	}
	
	// MARK: Privates

	static var tasks: [String : Task<Void, any Error>] = [:]
	
}
