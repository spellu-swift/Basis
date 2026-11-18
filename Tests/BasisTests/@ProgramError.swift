@testable import Basis


@Suite struct ProgramErrorTests {
	
	struct MyError : Error, CustomStringConvertible {
		var description: String {
			"エラーが発生しました"
		}
	}
	@Test func ThirdPartyError() {
		#expect(MyError().readableMessage == "Error My: エラーが発生しました")
	}
		
	enum FooError : ProgramError {
		case e0
		case e1(String)
		case e2(String, count: Int)
		case e3(String, String, String)
	}
	
	struct StructError : ProgramError {
		var message: String
	}
	
	@Test func enum情報1() {
		let error = FooError.e0
		
		#expect(error.category == "Foo")
		#expect(error.reason == "e0")
		#expect(error.readableMessage == "Error Foo: e0")
		#expect("\(error)" == "e0")
		#expect(String(describing: error) == #"e0"#)
		#expect(String(reflecting: error) == #"BasisTests.ProgramErrorTests.FooError.e0"#)
	}
	
	@Test func enum情報2() {
		let error = FooError.e1("zot")
//		let error = FooError.ohno("b", "zot", "c")

		#expect(error.category == "Foo")
		#expect(error.reason == "e1")
		#expect(error.readableMessage == "Error Foo: e1: zot")
		#expect("\(error)" == #"e1("zot")"#)
		#expect(String(describing: error) == #"e1("zot")"#)
		#expect(String(reflecting: error) == #"BasisTests.ProgramErrorTests.FooError.e1("zot")"#)
	}
	
	@Test func enum情報3() {
		let error = FooError.e2("zotted", count: 3)
		
		#expect(error.category == "Foo")
		#expect(error.reason == "e2")
		#expect(error.readableMessage == "Error Foo: e2: zotted count=3")
		#expect("\(error)" == #"e2("zotted", count: 3)"#)
		#expect(String(describing: error) == #"e2("zotted", count: 3)"#)
		#expect(String(reflecting: error) == #"BasisTests.ProgramErrorTests.FooError.e2("zotted", count: 3)"#)
	}
	
	@Test func struct情報1() {
		let error = StructError(message: "hoge")
		
		#expect(error.category == "Struct")
		#expect(error.reason == nil)
		#expect(error.readableMessage == "Error Struct: hoge")
		#expect("\(error)" == #"StructError(message: "hoge")"#)
		#expect(String(describing: error) == #"StructError(message: "hoge")"#)
		#expect(String(reflecting: error) == #"BasisTests.ProgramErrorTests.StructError(message: "hoge")"#)
	}
	
}
