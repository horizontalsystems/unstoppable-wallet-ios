import Foundation
import Testing

/// Reads the sources, so that no send path can reach a handler's send(data:) around the E2E broadcast guard
/// and no Debug-E2E configuration can lose its E2E compilation condition.
struct BroadcastGuardTests {
    private static let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    private static let sourcesDirectory = testsDirectory
        .appendingPathComponent("../../packages/WalletCore/Sources/WalletCore")
        .standardizedFileURL

    private static let projectFile = testsDirectory
        .appendingPathComponent("../Unstoppable.xcodeproj/project.pbxproj")
        .standardizedFileURL

    private static func read(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private static func codeLines(_ text: String) -> [String] {
        text.components(separatedBy: "\n").filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !(trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*"))
        }
    }

    /// Both forms Xcode writes for a list setting are accepted: a string of space-separated values and an array.
    private static func conditionValues(in lines: ArraySlice<Substring>) -> Set<String>? {
        let key = "SWIFT_ACTIVE_COMPILATION_CONDITIONS = "
        let quotes = CharacterSet(charactersIn: "\"")

        guard let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(key) }) else {
            return nil
        }

        var value = lines[index].trimmingCharacters(in: .whitespaces).dropFirst(key.count)
            .trimmingCharacters(in: .whitespaces)

        if value == "(" {
            var values = Set<String>()
            for line in lines[lines.index(after: index)...] {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed == ");" {
                    break
                }
                var item = trimmed
                if item.hasSuffix(",") {
                    item.removeLast()
                }
                item = item.trimmingCharacters(in: quotes)
                if !item.isEmpty, item != "$(inherited)" {
                    values.insert(item)
                }
            }
            return values
        }

        if value.hasSuffix(";") {
            value.removeLast()
        }
        value = value.trimmingCharacters(in: quotes)
        return Set(value.split(whereSeparator: { $0.isWhitespace }).map(String.init))
    }

    @Test func guardPrecedesHandlerSend() throws {
        let file = Self.sourcesDirectory.appendingPathComponent("Modules/SendNew/SendViewModel.swift")
        try #require(FileManager.default.fileExists(atPath: file.path))

        let text = try Self.read(file)
        let sendDeclaration = try #require(text.range(of: "func send()"))
        let body = text[sendDeclaration.lowerBound...]
        let guardRange = try #require(body.range(of: "BroadcastGuard.check()"))
        let sendRange = try #require(body.range(of: "handler.send(data:"))

        #expect(guardRange.lowerBound < sendRange.lowerBound)
    }

    @Test func handlerSendIsCalledOnlyBehindTheGuard() throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: Self.sourcesDirectory.path, isDirectory: &isDirectory)
        try #require(exists)
        try #require(isDirectory.boolValue)

        let enumerator = try #require(FileManager.default.enumerator(at: Self.sourcesDirectory, includingPropertiesForKeys: nil))
        let swiftFiles = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        try #require(!swiftFiles.isEmpty)

        var callers = Set<String>()
        for file in swiftFiles {
            let lines = try Self.codeLines(Self.read(file))
            if lines.contains(where: { $0.contains(".send(data:") || $0.contains(".sendCapturingRef(data:") }) {
                callers.insert(file.lastPathComponent)
            }
        }

        let allowed: Set = ["SendViewModel.swift", "CrossPayHandler.swift", "PrivateSendHandler.swift"]
        let offenders = callers.subtracting(allowed).sorted().joined(separator: ", ")

        #expect(callers.contains("SendViewModel.swift"))
        #expect(offenders.isEmpty, "send(data:) is called outside the guarded files: \(offenders)")
    }

    @Test func debugE2EKeepsTheE2ECondition() throws {
        try #require(FileManager.default.fileExists(atPath: Self.projectFile.path))

        let text = try Self.read(Self.projectFile)
        let chunks = text.components(separatedBy: "isa = XCBuildConfiguration;").dropFirst()

        var count = 0
        for chunk in chunks {
            let lines = chunk.split(separator: "\n", omittingEmptySubsequences: false)
            guard let nameIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("name = ") }) else {
                continue
            }

            let name = lines[nameIndex].trimmingCharacters(in: .whitespaces)
                .dropFirst("name = ".count)
                .trimmingCharacters(in: CharacterSet(charactersIn: ";\""))
            guard name == "Debug-E2E", let values = Self.conditionValues(in: lines[...nameIndex]) else { continue }

            count += 1
            #expect(values.contains("E2E"), "Debug-E2E lost the E2E condition: \(values.sorted())")
        }

        #expect(count >= 1)
    }
}
