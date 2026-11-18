#if os(macOS) || canImport(Glibc)
import Libc


extension Subprocess {
	
	///
	/// プログラムを実行する。
	///
	/// 子プロセスに渡す環境変数と作業ディレクトリで、プログラムを探す。
	/// - fileがファイル名なら、environmentのPATHから実行可能な通常ファイルを探す。PATHの空の項目と相対の項目は、作業ディレクトリを基準にする。
	/// - fileが/を含む相対パスなら、作業ディレクトリを基準にする。
	/// - fileと作業ディレクトリは、~や環境変数を展開せず文字どおりに解釈する。
	///
	/// - file: ファイルパス、もしくはファイル名。
	/// - arguments: 引数
	/// - workingDirectory: ワーキングディレクトリのパス。nilの場合は現在のワーキングディレクトリが使用される。相対パスは現在のワーキングディレクトリを基準にする。
	/// - environment: 環境変数。nilの場合は現在のプロセスの環境変数をすべて引き継ぐ。
	///
	public static func execute(
		file: String,
		arguments: [String] = [],
		workingDirectory: FilePath? = nil,
		environment: [String : String]? = nil,
	) throws -> Subprocess {
		let currentDirectory: FilePath = .init(POSIX.getcwd())
		let workingDirectory: FilePath
		= workingDirectory?.absoluted(relativeTo: currentDirectory, as: .directory)
			?? currentDirectory
		let environment: [String : String]
		= environment ?? Backbone.environment.values

		guard
			let path = searchExecutable(
				file,
				workingDirectory: workingDirectory,
				environment: environment,
			)
		else { throw GeneralError.unexpectedValue("File '\(file)' not found") }

		return try execute(
			[path.asString] + arguments,
			workingDirectoryPath: workingDirectory.asString,
			environment: environment,
		)
	}
	
	///
	/// シェルコマンドを実行する。
	///
	/// commandはシェルが解釈できる文字列。commandの引数をエスケープするのは使用側の責任です。
	///
	/// - shell: シェルのパス
	/// - command: コマンド文字列。
	/// - workingDirectory: ワーキングディレクトリのパス。nilの場合は現在のワーキングディレクトリが使用される。
	/// - environment: 環境変数。nilの場合は現在のプロセスの環境変数をすべて引き継ぐ。
	///
	public static func execute(
		shell: String = "/bin/sh",
		command: String,
		workingDirectory: FilePath? = nil,
		environment: [String : String]? = nil,
	) throws -> Subprocess {
		try execute(
			file: shell,
			arguments: ["-c", command],
			workingDirectory: workingDirectory,
			environment: environment,
		)
	}
	
	///
	/// プログラムを実行する。
	///
	/// argumentsの最初の要素をプログラムとして、``execute(file:arguments:workingDirectory:environment:)``と同じ規則で探す。
	///
	/// - arguments: コマンド引数。
	/// - workingDirectory: ワーキングディレクトリのパス。nilの場合は現在のワーキングディレクトリが使用される。
	/// - environment: 環境変数。nilの場合は現在のプロセスの環境変数をすべて引き継ぐ。
	///
	public static func execute(
		_ arguments: [String],
		workingDirectory: FilePath? = nil,
		environment: [String : String]? = nil,
	) throws -> Subprocess {
		guard let file = arguments.first
		else { throw GeneralError.unexpectedValue("arguments") }

		return try execute(
			file: file,
			arguments: Array(arguments.dropFirst()),
			workingDirectory: workingDirectory,
			environment: environment,
		)
	}

	/// 子プロセスの環境で、実行するプログラムの絶対パスを求める。
	static func searchExecutable(
		_ file: String,
		workingDirectory: FilePath,
		environment: [String : String],
	) -> FilePath? {
		func absolute(_ path: String) -> FilePath {
			FilePath(path).absoluted(relativeTo: workingDirectory, as: .directory)
		}

		if file.contains("/") {
			return absolute(file)
		}

		guard let paths = environment["PATH"]
		else { return nil }

		return paths
			.split(separator: ":", omittingEmptySubsequences: false)
			.map { absolute(String($0)).appending(file) }
			.first {
				FileStatus(at: $0, followLink: true)?.type == .file && POSIX.access($0.asString, .execute)
			}
	}

