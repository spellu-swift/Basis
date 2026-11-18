import Basis
import Libc


public struct HSVColor : Sendable {
	
	
	/// A context-dependent red color suitable for use in UI elements.
	/// #FF3B30
	public static let red: HSVColor = .hsv(3, 81, 100)
	/// #FF463A
	public static let redDark: HSVColor = .hsv(4, 77.3, 100)

	/// A context-dependent orange color suitable for use in UI elements.
	/// #FF9900
	public static let orange: HSVColor = .hsv(36, 100, 100)
	/// #FF9F3A
	public static let orangeDark: HSVColor = .hsv(31, 77.3, 100)

	/// A context-dependent yellow color suitable for use in UI elements.
	/// #FFCC00
	public static let yellow: HSVColor = .hsv(48, 100, 100)
	/// #FFD60A
	public static let yellowDark: HSVColor = .hsv(50, 96.1, 100)

	/// A context-dependent green color suitable for use in UI elements.
	/// #27CD41
	public static let green: HSVColor = .hsv(128, 81.0, 80.4)
	/// #32D74B
	public static let greenDark: HSVColor = .hsv(129, 76.7, 83.4)

	/// A context-dependent mint color suitable for use in UI elements.
	/// #01C7BE
	public static let mint: HSVColor = .hsv(177, 99.5, 78.0)
	/// #62E6E2
	public static let mintDark: HSVColor = .hsv(178, 57.4, 90.2)

	/// A context-dependent teal color suitable for use in UI elements.
	/// #59ADC4
	public static let teal: HSVColor = .hsv(193, 54.6, 76.9)
	/// #69C4DC
	public static let tealDark: HSVColor = .hsv(193, 52.3, 86.3)

	/// A context-dependent cyan color suitable for use in UI elements.
	/// #56BEF0
	public static let cyan: HSVColor = .hsv(199, 64.2, 94.1)
	/// #5AC8F5
	public static let cyanDark: HSVColor = .hsv(197, 63.3, 96.1)

	/// A context-dependent blue color suitable for use in UI elements.
	/// #007AFF
	public static let blue: HSVColor = .hsv(211, 100, 100)
	/// #0C84FF
	public static let blueDark: HSVColor = .hsv(210, 95.3, 100)

	/// A context-dependent indigo color suitable for use in UI elements.
	/// #5856D7
	public static let indigo: HSVColor = .hsv(241, 60.0, 84.3)
	/// #5E5CE6
	public static let indigoDark: HSVColor = .hsv(241, 60.0, 90.2)

	/// A context-dependent purple color suitable for use in UI elements.
	/// #AF52DE
	public static let purple: HSVColor = .hsv(280, 63.1, 87.1)
	/// #BF5AF2
	public static let purpleDark: HSVColor = .hsv(280, 62.8, 94.9)

	/// A context-dependent pink color suitable for use in UI elements.
	/// #FF2E55
	public static let pink: HSVColor = .hsv(349, 82.0, 100)
	/// #FF375F
	public static let pinkDark: HSVColor = .hsv(348, 74.8, 100)

	/// A context-dependent brown color suitable for use in UI elements.
	/// #A2845E
	public static let brown: HSVColor = .hsv(34, 42.0, 63.5)
	/// #AC8E68
	public static let brownDark: HSVColor = .hsv(34, 39.5, 67.5)

	/// A white color suitable for use in UI elements.
	/// #
	public static let white: HSVColor = .hsv(0, 0, 100)
	/// #FFFFFF
	public static let whiteDark: HSVColor = .hsv(0, 0, 100)

	/// A context-dependent gray color suitable for use in UI elements.
	/// #8E8E93
	public static let gray: HSVColor = .hsv(240, 3.4, 57.6)
	/// #98989D
	public static let grayDark: HSVColor = .hsv(240, 3.2, 61.6)

	/// A black color suitable for use in UI elements.
	/// #000000
	public static let black: HSVColor = .hsv(0, 0, 0)
	/// #000000
	public static let blackDark: HSVColor = .hsv(0, 0, 0)


	
	/// #252424
	public static let primary: HSVColor = .hsv(0, 2.7, 14.5)
	/// #DFDEDE
	public static let primaryDark: HSVColor = .hsv(0, 0.4, 87.5)

	/// #7C7876
	public static let secondary: HSVColor = .hsv(20, 4.8, 48.6)
	/// #A39E9E
	public static let secondaryDark: HSVColor = .hsv(0, 3.1, 63.9)

	/// #DCDCDC
	public static let selection: HSVColor = .hsv(0, 0, 86.3)
	/// #464646
	public static let selectionDark: HSVColor = .hsv(0, 0, 27.5)
	
	/// #DDD7D4
	public static let separator: HSVColor = .hsv(20, 4.1, 86.7)
	/// #453D3C
	public static let separatorDark: HSVColor = .hsv(7, 13.0, 27.1)
	


	@inlinable
	public static func grayish(
		_ value: Int
	) -> HSVColor {
		HSVColor(
			0.0,
			0.0,
			Double(value) / 100
		)
	}
	
	
	@inlinable
	public static func grayish(
		_ value: Double
	) -> HSVColor {
		HSVColor(
			0.0,
			0.0,
			value
		)
	}
	
	
	@inlinable
	public static func hsv(
		_ hue: Int,
		_ saturation: Double,
		_ value: Double
	) -> HSVColor {
		HSVColor(
			hue,
			saturation,
			value
		)
	}
	
	
	@inlinable
	public static func hsv(
		_ hue: Double,
		_ saturation: Double,
		_ value: Double
	) -> HSVColor {
		HSVColor(
			hue,
			saturation,
			value
		)
	}
	
	
	public init(
		_ hue: Int,
		_ saturation: Double,
		_ value: Double
	) {
		self.hue = Double(hue) / 360
		self.saturation = saturation / 100
		self.value = value / 100
	}
	
	
	public init(
		_ hue: Double,
		_ saturation: Double,
		_ value: Double
	) {
		self.hue = hue
		self.saturation = saturation
		self.value = value
	}
	
	
	public var hue: Double
	public var saturation: Double
	public var value: Double
	
	
}


extension HSVColor {
	
	
	public var asRGB: RGBColor {
		var r: Double = value
		var g: Double = value
		var b: Double = value
		
		if saturation > 0.0 {
			let h: Double = hue * 6.0
			let s: Double = saturation
			
			let i: Double = Libc.floor(h)
			let f: Double = h - i
			
			switch Int(i) {
				case 0:
					g *= 1 - s * (1 - f)
					b *= 1 - s
					break
				case 1:
					r *= 1 - s * f
					b *= 1 - s
					break
				case 2:
					r *= 1 - s
					b *= 1 - s * (1 - f)
					break
				case 3:
					r *= 1 - s
					g *= 1 - s * f
					break
				case 4:
					r *= 1 - s * (1 - f)
					g *= 1 - s
					break
				case 5:
					g *= 1 - s
					b *= 1 - s * f
					break
				default:
					break
			}
		}
		
		return RGBColor(
			Int(round(r * 255)),
			Int(round(g * 255)),
			Int(round(b * 255))
		)
	}
	
	
}


extension HSVColor : Equatable {
	
}
