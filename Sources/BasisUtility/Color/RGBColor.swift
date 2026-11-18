import Basis
import Libc


public struct RGBColor : Sendable {
	
	public init(
		_ red: Int,
		_ green: Int,
		_ blue: Int,
	) {
		self.red = red
		self.green = green
		self.blue = blue
	}
	
	public static func hex(
		_ value: Int,
	) -> RGBColor {
		RGBColor(
			(value & 0xFF0000) >> 16,
			(value & 0x00FF00) >> 8,
			value & 0x0000FF
		)
	}
	
	public var red: Int
	public var green: Int
	public var blue: Int

	public var hexString: String {
		POSIX.format("#%02X%02X%02X", red, green, blue)
	}
	
}


extension RGBColor {
	
	///
	/// RGBカラー値をHSVカラー値に変換する。
	/// See: https://yanohirota.com/color-converter/
	///
	public var asHSV: HSVColor {
		let r: Double = Double(red) / 255
		let g: Double = Double(green) / 255
		let b: Double = Double(blue) / 255

		var max: Double = r > g ? r : g
		max = max > b ? max : b

		var min: Double = r < g ? r : g
		min = min < b ? min : b

		var h: Double = max - min

		if h > 0.0 {
			if max == r {
				h = (g - b) / h
				if h < 0.0 {
					h += 6.0
				}
			} else if max == g {
				h = 2.0 + (b - r) / h
			} else {
				h = 4.0 + (r - g) / h
			}
		}

		if max == 0.0 {
			return HSVColor(
				h / 6.0,
				0,
				0
			)
		} else {
			return HSVColor(
				Int(round(h / 6.0 * 360)),
				round((max - min) / max * 1000) / 10,
				round(max * 1000) / 10
			)
		}
	}
	
}


extension RGBColor : Equatable {
	
}
