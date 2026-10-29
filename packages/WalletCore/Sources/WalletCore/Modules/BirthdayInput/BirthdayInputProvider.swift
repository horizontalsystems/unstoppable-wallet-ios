import Foundation
import MarketKit
import MoneroKit
import ZanoKit
import ZODLSwiftWalletSDK

protocol IBirthdayInputProvider {
    var lastBlockHeight: Int { get }
    func height(date: Date) -> Int
    func date(height: Int) -> Date
}

enum BirthdayInputProviderFactory {
    static func provider(blockchainType: BlockchainType) -> IBirthdayInputProvider? {
        switch blockchainType {
        case .zcash: return ZCashBirthdayInputProvider()
        case .monero: return MoneroBirthdayInputProvider()
        case .zano: return ZanoBirthdayInputProvider()
        default: return nil
        }
    }
}

class ZCashBirthdayInputProvider: IBirthdayInputProvider {
    var lastBlockHeight: Int {
        ZcashAdapter.newBirthdayHeight(network: ZcashNetworkBuilder.network(for: ZcashAdapter.networkType))
    }

    func height(date: Date) -> Int {
        ZcashAdapter.estimateBirthdayHeight(date: date)
    }

    func date(height: Int) -> Date {
        Date(timeIntervalSince1970: .init(ZcashAdapter.estimateBirthdayTime(for: height)))
    }
}

class MoneroBirthdayInputProvider: IBirthdayInputProvider {
    var lastBlockHeight: Int {
        height(date: Date())
    }

    func height(date: Date) -> Int {
        Int(MoneroKit.RestoreHeight.getHeight(date: date))
    }

    func date(height: Int) -> Date {
        MoneroKit.RestoreHeight.getDate(height: Int64(height))
    }
}

class ZanoBirthdayInputProvider: IBirthdayInputProvider {
    var lastBlockHeight: Int {
        height(date: Date())
    }

    func height(date: Date) -> Int {
        Int(ZanoKit.RestoreHeight.getHeight(date: date))
    }

    func date(height: Int) -> Date {
        ZanoKit.RestoreHeight.getDate(height: Int64(height))
    }
}
