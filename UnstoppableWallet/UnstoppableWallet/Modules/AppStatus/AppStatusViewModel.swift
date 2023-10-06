import Foundation
import MarketKit

class AppStatusViewModel {
    private let dateFormatter = DateFormatter()
    private(set) var sections = [Section]()

    init(systemInfoManager: SystemInfoManager, appVersionStorage: AppVersionStorage, accountManager: AccountManager,
         walletManager: WalletManager, adapterManager: AdapterManager, logRecordManager: LogRecordManager,
         evmBlockchainManager: EvmBlockchainManager, binanceKitManager: BinanceKitManager, marketKit: MarketKit.Kit)
    {
        dateFormatter.dateFormat = "dd MMM yyyy, HH:mm"

        sections.append(
            Section(
                title: "App Info",
                blocks: [
                    [
                        .info(title: "Current Time", value: dateFormatter.string(from: Date())),
                        .info(title: "App Version", value: systemInfoManager.appVersion.description),
                        .info(title: "Device Model", value: systemInfoManager.deviceModel),
                        .info(title: "iOS Version", value: systemInfoManager.osVersion),
                    ],
                ]
            )
        )

        let appVersions = appVersionStorage.appVersions

        if !appVersions.isEmpty {
            sections.append(
                Section(
                    title: "Version History",
                    blocks: [
                        appVersions.map { version in
                            .info(title: version.description, value: dateFormatter.string(from: version.date))
                        },
                    ]
                )
            )
        }

        let accounts = accountManager.accounts

        if !accounts.isEmpty {
            sections.append(
                Section(
                    title: "Wallets",
                    blocks: accounts.map { account in
                        var fields: [Field] = [
                            .info(title: "Name", value: account.name),
                            .info(title: "Type", value: account.type.description),
                        ]

                        if case .mnemonic = account.type {
                            fields.append(.info(title: "Origin", value: account.origin.rawValue.capitalized))
                        }

                        return fields
                    }
                )
            )
        }

        var blockchainBlocks = [[Field]]()

        for wallet in walletManager.activeWallets {
            let blockchain = wallet.token.blockchain

            switch blockchain.type {
            case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash, .zcash:
                if let adapter = adapterManager.adapter(for: wallet) {
                    blockchainBlocks.append(block(blockchain: blockchain.name, statusInfo: adapter.statusInfo))
                }
            default:
                ()
            }
        }

        for blockchain in evmBlockchainManager.allBlockchains {
            if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchain.type).evmKitWrapper {
                blockchainBlocks.append(block(blockchain: blockchain.name, statusInfo: evmKitWrapper.evmKit.statusInfo()))
            }
        }

        if let binanceKit = binanceKitManager.binanceKit {
            blockchainBlocks.append(block(blockchain: "Binance Chain", statusInfo: binanceKit.statusInfo))
        }

        if !blockchainBlocks.isEmpty {
            sections.append(
                Section(
                    title: "Blockchains",
                    blocks: blockchainBlocks
                )
            )
        }

        let marketSyncInfo = marketKit.syncInfo()

        sections.append(
            Section(
                title: "Market Last Sync Timestamps",
                blocks: [
                    [
                        .info(title: "Coins", value: marketSyncInfo.coinsTimestamp ?? "n/a"),
                        .info(title: "Blockchains", value: marketSyncInfo.blockchainsTimestamp ?? "n/a"),
                        .info(title: "Tokens", value: marketSyncInfo.tokensTimestamp ?? "n/a"),
                    ],
                ]
            )
        )

        let sendLogs = logRecordManager.logsGroupedBy(context: "Send")

        if !sendLogs.isEmpty {
            sections.append(
                Section(
                    title: "Logs",
                    blocks: [
                        [
                            .title(value: "Send"),
                            .raw(text: build(logs: sendLogs, showBullet: true).trimmingCharacters(in: .whitespacesAndNewlines)),
                        ],
                    ]
                )
            )
        }
    }

    private func block(blockchain: String, statusInfo: [(String, Any)]) -> [Field] {
        [
            .title(value: blockchain),
            .raw(text: build(logs: statusInfo, showBullet: true).trimmingCharacters(in: .whitespacesAndNewlines)),
        ]
    }

    private func build(logs: [(String, Any)], level: Int = 0, showBullet: Bool = false) -> String {
        var result = ""

        logs.forEach { key, value in
            let indentation = String(repeating: "    ", count: level)
            let bullet = showBullet ? "- " : ""
            let key = (indentation + bullet + key + ": ").capitalized

            if let date = value as? Date {
                result += key + dateFormatter.string(from: date) + "\n"
            } else if let string = value as? String {
                result += key + string + "\n"
            } else if let int = value as? Int {
                result += key + "\(int)" + "\n"
            } else if let int = value as? Int32 {
                result += key + "\(int)" + "\n"
            } else if let deep = value as? [String] {
                result += key + "\n"
                deep.forEach { str in
                    result += indentation + "    " + bullet + str + "\n"
                }
            } else if let deep = value as? [(String, Any)] {
                result += "\n" + key + "\n" + build(logs: deep, level: level + 1, showBullet: true)
            }
        }

        return result
    }

    var rawStatus: String {
        var rawInfo = ""

        for section in sections {
            rawInfo += section.title + "\n"

            for block in section.blocks {
                for field in block {
                    switch field {
                    case let .info(title, value):
                        rawInfo += "    - \(title): \(value)\n"
                    case let .title(value):
                        rawInfo += "    - \(value)\n"
                    case let .raw(text):
                        rawInfo += text.components(separatedBy: "\n").map { "        " + $0 }.joined(separator: "\n") + "\n"
                    }
                }

                rawInfo += "\n"
            }
        }

        return rawInfo.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension AppStatusViewModel {
    enum Field: Hashable {
        case info(title: String, value: String)
        case title(value: String)
        case raw(text: String)
    }

    struct Section {
        let title: String
        let blocks: [[Field]]
    }
}
