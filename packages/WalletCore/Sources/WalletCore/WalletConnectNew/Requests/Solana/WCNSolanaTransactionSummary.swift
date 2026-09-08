import Foundation
import MarketKit
import SolanaKit

// Best-effort read of a serialized Solana transaction for the request card, as Android WCSolanaTxSummary:
// a coarse method (Swap when an aggregator is invoked, otherwise Transfer) and the directly decodable
// System / SPL transfers among the top-level instructions. Swap amounts stay hidden: they live in inner
// instructions, and a destination loaded from a v0 lookup table cannot be resolved to an address.
struct WCNSolanaTransactionSummary {
    enum Method {
        case swap
        case transfer
    }

    struct Transfer {
        let amount: UInt64
        // nil for SOL and for SPL Transfer, which carries no decimals
        let decimals: Int?
        let isSol: Bool
        let destination: String?
    }

    private static let swapPrograms: Set<String> = KnownPrograms.all.union([
        "DF1ow4tspfHX9JwWJsAb9epbkA8hmpSEAtxXy1V27QBH", // DFlow, Jupiter routes some legs through it
    ])
    private static let tokenPrograms: Set<String> = [PublicKey.tokenProgramId.base58, PublicKey.token2022ProgramId.base58]

    let method: Method?
    let transfers: [Transfer]

    // nothing material decoded: the user would be signing blind
    var opaque: Bool {
        method == nil && transfers.isEmpty
    }

    init(rawTransaction: Data) {
        guard let (_, message) = try? SolanaSerializer.deserialize(transactionData: rawTransaction) else {
            method = nil
            transfers = []
            return
        }

        let keys = message.accountKeys.map(\.base58)
        // index into the message's account keys
        func accountKey(_ index: Int) -> String? {
            keys.indices.contains(index) ? keys[index] : nil
        }

        var transfers = [Transfer]()
        var isSwap = false

        for instruction in message.instructions {
            guard let programId = accountKey(Int(instruction.programIdIndex)) else {
                continue
            }
            let data = instruction.data

            // an instruction addresses accounts by slot into its own list, which indexes the message keys
            func account(_ slot: Int) -> String? {
                instruction.accountIndices.indices.contains(slot) ? accountKey(Int(instruction.accountIndices[slot])) : nil
            }

            if Self.swapPrograms.contains(programId) {
                isSwap = true
            } else if programId == PublicKey.systemProgramId.base58 {
                // System transfer: u32 index 2, then u64 lamports; accounts [from, to]
                if data.count >= 12, data.prefix(4) == Data([2, 0, 0, 0]) {
                    transfers.append(Transfer(amount: Self.u64(data, at: 4), decimals: nil, isSol: true, destination: account(1)))
                }
            } else if Self.tokenPrograms.contains(programId) {
                switch data.first {
                // SPL Transfer: index 3, u64 amount; accounts [source, destination, owner]
                case 3 where data.count >= 9:
                    transfers.append(Transfer(amount: Self.u64(data, at: 1), decimals: nil, isSol: false, destination: account(1)))
                // SPL TransferChecked: index 12, u64 amount, u8 decimals; accounts [source, mint, destination, owner]
                case 12 where data.count >= 10:
                    transfers.append(Transfer(amount: Self.u64(data, at: 1), decimals: Int(data[data.startIndex + 9]), isSol: false, destination: account(2)))
                default:
                    ()
                }
            }
        }

        method = isSwap ? .swap : (transfers.isEmpty ? nil : .transfer)
        self.transfers = transfers
    }

    func fields(baseToken: Token) -> [SendField] {
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
            if let destination = transfer.destination {
                fields.append(.recipient(title: "send.confirmation.to".localized, value: destination, copyable: true, blockchainType: baseToken.blockchainType))
            }
        }

        return fields
    }

    private static func u64(_ data: Data, at offset: Int) -> UInt64 {
        data[(data.startIndex + offset) ..< (data.startIndex + offset + 8)].reversed().reduce(0) { $0 << 8 | UInt64($1) }
    }
}
