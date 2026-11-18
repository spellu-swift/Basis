

@freestanding(expression)
public macro print(
	_ items: Any? ...,
	nilString: String = "nil",
	separator: String = " ",
	terminator: String = "\n",
)
= #externalMacro(module: "BasisMacros", type: "PrintMacro")


@freestanding(expression)
public macro print<Value>(
	list values: any Sequence<Value>,
	prefix: String = "  ",
	line: (Value) -> String = { "\($0)" },
)
= #externalMacro(module: "BasisMacros", type: "PrintMacro")


//@freestanding(expression)
//public macro trace<Value>(
//	_ values: any Sequence<Value>,
//	prefix: String = "  ",
//	line: (Value) -> String = { "\($0)" },
//)
//= #externalMacro(module: "BasisMacros", type: "PrintMacro")


@freestanding(expression)
public macro trace(
	_ tree: any CustomTreeStringConvertible,
)
= #externalMacro(module: "BasisMacros", type: "TraceMacro")


public struct Debugging {
	
	public static func print(
		_ items: Any? ...,
		nilString: String = "nil",
		separator: String = " ",
		terminator: String = "\n",
	) {
		print(
			items: items,
			nilString: nilString,
			separator: separator,
			terminator: terminator,
		)
	}
	
	public static func print(
		items: [Any?],
		nilString: String = "nil",
		separator: String = " ",
		terminator: String = "\n",
	) {
		func itemToString(
			_ item: Any?
		) -> String {
			if let item {
				String(describing: item)
			} else {
				nilString
			}
		}
		
		guard items.count > 0
		else { return }
		
		var result: String = ""
		
		for item in items.dropLast() {
			result += itemToString(item)
			result += separator
		}
		
		result += itemToString(items.last!)
		
		Swift.print(result, terminator: terminator)
	}
	
	public static func print<Value>(
		list values: any Sequence<Value>,
		indent: String = "  ",
		line: (Value) -> String = { "\($0)" },
		__file: String = #file,
		__line: Int = #line,
	) {
		Swift.print("Source at \(__file)#\(__line)")

		for (index, value) in Array(values).enumerated() {
			Swift.print(indent, "#\(index): ", line(value), separator: "")
		}
	}

}