	// 既に確定したパスを再展開せず実行する。
	static func execute(
		_ arguments: [String],
		workingDirectoryPath: String,
		environment: [String : String],
		pipeMaker: (inout [Int32]) -> Int32 = { pipe(&$0) },
	) throws -> Subprocess {
		assert(arguments.isNotEmpty)
		assert(arguments[0].hasPrefix("/"))

		guard
			arguments.count > 0
		else { throw GeneralError.unexpectedValue("arguments") }
		
		var pid: pid_t = 0
		
#if canImport(Darwin)
		var fileActions: posix_spawn_file_actions_t? = nil
#else
		var fileActions: posix_spawn_file_actions_t = .init()
#endif

		posix_spawn_file_actions_init(&fileActions)
		
		defer {
			posix_spawn_file_actions_destroy(&fileActions)
		}
		
		// 作成に失敗した組は-1のままで、closeは何もしない。
		var inFds: [Int32] = [-1, -1]
		var outFds: [Int32] = [-1, -1]
		var errFds: [Int32] = [-1, -1]
		var spawned: Bool = false
		
		defer {
			close(inFds[0])
			close(outFds[1])
			close(errFds[1])

			// 起動に成功したら、親が使う側はSubprocessが閉じる。
			if !spawned {
				close(inFds[1])
				close(outFds[0])
				close(errFds[0])
			}
		}
		
		try POSIX.checkError(pipeMaker(&inFds) == 0)
		try POSIX.checkError(pipeMaker(&outFds) == 0)
		try POSIX.checkError(pipeMaker(&errFds) == 0)
		
		posix_spawn_file_actions_addclose(&fileActions, inFds[1])
		posix_spawn_file_actions_addclose(&fileActions, outFds[0])
		posix_spawn_file_actions_addclose(&fileActions, errFds[0])
		
		posix_spawn_file_actions_adddup2 (&fileActions, inFds[0],  STDIN_FILENO)  // 0: stdin
		posix_spawn_file_actions_adddup2 (&fileActions, outFds[1], STDOUT_FILENO) // 1: stdout
		posix_spawn_file_actions_adddup2 (&fileActions, errFds[1], STDERR_FILENO) // 2: stderr
		
		posix_spawn_file_actions_addclose(&fileActions, inFds[0])
		posix_spawn_file_actions_addclose(&fileActions, outFds[1])
		posix_spawn_file_actions_addclose(&fileActions, errFds[1])
		
#if canImport(Darwin) && os(macOS)
		let workingDirectory = workingDirectoryPath

		if #available(macOS 26.0, *) {
			posix_spawn_file_actions_addchdir(&fileActions, workingDirectory)
		} else {
			posix_spawn_file_actions_addchdir_np(&fileActions, workingDirectory)
		}
#elseif canImport(Glibc)
		posix_spawn_file_actions_addchdir_np(
			&fileActions,
			workingDirectoryPath,
		)

		// 明示した標準入出力だけを子へ渡す。
		posix_spawn_file_actions_addclosefrom_np(
			&fileActions,
			STDERR_FILENO + 1,
		)
#endif
		
#if canImport(Darwin) || os(Android) || os(OpenBSD)
		var spawnAttrs: posix_spawnattr_t? = nil
#else
		var spawnAttrs: posix_spawnattr_t = posix_spawnattr_t()
#endif
		
		defer {
			posix_spawnattr_destroy(&spawnAttrs)
		}
		
		posix_spawnattr_init(&spawnAttrs)
		// 親がブロック・無視したシグナル状態を子へ持ち込まない。
		var signalMask: sigset_t = .init()
		var signalDefaults: sigset_t = .init()
		sigemptyset(&signalMask)
		sigfillset(&signalDefaults)
		sigdelset(&signalDefaults, SIGKILL)
		sigdelset(&signalDefaults, SIGSTOP)
#if canImport(Darwin)
		// 明示した標準入出力だけを子へ渡す。
		let closeOnExecFlag: Int32 = POSIX_SPAWN_CLOEXEC_DEFAULT
#else
		// Linuxはファイルアクションのclosefromで閉じる。
		let closeOnExecFlag: Int32 = 0
#endif
		let setupResults: [Int32] = [
			posix_spawnattr_setsigmask(&spawnAttrs, &signalMask),
			posix_spawnattr_setsigdefault(&spawnAttrs, &signalDefaults),
			posix_spawnattr_setflags(
				&spawnAttrs,
				.init(
					POSIX_SPAWN_SETPGROUP
						| POSIX_SPAWN_SETSIGMASK
						| POSIX_SPAWN_SETSIGDEF
						| closeOnExecFlag
				),
			),
		]
		for result in setupResults where result != 0 {
			throw POSIXError.system(result)
		}

		let argumentList: UnsafeMutableBufferPointer<CCharPointer?> = arguments.cPointerList
		
		let variableList: UnsafeMutableBufferPointer<CCharPointer?> = environment.cPointerList
		
		defer {
			argumentList.deallocate()
			
			variableList.deallocate()
		}
		
		let result: Int32 =
		Libc.posix_spawn(
			&pid,
			argumentList[0]!,
			&fileActions,
			&spawnAttrs,
			argumentList.baseAddress!,
			variableList.baseAddress,
		)
		
		guard
			result == 0
		else { throw POSIXError.system(result) }
		
		spawned = true

		let process = Subprocess(
			pid: pid,
			inFd: inFds[1],
			outFd: outFds[0],
			errFd: errFds[0],
		)
		
		return process
	}
	
}


private typealias CCharPointer = UnsafeMutablePointer<CChar>


private extension [String] {
	
	var estimatedBufferCount: Int {
		self.reduce(0) { result, element in
			result + element.utf8.count + 1
		}
	}
	
	var cPointerList: UnsafeMutableBufferPointer<CCharPointer?> {
		let count: Int = self.count
		
		let buffer: UnsafeMutableRawPointer! = .allocate(
			byteCount: (count + 1) * MemoryLayout<CCharPointer?>.size + estimatedBufferCount,
			alignment: 8,
		)
		
		let argumentList: UnsafeMutablePointer<CCharPointer?> = buffer.assumingMemoryBound(
			to: CCharPointer?.self,
		)
		
		var pointer: UnsafeMutablePointer<CChar> = buffer
			.advanced(
				by: (count + 1) * MemoryLayout<CCharPointer>.size,
			)
			.assumingMemoryBound(
				to: CChar.self,
			)
		
		for index in 0..<count {
			let string = self[index]
			
			argumentList[index] = string.utf8CString
				.withUnsafeBufferPointer {
					let current = pointer
					
					pointer = pointer.advanced(by: $0.count)
					
					memcpy(current, $0.baseAddress!, $0.count)
					
					return current
				}
		}
		
		argumentList[count] = nil
		
		return .init(
			start: argumentList,
			count: count + 1,
		)
	}
	
}


private extension [String : String] {
	
	var cPointerList: UnsafeMutableBufferPointer<CCharPointer?> {
		map {
			"\($0.key)=\($0.value)"
		}
		.cPointerList
	}
	
}


#endif
