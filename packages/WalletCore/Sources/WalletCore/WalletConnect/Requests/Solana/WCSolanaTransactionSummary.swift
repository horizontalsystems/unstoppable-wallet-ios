import Foundation
import MarketKit
import SolanaKit

// Best-effort disclosure of top-level actions, not simulation or a guarantee of a swap's effects.
// Lookup-table addresses cannot be resolved offline and must never disappear from a transfer row.
struct WCSolanaTransactionSummary {
    enum Method {
        case swap
        case transfer
    }

    enum AccountRef: Equatable {
        case address(String)
        case lookupTable
    }

    // Declaration order is the display priority, including across a signAll batch.
    enum Warning: CaseIterable, Hashable {
        case hiddenRecipient
        case unreadable
        case unknownInstructions
    }

    struct Transfer {
        let amount: UInt64
        // nil for SOL and for SPL Transfer, which carries no decimals
        let decimals: Int?
        let isSol: Bool
        let source: AccountRef
        let destination: AccountRef
    }

    private static let swapPrograms: Set<String> = KnownPrograms.all.union([
        "DF1ow4tspfHX9JwWJsAb9epbkA8hmpSEAtxXy1V27QBH", // DFlow, Jupiter routes some legs through it
    ])
    private static let tokenPrograms: Set<String> = [PublicKey.tokenProgramId.base58, PublicKey.token2022ProgramId.base58]
    private static let auxiliaryPrograms: Set<String> = [
        "ComputeBudget111111111111111111111111111111",
        "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr",
        "Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo",
    ]
    private static let associatedTokenProgram = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

    let method: Method?
    let transfers: [Transfer]
    // the account that pays the network fee (accountKeys[0]); nil when the transaction cannot be read
    let feePayer: String?
    let warnings: Set<Warning>

    // nothing material decoded: the user would be signing blind
    var opaque: Bool {
        method == nil && transfers.isEmpty
    }

    init(rawTransaction: Data) {
        guard let (_, message) = try? SolanaSerializer.deserialize(transactionData: rawTransaction),
              let summary = try? Self.decode(message: message)
        else {
            self.init(method: nil, transfers: [], feePayer: nil, warnings: [.unreadable])
            return
        }
        self = summary
    }

    private init(method: Method?, transfers: [Transfer], feePayer: String?, warnings: Set<Warning>) {
        self.method = method
        self.transfers = transfers
        self.feePayer = feePayer
        self.warnings = warnings
    }

