import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class SendEvmHandler {
    let coinServiceFactory: EvmCoinServiceFactory
    let transactionData: TransactionData
    let evmKitWrapper: EvmKitWrapper
    let evmLabelManager = App.shared.evmLabelManager
    let contactLabelService: ContactLabelService

    init(coinServiceFactory: EvmCoinServiceFactory, transactionData: TransactionData, evmKitWrapper: EvmKitWrapper, contactLabelService: ContactLabelService) {
        self.coinServiceFactory = coinServiceFactory
        self.transactionData = transactionData
        self.evmKitWrapper = evmKitWrapper
        self.contactLabelService = contactLabelService
    }
}

extension SendEvmHandler: ISendHandler {
    var blockchainType: BlockchainType {
        evmKitWrapper.blockchainType
    }

    func confirmationData(transactionSettings: TransactionSettings?) async throws -> ISendConfirmationData {
        let decoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)

        let gasPrice = transactionSettings?.gasPrice
        var gasLimit: Int?
        var transactionError: Error?

        if let gasPrice {
            do {
                gasLimit = try await evmKitWrapper.evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {
                transactionError = error
            }
        }

        let sections = decoration.map { self.sections(decoration: $0, nonce: transactionSettings?.nonce) } ?? []

        return ConfirmationData(baseSections: sections, gasPrice: gasPrice, gasLimit: gasLimit, transactionError: transactionError)
    }

    func send(data _: ISendConfirmationData) async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }

    private func sections(decoration: TransactionDecoration?, nonce: Int?) -> [[SendConfirmField]] {
        switch decoration {
        case let decoration as ApproveEip20Decoration:
            return eip20ApproveItems(
                spender: decoration.spender,
                value: decoration.value,
                contractAddress: decoration.contractAddress,
                nonce: nonce
            )
        default:
            return []
        }
    }

    private func eip20ApproveItems(spender: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address, nonce: Int?) -> [[SendConfirmField]] {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return []
        }

        var sections = [[SendConfirmField]]()

        let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance

        let amountField: SendConfirmField

        if isRevokeAllowance {
            amountField = .amount(
                title: "approve.confirmation.you_revoke".localized,
                token: coinService.token,
                coinValue: coinService.token.coin.code,
                currencyValue: nil,
                type: .neutral
            )
        } else {
            amountField = self.amountField(
                coinService: coinService,
                title: "approve.confirmation.you_approve".localized,
                value: value,
                type: .neutral
            )
        }

        sections.append([amountField])

        let addressValue = spender.eip55
        let addressTitle = evmLabelManager.addressLabel(address: addressValue)
        let contactData = contactLabelService.contactData(for: addressValue)

        var fields: [SendConfirmField] = [
            .address(
                title: "approve.confirmation.spender".localized,
                value: addressValue,
                valueTitle: addressTitle,
                contactAddress: contactData.contactAddress
            ),
        ]

        if let contactName = contactData.name {
            fields.append(.levelValue(title: "send.confirmation.contact_name".localized, value: contactName, level: .regular))
        }

        if let nonce {
            fields.append(.levelValue(title: "send.confirmation.nonce".localized, value: nonce.description, level: .regular))
        }

        sections.append(fields)

        return sections

//        if let section = dAppSection(additionalInfo: additionalInfo) {
//            sections.append(section)
//        }
    }

    private func amountField(coinService: CoinService, title: String, value: BigUInt, type: SendConfirmField.AmountType) -> SendConfirmField {
        amountField(coinService: coinService, title: title, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountField(coinService: CoinService, title: String, amountData: AmountData, type: SendConfirmField.AmountType) -> SendConfirmField {
        let token = coinService.token
        let value = amountData.coinValue

        return .amount(
            title: title,
            token: token,
            coinValue: value.isMaxValue ? value.infinity : value.formattedFull ?? "n/a".localized,
            currencyValue: value.isMaxValue ? nil : amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
            type: type
        )
    }
}

extension SendEvmHandler {
    struct ConfirmationData: ISendConfirmationData {
        let baseSections: [[SendConfirmField]]
        let gasPrice: GasPrice?
        let gasLimit: Int?
        let transactionError: Error?

        var feeData: FeeData? {
            gasLimit.map {
                .evm(gasLimit: $0)
            }
        }

        var canSend: Bool {
            gasLimit != nil
        }

        func cautions(feeToken _: Token?) -> [CautionNew] {
            []
        }

        func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
            var sections = baseSections

            if let feeToken {
                let feeData = feeData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

                sections.append(
                    [
                        .value(
                            title: "Network Fee",
                            description: .init(title: "Network Fee", description: "Network Fee Description"),
                            coinValue: (feeData?.coinValue).flatMap { ValueFormatter.instance.formatShort(coinValue: $0) },
                            currencyValue: (feeData?.currencyValue).flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) }
                        ),
                    ]
                )
            }

            return sections
        }

        private func feeData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let gasPrice, let gasLimit else {
                return nil
            }

            let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)
            let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

            return AmountData(coinValue: coinValue, currencyValue: currencyValue)
        }
    }
}

extension SendEvmHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData) -> SendEvmHandler? {
        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: blockchainType,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            return nil
        }

        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: blockchainType)

        return SendEvmHandler(
            coinServiceFactory: coinServiceFactory,
            transactionData: transactionData,
            evmKitWrapper: evmKitWrapper,
            contactLabelService: contactLabelService
        )
    }
}
