import Libc


public enum Backbone {

	/// POSIXの環境変数
	public final class Environment : Sendable {

		let _values: Barrier<[String : String]>
		= .init(POSIX.environment)
		
		/// 環境変数を取得／設定する
		@inlinable
		public subscript (
			_ name: String,
		) -> String? {
			get {
				get(name: name)
			}
			set {
				if
					let newValue
				{
					set(name: name, value: newValue)
				}
				else {
					unset(name: name)
				}
			}
		}

		/// 環境変数全体を再読み込みする
		public func reload() {
			_values.atomic{ $0 = POSIX.environment }
		}

		/// 環境変数全体を取得する
		public var values: [String : String] {
			_values.atomic{ $0 }
		}

		/// 環境変数を取得する
		public func get (
			name: String,
		) -> String? {
			_values.atomic{ $0[name] }
		}

		/// 環境変数を設定する
		public func set(
			name: String,
			value: String,
		) {
			_values.atomic {
				guard
					setenv(name, value, 1) == 0
				else { return }

				$0[name] = value
			}
		}

		/// 環境変数を削除する
		public func unset(
			name: String,
		) {
			_values.atomic {
				guard
					unsetenv(name) == 0
				else { return }

				$0[name] = nil
			}
		}

	}

	/// 現在の環境
	public static let environment: Environment = .init()

	/// 現在のワーキングディレクトリ
	@inlinable
	public static var workingDirectory: FilePath {
		.init(
			POSIX.getcwd()
		)
	}

	/// テンポラリディレクトリ
	@inlinable
	public static var temporaryDirectory: FilePath {
		.init(
			POSIX.temporaryDirectory
		)
	}
	
	/// このプロセスの実行ファイルパス
	public static var executableFile: FilePath {
		let file: String = CommandLine.arguments[0]
		
		if file.hasPrefix("/") {
			return FilePath(file)
		}
		else if file.contains("/") {
			return FilePath(file).absoluted.realized
		}
		else {
			return POSIX.searchFile(file) ?? FilePath(file)
		}
	}
	
	/// 現在のパス
	public static var paths: [FilePath] {
		environment["PATH"]?
			.split(separator: ":")
			.map{FilePath($0.asString)}
		?? []
	}

	/// 現在のプロセスを終了する
	public static func exit(
		status: Int32
	) -> Never {
		Libc.exit(status)
	}

}


extension Backbone {
	
	@inlinable
	public static func app(
		_ name: String
	) -> Application {
		.init(name: name)
	}
	
	public struct Application {
		
		public let name: String
		
		public init(
			name: String,
		) {
			self.name = name
		}

		#if os(macOS)
		public var inSandbox: Bool {
			Backbone.environment["APP_SANDBOX_CONTAINER_ID"] != nil
		}
		
		public var allUserDirectory: Directory {
			.init(at: "/Library/Application Support/\(name)")
		}

		public var userDirectory: Directory {
			.init(at: "~/Library/Application Support/\(name)")
		}

		public var allUserTemporaryDirectory: Directory {
			.init(at: "/private/tmp")
		}

		public var userTemporaryDirectory: Directory {
			.init(at: POSIX.temporaryDirectory)
		}
		#endif

		#if os(Linux)
		public var allUserPreferenceDirectory: Directory {
			.init(at: "/etc/\(name)")
		}

		public var userPreferenceDirectory: Directory {
			.init(at: "~/.config/\(name)")
		}

		public var temporaryDirectory: Directory {
			.init(at: POSIX.temporaryDirectory)
		}
		#endif
	}

}


extension Backbone {

	/// このプロセスの現在のユーザー
	public static var user: User {
		User(name: nil)!
	}

	/// ユーザー
	public static func user(
		_ name: String
	) -> User? {
		User(name: name)
	}

	public struct User {
		init?(
			name: String?
		) {
			guard let user = POSIX.user(name: name)
			else { return nil }
			
			self.user = user
		}
		
		let user: passwd

		/// ユーザーの名前
		public var name: String {
			user.pw_name.asString!
		}

		/// ユーザーのホームディレクトリ
		public var homeDirectoryString: String! {
			user.pw_dir.asString ?? Backbone.environment["HOME"]
		}

		/// ユーザーのホームディレクトリ
		public var homeDirectory: FilePath! {
			homeDirectoryString
				.map{ FilePath($0 + "/") }
		}
		
		/// ユーザーのシェル
		public var shell: FilePath {
			.init(user.pw_shell.asString)
		}
	}

}


extension Backbone {

	/// 標準入力が端末か
	public static var isInputTerminal: Bool {
		Libc.isatty(STDIN_FILENO) == 1
	}

	/// 標準出力が端末か
	public static var isOutputTerminal: Bool {
		Libc.isatty(STDOUT_FILENO) == 1
	}

	/// 標準エラー出力が端末か
	public static var isErrorTerminal: Bool {
		Libc.isatty(STDERR_FILENO) == 1
	}

	/// 標準出力
	@inlinable
	public static var outputStream: StandardStream {
		.output
	}

	/// 標準エラー出力
	@inlinable
	public static var errorStream: StandardStream {
		.error
	}

}
