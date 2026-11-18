@testable import BasisUtility
import UnitTesting


struct ColorTest {

	@Test
	func HSVtoRGB() {
		#expect(HSVColor(  0,   0,   0).asRGB == RGBColor(0x00, 0x00, 0x00))
		#expect(HSVColor(  0,   0,  50).asRGB == RGBColor(0x80, 0x80, 0x80))
		#expect(HSVColor(  0,   0, 100).asRGB == RGBColor(0xFF, 0xFF, 0xFF))
		
		#expect(HSVColor(  0, 100, 100).asRGB == RGBColor(0xFF, 0x00, 0x00))
		#expect(HSVColor( 30, 100, 100).asRGB == RGBColor(0xFF, 0x80, 0x00))
		#expect(HSVColor( 60, 100, 100).asRGB == RGBColor(0xFF, 0xFF, 0x00))
		#expect(HSVColor( 90, 100, 100).asRGB == RGBColor(0x80, 0xFF, 0x00))
		#expect(HSVColor(120, 100, 100).asRGB == RGBColor(0x00, 0xFF, 0x00))
		#expect(HSVColor(150, 100, 100).asRGB == RGBColor(0x00, 0xFF, 0x80))
		#expect(HSVColor(180, 100, 100).asRGB == RGBColor(0x00, 0xFF, 0xFF))
		#expect(HSVColor(210, 100, 100).asRGB == RGBColor(0x00, 0x80, 0xFF))
		#expect(HSVColor(240, 100, 100).asRGB == RGBColor(0x00, 0x00, 0xFF))
		#expect(HSVColor(270, 100, 100).asRGB == RGBColor(0x80, 0x00, 0xFF))
		#expect(HSVColor(300, 100, 100).asRGB == RGBColor(0xFF, 0x00, 0xFF))
		#expect(HSVColor(330, 100, 100).asRGB == RGBColor(0xFF, 0x00, 0x80))
	}
		
	@Test
	func RGBtoHSV() {
		#expect(RGBColor(0x00, 0x00, 0x00).asHSV == HSVColor(  0,   0,   0))
		#expect(RGBColor(0x80, 0x80, 0x80).asHSV == HSVColor(  0,   0,  50.2))
		#expect(RGBColor(0xFF, 0xFF, 0xFF).asHSV == HSVColor(  0,   0, 100))
		
		#expect(RGBColor(0xFF, 0x00, 0x00).asHSV == HSVColor(  0, 100, 100))
	}
		
	@Test
	func appleDefinedColor() {
		#expect(RGBColor(0x3C, 0x84, 0xF7).asHSV == HSVColor(217, 75.7, 96.9))
		#expect(HSVColor(217, 75.7, 96.9).asRGB.hexString == RGBColor(0x3C, 0x84, 0xF7).hexString)

		#expect(RGBColor(0x3C, 0x87, 0xF7).asHSV == HSVColor(216, 75.7, 96.9))
		#expect(HSVColor(216, 75.7, 96.9).asRGB.hexString == RGBColor(0x3C, 0x87, 0xF7).hexString)
	}
		
//	func test() {
//		#expect(rgb(HSVColor(  0, 100, 100)), "#FF0000")
//		#expect(rgb(HSVColor( 30, 100, 100)), "#FF8000")
//		#expect(rgb(HSVColor( 60, 100, 100)), "#FFFF00")
//
//		#expect(rgb(HSVColor(217, 75.7, 96.9)), "#3C84F7")
//		#expect(rgb(HSVColor(216, 75.7, 96.9)), "#3C87F7")
//		#expect(rgb(HSVColor(211, 100, 100)), "#007BFF")
//		#expect(HSVColor.blue.asRGB.hexString, "#007BFF")
//	}
		
//	func rgb(_ color: HSVColor) -> String {
//		Color(hue: color.hue, saturation: color.saturation, brightness: color.value)
//			.description
//			.dropLast(2).asString
//	}
		
}
