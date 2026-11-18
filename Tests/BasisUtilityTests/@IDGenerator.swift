@testable import BasisUtility


@Suite struct IDGeneratorTests {
	
	@Test func Epoch2020() throws {
		let epochTime: ZonedDateTime = .dateTime(2020, 1, 1, 0, 0, 0)
		let epochTimeSeconds = epochTime.epochSecond
		let epochTimeMills = epochTimeSeconds * 1000
		
		#expect(epochTimeSeconds ==    1577836800)
		#expect(epochTimeMills ==   1577836800000)
		
		#expect(epochTimeMills == IDGenerator.EPOCH_2020)
	}
	
	@Test func Epoch2025() throws {
		let epochTime: ZonedDateTime = .dateTime(2025, 1, 1, 0, 0, 0)
		let epochTimeSeconds = epochTime.epochSecond
		let epochTimeMills = epochTimeSeconds * 1000
		
		#expect(epochTimeSeconds ==     1735689600)
		#expect(epochTimeMills ==    1735689600000)
		
		#expect(epochTimeMills == IDGenerator.EPOCH_2025)
	}
	
	@Test func IDStructure() async throws {
		let generator = IDGenerator(epoch: IDGenerator.EPOCH_2020, instance: 1)
		
		let now: Int64 = generator.time() - generator.epoch
		
		try await Task.sleep(seconds: 0.1)
		
		let id_1: Int64 = generator.new
		let id_2: Int64 = generator.new
		let id_3: Int64 = generator.new
		
		#expect(((id_1 >> 19) & 17592186044415) >= now)
		#expect(((id_2 >> 19) & 17592186044415) >= now)
		#expect(((id_3 >> 19) & 17592186044415) >= now)
		
		#expect((id_1 >> 10) & 511 == 1)
		#expect((id_2 >> 10) & 511 == 1)
		#expect((id_3 >> 10) & 511 == 1)
		
		#expect((id_1 >> 0) & 1023 == 0)
		#expect((id_2 >> 0) & 1023 == 1)
		#expect((id_3 >> 0) & 1023 == 2)
	}
	
}

