import Foundation
import MarketKit
import MoneroKit
import RxCocoa
import RxSwift
import ZanoKit
import ZcashLightClientKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let statPage: StatPage
    private let disposeBag = DisposeBag()

    private var enteredHeight: Int?

    init(viewModel: RestoreSettingsViewModel, statPage: StatPage) {
        self.viewModel = viewModel
        self.statPage = statPage

        subscribe(disposeBag, viewModel.openBirthdayAlertSignal) { [weak self] token in
            self?.showBirthdayAlert(blockchain: token.blockchain)
        }
    }

    private func showBirthdayAlert(blockchain: Blockchain) {
        enteredHeight = nil

        guard let provider = BirthdayInputProviderFactory.provider(blockchainType: blockchain.type) else {
            return
        }

        Coordinator.shared.present { _ in
            BirthdayInputView(blockchain: blockchain, provider: provider, onEnterBirthdayHeight: { [weak self] height in
                self?.enteredHeight = height
                self?.viewModel.onEnter(birthdayHeight: height)
            })
        } onDismiss: { [weak self] in
            if self?.enteredHeight == nil {
                self?.viewModel.onCancelEnterBirthdayHeight()
            }
        }

        stat(page: statPage, event: .open(page: .birthdayInput))
    }

    private func birthdayInputProvider(token: Token) -> IBirthdayInputProvider? {
        switch token.blockchainType {
        case .zcash: return ZCashBirthdayInputProvider()
        case .monero: return MoneroBirthdayInputProvider()
        case .zano: return ZanoBirthdayInputProvider()
        default: return nil
        }
    }
}

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
        ZcashAdapter.newBirthdayHeight(network: ZcashNetworkBuilder.network(for: .mainnet))
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
