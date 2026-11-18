

extension Sequence where Element : Sendable {
	

	public func asyncEach(
		task: @Sendable @escaping (Element) async -> Void
	) async -> Void {
		_ = await asyncMap(task: task)
	}
	

	public func asyncEach(
		task: @Sendable @escaping (Element) async throws -> Void
	) async rethrows -> Void {
		_ = try await asyncMap(task: task)
	}
	

	public func asyncMap<Result : Sendable>(
		task: @Sendable @escaping (Element) async -> Result
	) async -> [Result] {
		await withTaskGroup(of: (Int, Result).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					await (index, task(item))
				}
			}
			
			return await createArray(group: group)
		}
	}
	

	public func asyncMap<Result : Sendable>(
		task: @Sendable @escaping (Element) async throws -> Result
	) async rethrows -> [Result] {
		try await withThrowingTaskGroup(of: (Int, Result).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					try await (index, task(item))
				}
			}
			
			return try await createArray(group: group)
		}
	}
	
	
	public func asyncCompactMap<Result : Sendable>(
		task: @Sendable @escaping (Element) async -> Result?
	) async -> [Result] {
		await withTaskGroup(of: (Int, Result?).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					await (index, task(item))
				}
			}

			return await createArray(group: group).compacted()
		}
	}
	
	
	public func asyncCompactMap<Result : Sendable>(
		task: @Sendable @escaping (Element) async throws -> Result?
	) async rethrows -> [Result] {
		try await withThrowingTaskGroup(of: (Int, Result?).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					try await (index, task(item))
				}
			}
			
			return try await createArray(group: group).compacted()
		}
	}
	
	
	///
	/// 要素を列挙し、それぞれに指定された非構造化タスクを実行する。
	/// 最後に結果配列をリデューサーで変換し、結果を返す。
	///
	public func asyncReduce<Result : Sendable, GroupResult>(
		_ items: [Element],
		task: @Sendable @escaping (Element) async -> Result,
		reducer: @escaping ([Result]) async -> GroupResult
	) async -> GroupResult {
		await withTaskGroup(of: (Int, Result).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					await (index, task(item))
				}
			}
			
			return await reducer(createArray(group: group))
		}
	}
	
	
	public func asyncReduce<Result : Sendable, GroupResult>(
		_ items: [Element],
		task: @Sendable @escaping (Element) async throws -> Result,
		reducer: @escaping ([Result]) async -> GroupResult
	) async rethrows -> GroupResult {
		try await withThrowingTaskGroup(of: (Int, Result).self) { group in
			for (index, item) in self.enumerated() {
				group.addTask {
					try await (index, task(item))
				}
			}
			
			return try await reducer(createArray(group: group))
		}
	}
	
	
	func createArray<ChildTaskResult>(
		group: TaskGroup<(Int, ChildTaskResult)>
	) async -> [ChildTaskResult] {
		var bag: [Int: ChildTaskResult] = [:]
		
		for await (index, item) in group {
			bag[index] = item
		}
		
		return (0..<bag.count).map { index in
			bag[index]!
		}
	}

	
	func createArray<ChildTaskResult>(
		group: ThrowingTaskGroup<(Int, ChildTaskResult), Swift.Error>
	) async throws -> [ChildTaskResult] {
		var bag: [Int: ChildTaskResult] = [:]
		
		for try await (index, item) in group {
			bag[index] = item
		}
		
		return (0..<bag.count).map { index in
			bag[index]!
		}
	}
	
	
}


