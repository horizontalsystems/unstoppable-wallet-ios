import Combine
import Foundation
import MarketKit
import MoneroKit
import NearKit
import ZanoKit
import ZcashLightClientKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let statPage: StatPage
    private var cancellables: [AnyCancellable] = []

    private var enteredHeight: Int?
    private var nearAccountEntered = false

    init(viewModel: RestoreSettingsViewModel, statPage: StatPage) {
        self.viewModel = viewModel
        self.statPage = statPage

        viewModel.openBirthdayAlertPublisher.sink { [weak self] token in
            self?.showBirthdayAlert(blockchain: token.blockchain)
        }.store(in: &cancellables)

        viewModel.openNearAccountPublisher.sink { [weak self] accountType in
            self?.showNearAccount(accountType: accountType)
        }.store(in: &cancellables)
    }

    // the choice is a mainnet setting; testnet always opens the implicit account
    private func showNearAccount(accountType: AccountType) {
        nearAccountEntered = false

        guard Core.shared.nearKitManager.network == .mainNet, let seed = accountType.mnemonicSeed, let publicKey = try? NearKit.Signer.publicKey(seed: seed) else {
            viewModel.onEnter(settings: [:])
            return
        }

        Coordinator.shared.present { isPresented in
            NearAccountPickerView(publicKey: publicKey, isPresented: isPresented, onSelect: { [weak self] accountId in
                self?.nearAccountEntered = true
                self?.viewModel.onEnter(settings: [.nearAccountId: accountId])
            }, onUseDefault: { [weak self] in
                self?.nearAccountEntered = true
                self?.viewModel.onEnter(settings: [:])
            })
        } onDismiss: { [weak self] in
            if self?.nearAccountEntered == false {
                self?.viewModel.onCancelEnterBirthdayHeight()
            }
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
