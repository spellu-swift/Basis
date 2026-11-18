import Basis


private struct A : Orderable {
	var foo: String
	var bar: Int?
	static func <=>(
		_ lhs: Self,
		_ rhs: Self
	) -> Ordering {
		Basis
			.compare(lhs, rhs, \.foo)
			.else { compare(lhs, rhs, \.bar) }
	}
}


@Orderable
private struct B {
	var foo: String
	var c: Int?
}


@Orderable
private struct C {
	var foo: [String]
	var bar: [Int]?
}


private struct Tests {
	@Test func Ordering_String() async throws {
		#expect(("t" <=> "yy") == .less)
		#expect(compare("t", "yy") == .less)
	}
	
	
	@Test func Orderable_struct_A() async throws {
		let v1: A = .init(foo: "b")
		let v2: A = .init(foo: "ac")
		
		#expect((v1 <=> v2) == .greater)
		#expect(compare(v1, v2) == .greater)
	}
	
	
	@Test func Orderable_struct_B() async throws {
		let v1: B = .init(foo: "b")
		let v2: B = .init(foo: "ac")
		
		#expect((v1 > v2) == true)
		#expect((v1 <=> v2) == .greater)
		#expect(compare(v1, v2) == .greater)
	}
	
	
	@Test func Orderable_struct_C() {
		let v1: C = .init(foo: ["b"])
		let v2: C = .init(foo: ["ac"])

		#expect((v1 <=> v2) == .greater)
		#expect(compare(v1, v2) == .greater)
	}
}

