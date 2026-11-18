

public enum FileType {
	case file
	case directory
	case link
	case fifo
	case character
	case block
	case socket
//	case wht
	case unknown
}


extension FileType : CustomStringConvertible {
		
	public var description: String {
		switch self {
			case .file:
				return "file"
			case .directory:
				return "directory"
			case .link:
				return "link"
			case .fifo:
				return "fifo"
			case .character:
				return "character"
			case .block:
				return "block"
			case .socket:
				return "socket"
//			case .wht:
//				return "wht"
			case .unknown:
				return "unknown"
		}
	}	
	
}