    private static func decode(message: SolanaSerializer.CompiledMessage) throws -> Self {
        let keys = message.accountKeys.map(\.base58)
        let loadedCount = message.addressLookupTables.reduce(0) { $0 + $1.writableIndexes.count + $1.readonlyIndexes.count }
        let accountCount = keys.count + loadedCount
        // Validate every reference, including those in instructions we do not display.
        guard !keys.isEmpty, accountCount <= 256,
              message.instructions.allSatisfy({ instruction in
                  Int(instruction.programIdIndex) < keys.count && instruction.accountIndices.allSatisfy { Int($0) < accountCount }
              })
        else {
            throw DecodeError.invalidAccounts
        }

        var transfers = [Transfer]()
        var isSwap = false
        var hasUnknownInstructions = false

        for instruction in message.instructions {
            let programId = keys[Int(instruction.programIdIndex)]
            let data = instruction.data

            // an instruction addresses accounts by slot into its own list, which indexes the message keys
            func account(_ slot: Int) throws -> AccountRef {
                guard instruction.accountIndices.indices.contains(slot) else { throw DecodeError.invalidAccounts }
                let index = Int(instruction.accountIndices[slot])
                return index < keys.count ? .address(keys[index]) : .lookupTable
            }

            if Self.swapPrograms.contains(programId) {
                isSwap = true
            } else if programId == PublicKey.systemProgramId.base58 {
                // Transfer and CreateAccount both debit lamports from [funder, destination].
                if (data.count >= 12 && data.prefix(4) == Data([2, 0, 0, 0])) ||
                    (data.count >= 52 && data.prefix(4) == Data([0, 0, 0, 0]))
                {
                    transfers.append(try Transfer(amount: Self.u64(data, at: 4), decimals: nil, isSol: true, source: account(0), destination: account(1)))
                } else {
                    // Includes CreateAccountWithSeed, Assign and nonce operations.
                    hasUnknownInstructions = true
                }
            } else if Self.tokenPrograms.contains(programId) {
                switch data.first {
                // SPL Transfer: index 3, u64 amount; accounts [source, destination, owner]
                case 3 where data.count >= 9:
                    transfers.append(try Transfer(amount: Self.u64(data, at: 1), decimals: nil, isSol: false, source: account(2), destination: account(1)))
                // SPL TransferChecked: index 12, u64 amount, u8 decimals; accounts [source, mint, destination, owner]
                case 12 where data.count >= 10:
                    transfers.append(try Transfer(amount: Self.u64(data, at: 1), decimals: Int(data[data.startIndex + 9]), isSol: false, source: account(3), destination: account(2)))
                case 9:
                    // CloseAccount sweeps lamports; only a known return to the owner is exempt.
                    let destination = try account(1)
                    let owner = try account(2)
                    switch (destination, owner) {
                    case let (.address(destination), .address(owner)) where destination == owner:
                        break
                    default:
                        hasUnknownInstructions = true
                    }
                case 1, 17, 18:
                    // InitializeAccount, SyncNative, InitializeAccount3; not all Token instructions.
                    break
                default:
                    hasUnknownInstructions = true
                }
            } else if programId == Self.associatedTokenProgram {
                // Create (including the original empty encoding) and CreateIdempotent only.
                // RecoverNested can move funds and must not inherit this exemption.
                if let discriminator = data.first, discriminator != 0, discriminator != 1 {
                    hasUnknownInstructions = true
                }
            } else if !Self.auxiliaryPrograms.contains(programId) {
                hasUnknownInstructions = true
            }
        }

        let method: Method? = isSwap ? .swap : (transfers.isEmpty ? nil : .transfer)
        var warnings = Set<Warning>()
        if transfers.contains(where: { $0.destination == .lookupTable }) { warnings.insert(.hiddenRecipient) }
        if method == nil, transfers.isEmpty {
            warnings.insert(.unreadable)
        } else if hasUnknownInstructions {
            warnings.insert(.unknownInstructions)
        }
        return Self(method: method, transfers: transfers, feePayer: keys.first, warnings: warnings)
    }

    func fields(baseToken: Token, signer: String?) -> [SendField] {
        var fields = [SendField]()

        if let method {
            let value = method == .swap ? "swap.title".localized : "wallet_connect.solana.method_transfer".localized
            fields.append(.simpleValue(title: "send.confirmation.method".localized, value: value))
        }

        for transfer in transfers {
            if transfer.isSol {
                let appValue = AppValue(token: baseToken, value: Decimal(transfer.amount) / pow(10, baseToken.decimals))
                fields.append(.value(title: "wallet_connect.solana.value".localized, appValue: appValue, currencyValue: nil, formatFull: true))
            } else {
                let amount = transfer.decimals.map { Decimal(transfer.amount) / pow(10, $0) } ?? Decimal(transfer.amount)
                fields.append(.simpleValue(title: "wallet_connect.solana.value".localized, value: amount.description))
            }
            switch transfer.source {
            case let .address(address):
                if address != signer {
                    fields.append(.recipient(title: "send.confirmation.from".localized, value: address, copyable: true, blockchainType: baseToken.blockchainType))
                }
            case .lookupTable:
                fields.append(.simpleValue(title: "send.confirmation.from".localized, value: "wallet_connect.solana.unknown_lookup_address".localized))
            }
            switch transfer.destination {
            case let .address(address):
                fields.append(.recipient(title: "send.confirmation.to".localized, value: address, copyable: true, blockchainType: baseToken.blockchainType))
            case .lookupTable:
                fields.append(.simpleValue(title: "send.confirmation.to".localized, value: "wallet_connect.solana.unknown_lookup_address".localized))
            }
        }

        return fields
    }

    private enum DecodeError: Error {
        case invalidAccounts
    }

    private static func u64(_ data: Data, at offset: Int) -> UInt64 {
        data[(data.startIndex + offset) ..< (data.startIndex + offset + 8)].reversed().reduce(0) { $0 << 8 | UInt64($1) }
    }
}
