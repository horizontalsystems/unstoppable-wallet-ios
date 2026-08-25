import Foundation
import ZcashLightClientKit

enum ZcashFileStore {
    // Sapling parameters are identical across all wallets, so they live in a single shared
    // location (no per-wallet suffix). The SDK downloads and SHA1-validates them on demand;
    // we just hand it the destination path.
    static let spendParamsFilename = "sapling-spend.params"
    static let outputParamsFilename = "sapling-output.params"

    static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("z-cash-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    static func exist(url: URL) -> Bool {
        let fileManager = FileManager.default

        do {
            return try fileManager.fileExists(coordinatingAccessAt: url).exists
        } catch {
            return false
        }
    }

    static func fsBlockDbRootURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + ZcashSDK.defaultFsCacheName, isDirectory: true)
    }

    static func generalStorageURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + "general_storage", isDirectory: true)
    }

    static func dataDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultDataDbName, isDirectory: false)
    }

    static func torDirURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultTorDirName, isDirectory: true)
    }

    static func spendParamsURL() throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(spendParamsFilename)
    }

    static func outputParamsURL() throws -> URL {
        try dataDirectoryUrl().appendingPathComponent(outputParamsFilename)
    }

    // One-time cleanup: promote any pre-existing per-wallet sapling params
    // ("sapling-{spend,output}_<uniqueId>.params") to the shared, wallet-agnostic
    // location so existing users don't have to re-download ~51MB.
    static func migrateSharedSaplingParamsIfNeeded() {
        let fileManager = FileManager.default
        guard let dir = try? dataDirectoryUrl(),
              let files = try? fileManager.contentsOfDirectory(atPath: dir.path)
        else { return }

        for (legacyPrefix, sharedName) in [
            ("sapling-spend_", spendParamsFilename),
            ("sapling-output_", outputParamsFilename),
        ] {
            let legacy = files.filter { $0.hasPrefix(legacyPrefix) && $0.hasSuffix(".params") }
            guard !legacy.isEmpty else { continue }

            let sharedURL = dir.appendingPathComponent(sharedName)
            if !fileManager.fileExists(atPath: sharedURL.path), let first = legacy.first {
                // Promote one legacy copy to the shared location; SDK will SHA1-validate it.
                try? fileManager.moveItem(at: dir.appendingPathComponent(first), to: sharedURL)
            }
            // Remove any remaining per-wallet copies (including the one we just moved if move failed).
            let remaining = (try? fileManager.contentsOfDirectory(atPath: dir.path)) ?? []
            for filename in remaining where filename.hasPrefix(legacyPrefix) && filename.hasSuffix(".params") {
                try? fileManager.removeItem(at: dir.appendingPathComponent(filename))
            }
        }
    }

    static func clear(except excludedWalletIds: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        let preservedFilenames: Set<String> = [spendParamsFilename, outputParamsFilename]

        for filename in fileUrls {
            if preservedFilenames.contains(filename.lastPathComponent) {
                continue
            }
            if !excludedWalletIds.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }
}
