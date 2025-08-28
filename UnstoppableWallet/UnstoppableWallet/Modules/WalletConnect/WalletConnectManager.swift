import Combine
import EvmKit
import Foundation
import StellarKit
import Web3Wallet

class WalletConnectManager {
    private let timeOut = 5

    private let walletConnectSessionManager: WalletConnectSessionManager

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    @Published private(set) var isWaitingForSession = false

    private var errorSubject = PassthroughSubject<Error, Never>()

    init(walletConnectSessionManager: WalletConnectSessionManager) {
        self.walletConnectSessionManager = walletConnectSessionManager

        Web3Wallet.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                self?.didReceive(sessionProposal: sessionProposal.proposal)
            }.store(in: &cancellables)
    }

    func pair(url: String) {
        Task { [weak self] in
            switch WalletConnectUriHelper.uriVersion(uri: url) {
            case 2:
                do {
                    try await WalletConnectUriHelper.pair(uri: url)
                    self?.pairedSuccessful()
                } catch {
                    self?.errorSubject.send(error)
                }
            default: self?.errorSubject.send(WalletConnectUriHelper.ConnectionError.wrongUri)
            }
        }
    }

    private func pairedSuccessful() {
        isWaitingForSession = true

        timerCancellable = Just(())
            .delay(for: .seconds(timeOut), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.timeoutReached()
            }
    }

    private func didReceive(sessionProposal _: Session.Proposal) {
        proposalReceived()
    }

    private func timeoutReached() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isWaitingForSession = false
        errorSubject.send(WalletConnectUriHelper.ConnectionError.walletConnectDontRespond)
    }

    func proposalReceived() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isWaitingForSession = false
    }
}

extension WalletConnectManager {
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
}

extension WalletConnectManager {
    static func evmAddress(account: Account, chain: Chain) throws -> EvmKit.Address {
        if let mnemonicSeed = account.type.mnemonicSeed {
            return try Signer.address(seed: mnemonicSeed, chain: chain)
        }
        if case let .evmPrivateKey(data) = account.type {
            return Signer.address(privateKey: data)
        }
        if case let .evmAddress(address) = account.type {
            return address
        }
        throw AdapterError.unsupportedAccount
    }

    static func stellarAddress(account: Account) throws -> String {
        try StellarKitManager.accountId(accountType: account.type)
    }
}
