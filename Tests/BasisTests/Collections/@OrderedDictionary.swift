@testable import Basis


@Suite struct OrderedDictionaryTests {
	
	@Test	func merge() {
		var dic: OrderedDictionary<String, String>
		= [:]
		
		dic.merge(["" : ""]) { l, r in l }
		dic.merge(["" : nil]) { l, r in l }
		
		_ = ["a":"b"].merging(dic) { l, r in l }
	}
	
	@Test	func merge2() {
		var _: OrderedDictionary<String, String>
		= .init(["a": nil])
	}
	
	@Test	func _1_1() {
		var dic: [String : String] = [:]
		
		dic["O"] = "hoge"
		
		#expect(dic.count == 1)
		
		dic["O"] = nil
		
		#expect(dic.count == 0)
	}
	
	
	@Test	func _1_2() {
		var dic: [String : String?] = [:]
		
		dic["O"] = "hoge"
		
		#expect(dic.count == 1)
		
		dic["O"] = nil
		
		#expect(dic.count == 0)
	}
	
	
	@Test	func _2_1() {
		var dic: OrderedDictionary<String, String> = [:]
		
		dic["O"] = "hoge"
		
		#expect(dic.count == 1)
		
		dic["O"] = nil
		
		#expect(dic.count == 0)
	}
	
	
	@Test	func _2_2() {
		var dic: OrderedDictionary<String, String?> = [:]
		
		dic["O"] = "hoge"
		
		#expect(dic.count == 1)
		
		dic["O"] = nil
		
		#expect(dic.count == 0)
	}
	
	
	@Test	func `as`() throws {
		let a: [Any] = []
		#expect(a as Any is [Any])
		#expect(a as Any is [Any?])
		#expect(a as Any is [Int])
		#expect(a as Any is [String])
		
		let d: Dictionary<String, Any> = [:]
		
		#expect(d as Any is Dictionary<String, Any>)
		#expect(d as Any is Dictionary<String, Any?>)
		#expect(d as Any is Dictionary<String, Int?>)
		#expect(d as Any is Dictionary<String, String?>)
		
		let v: OrderedDictionary<String, Any> = [:]
		
		#expect(v as Any is OrderedDictionary<String, Any>)
		#expect(v as Any is OrderedDictionary<String, Any?> == false)
		#expect(v as Any is OrderedDictionary<String, Int?> == false)
		#expect(v as Any is OrderedDictionary<String, String?> == false)
	}
	
	
	@Test	func test_Codable() {
		enum String_1 : String { case a }
		enum String_2 : String, CodingKeyRepresentable { case a }
		
		enum Int_1 : Int { case a }
		enum Int_2 : Int, CodingKeyRepresentable { case a = 0 }
		
		#expect(OrderedDictionary<String, String>() as Any is Codable)
		
		#expect(OrderedDictionary<String_1, String>() as Any is Codable == false)
		#expect(OrderedDictionary<String_2, String>() as Any is Codable)
		#expect(OrderedDictionary<Int_1, String>() as Any is Codable == false)
		#expect(OrderedDictionary<Int_2, String>() as Any is Codable)
		
		#expect(OrderedDictionary<Int8, String>() as Any is Codable)
		#expect(OrderedDictionary<Int16, String>() as Any is Codable)
		#expect(OrderedDictionary<Int32, String>() as Any is Codable)
		#expect(OrderedDictionary<Int64, String>() as Any is Codable)
		#expect(OrderedDictionary<Int, String>() as Any is Codable)
	}


}
