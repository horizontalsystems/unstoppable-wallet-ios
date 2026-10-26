import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct NodeUrlValidatorTests {
    // MARK: EvmSyncSourceUrlValidator

    @Test func evmAcceptsHttpsAndWss() throws {
        let https = try EvmSyncSourceUrlValidator.validate(urlString: "https://rpc.example.com", blockchainType: .ethereum)
        #expect(https == URL(string: "https://rpc.example.com"))

        let wss = try EvmSyncSourceUrlValidator.validate(urlString: "wss://rpc.example.com/ws", blockchainType: .ethereum)
        #expect(wss == URL(string: "wss://rpc.example.com/ws"))
    }

    @Test func evmRejectsHttpForNonTron() {
        #expect(throws: EvmSyncSourceUrlValidator.ValidationError.invalid) {
            try EvmSyncSourceUrlValidator.validate(urlString: "http://rpc.example.com", blockchainType: .ethereum)
        }
    }

    @Test func tronAcceptsHttpAndRejectsWss() throws {
        let http = try EvmSyncSourceUrlValidator.validate(urlString: "http://api.trongrid.io", blockchainType: .tron)
        #expect(http == URL(string: "http://api.trongrid.io"))

        #expect(throws: EvmSyncSourceUrlValidator.ValidationError.invalid) {
            try EvmSyncSourceUrlValidator.validate(urlString: "wss://api.trongrid.io", blockchainType: .tron)
        }
    }

    @Test(arguments: ["rpc.example.com", "https://", "", "   "])
    func evmRejectsMissingHostOrScheme(urlString: String) {
        #expect(throws: EvmSyncSourceUrlValidator.ValidationError.invalid) {
            try EvmSyncSourceUrlValidator.validate(urlString: urlString, blockchainType: .ethereum)
        }
    }

    @Test func evmTrimsWhitespace() throws {
        let url = try EvmSyncSourceUrlValidator.validate(urlString: "  https://rpc.example.com \n", blockchainType: .ethereum)
        #expect(url == URL(string: "https://rpc.example.com"))
    }

    // MARK: MoneroNodeUrlValidator

    @Test func moneroRequiresHttps() {
        #expect(throws: MoneroNodeUrlValidator.ValidationError.invalid) {
            try MoneroNodeUrlValidator.validate(urlString: "http://node.io:18081")
        }
    }

    @Test func moneroRequiresPort() {
        #expect(throws: MoneroNodeUrlValidator.ValidationError.portRequired) {
            try MoneroNodeUrlValidator.validate(urlString: "https://node.io")
        }
    }

    @Test func moneroAcceptsHttpsWithPort() throws {
        let url = try MoneroNodeUrlValidator.validate(urlString: "https://node.io:18081")
        #expect(url == URL(string: "https://node.io:18081"))
    }

    @Test func moneroRejectsMissingHost() {
        #expect(throws: MoneroNodeUrlValidator.ValidationError.invalid) {
            try MoneroNodeUrlValidator.validate(urlString: "https:80")
        }
    }

    @Test func canonicalDefaultsPorts() throws {
        let https = try #require(URL(string: "https://node.io"))
        let http = try #require(URL(string: "http://node.io"))

        #expect(MoneroNodeUrlValidator.canonical(url: https) == "node.io:443")
        #expect(MoneroNodeUrlValidator.canonical(url: http) == "node.io:80")
    }

    @Test func canonicalHandlesBareHostPort() throws {
        let legacy = try #require(URL(string: "node.io:18081"))
        let https = try #require(URL(string: "https://node.io:18081"))

        #expect(MoneroNodeUrlValidator.canonical(url: legacy) == "node.io:18081")
        #expect(MoneroNodeUrlValidator.canonical(url: legacy) == MoneroNodeUrlValidator.canonical(url: https))
    }
}
