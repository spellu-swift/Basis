@testable import Basis


@Suite struct BarrierTests {

	@Test	func sync() async throws {
		let value = Barrier<Int>(248)
		
		#expect(value.resource.value == 248)

		await Task {
			try? await Task.sleep(seconds: 1)

			value.atomic {
				$0 += 30
			}
		}.value
		
		#expect(value.resource.value == 278)
	}

	@Test	func sync_array() async throws {
		let value = Barrier<[Int]>([2, 4, 8])
		
		Task {
			try? await Task.sleep(seconds: 1)

			value.push(34)
		}

		await Task {
			#expect(value.pop() == 2)
			#expect(value.pop() == 4)
			#expect(value.pop() == 8)
			#expect(value.pop() == 34)
		}.value
	}

	@Test	func Sendableでない値を守る() async throws {
		let counter = Barrier(Counter())

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< 100 {
				group.addTask {
					counter.atomic {
						$0.count += 1
					}
				}
			}
		}

		let count: Int = counter.atomic { $0.count }

		#expect(count == 100)
	}

	@Test	func wait() async throws {
		let value = Barrier(0)

		#expect(value.resource.wait(seconds: 0.1) == .timedout)
	}

}


/// Sendableでない値
private final class Counter {
	var count: Int = 0
}
