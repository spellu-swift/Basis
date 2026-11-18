#if canImport(Darwin)
@_exported import Darwin
#elseif canImport(Glibc)
@_exported import Glibc
#elseif canImport(Musl)
@_exported @preconcurrency import Musl
public var environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> {
	Musl.environ
}
#elseif canImport(WinSDK)
@_exported import WinSDK
#endif
