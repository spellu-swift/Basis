@testable import Basis
import Libc


@Suite struct BackboneTests {

//	@Test func isattyは端末かどうかを判定する() throws {
//		var descriptors: [Int32] = [0, 0]
//		try #require(pipe(&descriptors) == 0)
//		defer {
//			close(descriptors[0])
//			close(descriptors[1])
//		}
//
//		#expect(Backbone.isatty(descriptors[0]) == false)
//		#expect(Backbone.isatty(descriptors[1]) == false)
//		#expect(Backbone.isatty(STDIN_FILENO) == (Libc.isatty(STDIN_FILENO) == 1))
//		#expect(Backbone.isatty(STDOUT_FILENO) == (Libc.isatty(STDOUT_FILENO) == 1))
//		#expect(Backbone.isatty(STDERR_FILENO) == (Libc.isatty(STDERR_FILENO) == 1))
//	}

}
