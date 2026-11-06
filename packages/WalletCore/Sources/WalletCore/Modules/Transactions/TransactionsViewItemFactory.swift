import Foundation
import MarketKit

class TransactionsViewItemFactory {
    private typealias Token = ActivityCellViewItem.Token
    private typealias Value = ActivityCellViewItem.Value
    private typealias ValueType = ActivityCellViewItem.ValueType

    private let evmLabelManager = Core.shared.evmLabelManager
    private let amountRoundingManager = Core.shared.amountRoundingManager
    private let contactLabelService: TransactionsContactLabelService

    init(contactLabelService: TransactionsContactLabelService) {
        self.contactLabelService = contactLabelService
    }

    private func mapped(address: String, blockchainType: BlockchainType) -> String {
        contactLabelService.contactData(for: address, blockchainType: blockchainType).name ?? evmLabelManager.mapped(address: address)
    }

    /// The amount alone: the row's title already names the coin. Nil when it can't be formatted, as a `.raw` value.
    private func formattedCoin(_ appValue: AppValue, signType: ValueFormatter.SignType = .always) -> String? {
        if case .nft = appValue.kind {
            // as `AppValue.formattedFull` writes an NFT count, without the code
            return "\(appValue.value.sign == .plus ? "+" : "")\(appValue.value)"
        }

        return appValue.formattedWith(rounding: amountRoundingManager.useAmountRounding, signType: signType, showCode: false)
    }

    /// The amount alone, or the unknown text when it can't be formatted
    private func coinString(from appValue: AppValue, signType: ValueFormatter.SignType = .always) -> String {
        formattedCoin(appValue, signType: signType) ?? Token.unknownText
    }

    /// A swap's two lines, +out on top and -in below. A side that is missing or can't be formatted reads as the
    /// unknown text, typed as its line, so it takes that line's colour. `outType` is the out line's type: `.secondary`
    /// for a swap paid to another recipient.
    private func swapValues(valueIn: AppValue?, valueOut: AppValue?, outType: ValueType = .incoming) -> (Value, Value) {
        let primaryValue = valueOut.flatMap { valueOut in
            formattedCoin(valueOut).map { Value(text: $0, type: type(value: valueOut, outType)) }
        } ?? Value(text: Token.unknownText, type: outType)

        let secondaryValue = valueIn.flatMap { valueIn in
            formattedCoin(valueIn).map { Value(text: $0, type: type(value: valueIn, .outgoing)) }
        } ?? Value(text: Token.unknownText, type: .outgoing)

        return (primaryValue, secondaryValue)
    }

    private func currencyString(from currencyValue: CurrencyValue) -> String {
        ValueFormatter.instance.formatWith(rounding: amountRoundingManager.useAmountRounding, currencyValue: currencyValue) ?? ""
    }

    private func type(value: AppValue, condition: Bool = true, _ trueType: ValueType, _ falseType: ValueType? = nil) -> ValueType {
        guard !value.zeroValue else {
            return .neutral
        }

        return condition ? trueType : (falseType ?? trueType)
    }

    private func currencySecondaryValue(currencyValue: CurrencyValue?) -> Value? {
        currencyValue.map { Value(text: currencyString(from: $0), type: .secondary) }
    }

    private func singleValueSecondaryValue(value: AppValue, currencyValue: CurrencyValue?) -> Value? {
        switch value.kind {
        case .nft:
            return Value(text: value.name, type: .secondary)
        default:
            return currencySecondaryValue(currencyValue: currencyValue)
        }
    }

    private func incomingValue(_ value: AppValue) -> Value {
        Value(text: coinString(from: value), type: type(value: value, .incoming))
    }

    private func outgoingValue(_ value: AppValue, sentToSelf: Bool = false) -> Value {
        Value(text: coinString(from: value, signType: sentToSelf ? .never : .always), type: type(value: value, condition: sentToSelf, .neutral, .outgoing))
    }

    /// An approval or a trust line: an unlimited amount reads as "∞"
    private func allowanceValues(value: AppValue, currencyValue: CurrencyValue?) -> (Value?, Value?) {
        if value.isMaxValue {
            return (Value(text: "∞", type: .neutral), Value(text: "transactions.value.unlimited".localized, type: .secondary))
        }

        return (Value(text: coinString(from: value, signType: .never), type: .neutral), currencySecondaryValue(currencyValue: currencyValue))
    }

    private func token(value: AppValue) -> Token {
        switch value.kind {
        case .nft:
            return Token(icon: .remote(url: nil, alternativeUrl: nil, placeholder: "placeholder_nft_32", type: .squircle), text: value.name)
        case .raw:
            // an amount with no token to it
            return .unknown
        default:
            return Token(icon: .remote(url: value.coin?.imageUrl, alternativeUrl: value.coin?.image, placeholder: "placeholder_circle", type: .circle), text: value.code)
        }
    }

    private func chainToken(source: TransactionSource, text: String) -> Token {
        Token(icon: .local(name: source.blockchainType.iconPlain32), text: text)
    }

    /// What a contract interaction moved. Exactly one transfer reads as that coin and its amount; none or several
    /// read as the chain, titled `noTransferTitle` or `multipleTitle` (`noTransferTitle` when nil), with no amount.
    private func transfers(
        source: TransactionSource,
        incomingValues: [AppValue],
        outgoingValues: [AppValue],
        currencyValue: CurrencyValue?,
        noTransferTitle: String,
        multipleTitle: String? = nil
    ) -> Transfers {
        let count = incomingValues.count + outgoingValues.count

        if count == 1, let value = incomingValues.first {
            return Transfers(count: count, tokens: [token(value: value)], direction: .incoming, primaryValue: incomingValue(value), secondaryValue: singleValueSecondaryValue(value: value, currencyValue: currencyValue))
        } else if count == 1, let value = outgoingValues.first {
            return Transfers(count: count, tokens: [token(value: value)], direction: .outgoing, primaryValue: outgoingValue(value), secondaryValue: singleValueSecondaryValue(value: value, currencyValue: currencyValue))
        } else {
            return Transfers(count: count, tokens: [chainToken(source: source, text: count == 0 ? noTransferTitle : (multipleTitle ?? noTransferTitle))], direction: nil, primaryValue: nil, secondaryValue: nil)
        }
    }

    /// The completed subtitle of a contract call by its transfers: `noTransferSubtitle` when it moved nothing,
    /// `typeTitle` ("Contract Call", "External Call") for one transfer, "Completed" for several
    private func contractCallSubtitle(transfers: Transfers, typeTitle: String, noTransferSubtitle: String) -> String {
        switch transfers.count {
        case 0: return noTransferSubtitle
        case 1: return typeTitle
        default: return "transactions.completed".localized
        }
    }

    /// In, then out; a side the record does not know reads as the unknown token
    private func swapTokens(valueIn: AppValue?, valueOut: AppValue?) -> [Token] {
        [valueIn.map { token(value: $0) } ?? .unknown, valueOut.map { token(value: $0) } ?? .unknown]
    }

    func viewItem(item: TransactionsViewModel.Item, balanceHidden: Bool) -> TransactionsViewModel.ViewItem {
        let blockchainType = item.record.source.blockchainType
        let fiatValue = currencySecondaryValue(currencyValue: item.currencyValue)

        let kind: Kind
        let tokens: [Token]
        let completedSubtitle: String
        var primaryValue: Value?
        var secondaryValue: Value?
        var doubleSpend = false
        var locked: Bool?

        func sendKind(sentToSelf: Bool) -> Kind {
            sentToSelf ? .sendToSelf : .send
        }

        func sendSubtitle(to: String?, sentToSelf: Bool) -> String {
            if sentToSelf {
                return "transactions.to_yourself".localized
            }

            return to.map { "transactions.to".localized(mapped(address: $0, blockchainType: blockchainType)) } ?? "transactions.to_unknown".localized
        }

        switch item.record {
        case let record as EvmIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = "transactions.from".localized(mapped(address: record.from, blockchainType: blockchainType))
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as EvmOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue)

        case let record as SwapTransactionRecord:
            kind = .swap
            tokens = swapTokens(valueIn: record.valueIn, valueOut: record.valueOut)
            completedSubtitle = mapped(address: record.exchangeAddress, blockchainType: blockchainType)

            (primaryValue, secondaryValue) = swapValues(valueIn: record.valueIn, valueOut: record.valueOut, outType: record.recipient != nil ? .secondary : .incoming)

        case let record as UnknownSwapTransactionRecord:
            kind = .swap
            tokens = swapTokens(valueIn: record.valueIn, valueOut: record.valueOut)
            completedSubtitle = mapped(address: record.exchangeAddress, blockchainType: blockchainType)

            (primaryValue, secondaryValue) = swapValues(valueIn: record.valueIn, valueOut: record.valueOut)

        case let record as ApproveTransactionRecord:
            kind = .approve
            tokens = [token(value: record.value)]
            completedSubtitle = "transactions.approve".localized
            (primaryValue, secondaryValue) = allowanceValues(value: record.value, currencyValue: item.currencyValue)

        case let record as ContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues
            let moved = transfers(
                source: record.source,
                incomingValues: incomingValues,
                outgoingValues: outgoingValues,
                currencyValue: item.currencyValue,
                noTransferTitle: record.method ?? "transactions.contract_call".localized,
                multipleTitle: "transactions.contract_call".localized
            )

            kind = .contract(direction: moved.direction)
            tokens = moved.tokens
            completedSubtitle = contractCallSubtitle(transfers: moved, typeTitle: "transactions.contract_call".localized, noTransferSubtitle: mapped(address: record.contractAddress, blockchainType: blockchainType))
            (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)

        case let record as ExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues
            // a single transfer someone else's call delivered reads as a plain receive
            let isReceive = record.outgoingEvents.isEmpty && incomingValues.count == 1 && outgoingValues.isEmpty
            let moved = transfers(
                source: record.source,
                incomingValues: incomingValues,
                outgoingValues: outgoingValues,
                currencyValue: item.currencyValue,
                noTransferTitle: "transactions.external_call".localized
            )

            if isReceive {
                kind = .receive
                completedSubtitle = externalReceiveSubtitle(addresses: record.incomingEvents.map(\.address), blockchainType: blockchainType)
            } else {
                kind = .contract(direction: moved.direction)
                completedSubtitle = contractCallSubtitle(transfers: moved, typeTitle: "transactions.external_call".localized, noTransferSubtitle: "transactions.to_unknown".localized)
            }

            tokens = moved.tokens
            (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)

        case let record as ContractCreationTransactionRecord:
            kind = .contract(direction: nil)
            tokens = [chainToken(source: record.source, text: "transactions.contract_creation".localized)]
            completedSubtitle = "transactions.to_unknown".localized

        case let record as BitcoinIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = receiveSubtitle(from: record.from, to: record.to, blockchainType: blockchainType)
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

            doubleSpend = record.conflictingHash != nil
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as BitcoinOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = fiatValue

            doubleSpend = record.conflictingHash != nil
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as MoneroIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = receiveSubtitle(from: record.from, to: record.to, blockchainType: blockchainType)
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as MoneroOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = fiatValue

        case let record as ZanoIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = receiveSubtitle(from: record.from, to: record.to, blockchainType: blockchainType)
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as ZanoOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = fiatValue

        case let record as TronIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = "transactions.from".localized(mapped(address: record.from, blockchainType: blockchainType))
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as TronOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue)

        case let record as TronApproveTransactionRecord:
            kind = .approve
            tokens = [token(value: record.value)]
            completedSubtitle = "transactions.approve".localized
            (primaryValue, secondaryValue) = allowanceValues(value: record.value, currencyValue: item.currencyValue)

        case let record as TronContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues
            let moved = transfers(
                source: record.source,
                incomingValues: incomingValues,
                outgoingValues: outgoingValues,
                currencyValue: item.currencyValue,
                noTransferTitle: record.method ?? "transactions.contract_call".localized,
                multipleTitle: "transactions.contract_call".localized
            )

            kind = .contract(direction: moved.direction)
            tokens = moved.tokens
            completedSubtitle = contractCallSubtitle(transfers: moved, typeTitle: "transactions.contract_call".localized, noTransferSubtitle: mapped(address: record.contractAddress, blockchainType: blockchainType))
            (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)

        case let record as TronExternalContractCallTransactionRecord:
            let (incomingValues, outgoingValues) = record.combinedValues
            // a single transfer someone else's call delivered reads as a plain receive
            let isReceive = record.outgoingEvents.isEmpty && incomingValues.count == 1 && outgoingValues.isEmpty
            let moved = transfers(
                source: record.source,
                incomingValues: incomingValues,
                outgoingValues: outgoingValues,
                currencyValue: item.currencyValue,
                noTransferTitle: "transactions.external_call".localized
            )

            if isReceive {
                kind = .receive
                completedSubtitle = externalReceiveSubtitle(addresses: record.incomingEvents.map(\.address), blockchainType: blockchainType)
            } else {
                kind = .contract(direction: moved.direction)
                completedSubtitle = contractCallSubtitle(transfers: moved, typeTitle: "transactions.external_call".localized, noTransferSubtitle: "transactions.to_unknown".localized)
            }

            tokens = moved.tokens
            (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)

        case let record as TronTransactionRecord:
            kind = .unknown
            tokens = [chainToken(source: record.source, text: record.transaction.contract?.label ?? "transactions.unknown_transaction.title".localized)]
            completedSubtitle = "transactions.unknown_transaction.description".localized()

        case let record as ThorChainIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = record.from.flatMap { "transactions.from".localized(mapped(address: $0, blockchainType: blockchainType)) } ?? "transactions.from_unknown".localized
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as ThorChainOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = fiatValue

        case let record as ThorChainTransactionRecord:
            kind = .contract(direction: nil)
            tokens = [chainToken(source: record.source, text: record.transaction.type.capitalized)]
            completedSubtitle = record.transaction.memo.flatMap { $0.isEmpty ? nil : $0 } ?? "transactions.unknown_transaction.description".localized()

        case let record as TonTransactionRecord:
            if record.actions.count == 1, let action = record.actions.first {
                switch action.type {
                case let .send(value, to, sentToSelf, _):
                    kind = sendKind(sentToSelf: sentToSelf)
                    tokens = [token(value: value)]
                    completedSubtitle = sendSubtitle(to: to, sentToSelf: sentToSelf)
                    primaryValue = outgoingValue(value, sentToSelf: sentToSelf)
                    secondaryValue = fiatValue
                case let .receive(value, from, _):
                    kind = .receive
                    tokens = [token(value: value)]
                    completedSubtitle = "transactions.from".localized(mapped(address: from, blockchainType: blockchainType))
                    primaryValue = incomingValue(value)
                    secondaryValue = fiatValue
                case let .burn(value):
                    kind = .contract(direction: .outgoing)
                    tokens = [token(value: value)]
                    completedSubtitle = "transactions.burn".localized
                    primaryValue = outgoingValue(value)
                    secondaryValue = fiatValue
                case let .mint(value):
                    kind = .contract(direction: .incoming)
                    tokens = [token(value: value)]
                    completedSubtitle = "transactions.mint".localized
                    primaryValue = incomingValue(value)
                    secondaryValue = fiatValue
                case let .swap(routerName, routerAddress, valueIn, valueOut):
                    kind = .swap
                    tokens = swapTokens(valueIn: valueIn, valueOut: valueOut)
                    completedSubtitle = routerName ?? routerAddress.shortened
                    (primaryValue, secondaryValue) = swapValues(valueIn: valueIn, valueOut: valueOut)
                case let .contractDeploy(interfaces):
                    kind = .contract(direction: nil)
                    tokens = [chainToken(source: record.source, text: "transactions.contract_deploy".localized)]
                    completedSubtitle = interfaces.joined(separator: ", ")
                case let .contractCall(_, value, _):
                    kind = .contract(direction: .outgoing)
                    tokens = [token(value: value)]
                    completedSubtitle = "transactions.contract_call".localized
                    primaryValue = outgoingValue(value)
                    secondaryValue = fiatValue
                case let .unsupported(type):
                    kind = .contract(direction: nil)
                    tokens = [chainToken(source: record.source, text: "transactions.ton_transaction.title".localized)]
                    completedSubtitle = type
                }
            } else {
                kind = .contract(direction: nil)
                tokens = [chainToken(source: record.source, text: "transactions.ton_transaction.title".localized)]
                completedSubtitle = "transactions.multiple".localized
            }

        case let record as StellarTransactionRecord:
            switch record.type {
            case let .accountCreated(startingBalance, _):
                kind = .contract(direction: .incoming)
                tokens = [token(value: startingBalance)]
                completedSubtitle = "transactions.account_created".localized
                primaryValue = incomingValue(startingBalance)
                secondaryValue = fiatValue
            case let .accountFunded(startingBalance, _):
                kind = .contract(direction: .outgoing)
                tokens = [token(value: startingBalance)]
                completedSubtitle = "transactions.account_created".localized
                primaryValue = outgoingValue(startingBalance)
                secondaryValue = fiatValue
            case let .sendPayment(value, to, sentToSelf):
                kind = sendKind(sentToSelf: sentToSelf)
                tokens = [token(value: value)]
                completedSubtitle = sendSubtitle(to: to, sentToSelf: sentToSelf)
                primaryValue = outgoingValue(value, sentToSelf: sentToSelf)
                secondaryValue = fiatValue
            case let .receivePayment(value, from):
                kind = .receive
                tokens = [token(value: value)]
                completedSubtitle = "transactions.from".localized(mapped(address: from, blockchainType: blockchainType))
                primaryValue = incomingValue(value)
                secondaryValue = fiatValue
            case let .swap(valueIn, valueOut):
                kind = .swap
                tokens = swapTokens(valueIn: valueIn, valueOut: valueOut)
                completedSubtitle = "transactions.swap".localized
                (primaryValue, secondaryValue) = swapValues(valueIn: valueIn, valueOut: valueOut)
            case let .changeTrust(value, _, _, _):
                kind = .contract(direction: nil)
                tokens = [token(value: value)]
                completedSubtitle = "transactions.change_trust".localized
                (primaryValue, secondaryValue) = allowanceValues(value: value, currencyValue: item.currencyValue)
            case let .unsupported(type):
                kind = .contract(direction: nil)
                tokens = [chainToken(source: record.source, text: "transactions.stellar_transaction.title".localized)]
                completedSubtitle = type
            }

        case let record as XrpTransactionRecord:
            switch record.type {
            case let .send(value, to, sentToSelf):
                kind = sendKind(sentToSelf: sentToSelf)
                tokens = [token(value: value)]
                completedSubtitle = sendSubtitle(to: to, sentToSelf: sentToSelf)
                primaryValue = outgoingValue(value, sentToSelf: sentToSelf)
                secondaryValue = fiatValue
            case let .receive(value, from):
                kind = .receive
                tokens = [token(value: value)]
                completedSubtitle = "transactions.from".localized(mapped(address: from, blockchainType: blockchainType))
                primaryValue = incomingValue(value)
                secondaryValue = fiatValue
            case let .trustSet(value, issuer):
                kind = .contract(direction: nil)
                tokens = [token(value: value)]
                completedSubtitle = mapped(address: issuer, blockchainType: blockchainType)
                // the default limit means "no cap", as the Stellar unlimited trustline
                (primaryValue, secondaryValue) = allowanceValues(value: value, currencyValue: item.currencyValue)
            case let .unsupported(type):
                kind = .contract(direction: nil)
                tokens = [chainToken(source: record.source, text: "transactions.xrp_transaction.title".localized)]
                completedSubtitle = type
            }

        case let record as NearTransactionRecord:
            switch record.type {
            case let .send(value, to, sentToSelf, _):
                kind = sendKind(sentToSelf: sentToSelf)
                tokens = [token(value: value)]
                completedSubtitle = sendSubtitle(to: to, sentToSelf: sentToSelf)
                primaryValue = outgoingValue(value, sentToSelf: sentToSelf)
                secondaryValue = fiatValue
            case let .receive(value, from, _):
                kind = .receive
                tokens = [token(value: value)]
                completedSubtitle = "transactions.from".localized(mapped(address: from, blockchainType: blockchainType))
                primaryValue = incomingValue(value)
                secondaryValue = fiatValue
            case let .contractCall(contractId, method, incoming, outgoing):
                // a swap or a wrap lists each asset it moved, as an EVM contract call does
                let incomingValues = incoming.map(\.value)
                let outgoingValues = outgoing.map(\.value)
                let moved = transfers(
                    source: record.source,
                    incomingValues: incomingValues,
                    outgoingValues: outgoingValues,
                    currencyValue: item.currencyValue,
                    noTransferTitle: method ?? "transactions.contract_call".localized,
                    multipleTitle: "transactions.contract_call".localized
                )

                kind = .contract(direction: moved.direction)
                tokens = moved.tokens
                completedSubtitle = contractCallSubtitle(transfers: moved, typeTitle: "transactions.contract_call".localized, noTransferSubtitle: method.map { "\($0) · \(contractId.shortened)" } ?? contractId.shortened)
                (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)
            }

        case let record as ZcashShieldingTransactionRecord:
            switch record.direction {
            case .shield:
                kind = .shield
                completedSubtitle = "transactions.shielded".localized
            case .unshield:
                kind = .unshield
                completedSubtitle = "transactions.unshielded".localized
            case .migrate:
                kind = .migrate
                completedSubtitle = "transactions.migrate.to_ironwood".localized
            }

            tokens = [token(value: record.value)]
            primaryValue = Value(text: coinString(from: record.value, signType: .never), type: .neutral)
            secondaryValue = fiatValue

            doubleSpend = record.conflictingHash != nil
            if let lockState = item.transactionItem.lockState {
                locked = lockState.locked
            }

        case let record as SolanaIncomingTransactionRecord:
            kind = .receive
            tokens = [token(value: record.value)]
            completedSubtitle = record.from.flatMap { "transactions.from".localized(mapped(address: $0, blockchainType: blockchainType)) } ?? "transactions.from_unknown".localized
            primaryValue = incomingValue(record.value)
            secondaryValue = fiatValue

        case let record as SolanaOutgoingTransactionRecord:
            kind = sendKind(sentToSelf: record.sentToSelf)
            tokens = [token(value: record.value)]
            completedSubtitle = sendSubtitle(to: record.to, sentToSelf: record.sentToSelf)
            primaryValue = outgoingValue(record.value, sentToSelf: record.sentToSelf)
            secondaryValue = singleValueSecondaryValue(value: record.value, currencyValue: item.currencyValue)

        case let record as SolanaSwapTransactionRecord:
            kind = .swap
            tokens = swapTokens(valueIn: record.valueIn, valueOut: record.valueOut)
            completedSubtitle = record.exchangeName

            (primaryValue, secondaryValue) = swapValues(valueIn: record.valueIn, valueOut: record.valueOut)

        case let record as SolanaUnknownTransactionRecord:
            let incomingValues = record.incomingTransfers.map(\.value)
            let outgoingValues = record.outgoingTransfers.map(\.value)

            let moved = transfers(
                source: record.source,
                incomingValues: incomingValues,
                outgoingValues: outgoingValues,
                currencyValue: item.currencyValue,
                noTransferTitle: "transactions.unknown_transaction.title".localized
            )

            kind = .unknown
            tokens = moved.tokens
            completedSubtitle = "transactions.unknown_transaction.description".localized()
            (primaryValue, secondaryValue) = (moved.primaryValue, moved.secondaryValue)

        default:
            kind = .unknown
            tokens = [chainToken(source: item.record.source, text: "transactions.unknown_transaction.title".localized)]
            completedSubtitle = "transactions.unknown_transaction.description".localized()
        }

        let state: ActivityCellViewItem.State
        let subtitle: String

        switch item.transactionItem.status {
        case .pending, .processing:
            state = .pending
            subtitle = kind.pendingText

        case .failed:
            state = .failed
            subtitle = kind.failedText

        case .completed:
            state = .completed
            subtitle = completedSubtitle
        }

        // a row with no amount stays empty
        if balanceHidden, primaryValue != nil || secondaryValue != nil {
            primaryValue = Value(text: BalanceHiddenManager.placeholder, type: primaryValue?.type ?? .neutral)
            secondaryValue = Value(text: BalanceHiddenManager.placeholder, type: secondaryValue?.type ?? .neutral)
        }

        return TransactionsViewModel.ViewItem(
            id: item.viewItemId,
            uid: item.record.uid,
            date: item.record.date,
            cell: ActivityCellViewItem(
                glyph: kind.glyph,
                state: state,
                tokens: tokens,
                subtitle: subtitle,
                primaryValue: primaryValue,
                secondaryValue: secondaryValue,
                doubleSpend: doubleSpend,
                locked: locked,
                dimmed: item.record.spam
            )
        )
    }

    private func receiveSubtitle(from: String?, to: String?, blockchainType: BlockchainType) -> String {
        if let from {
            return "transactions.from".localized(mapped(address: from, blockchainType: blockchainType))
        } else if let to {
            return "transactions.to".localized(mapped(address: to, blockchainType: blockchainType))
        } else {
            return "transactions.from_unknown".localized
        }
    }

    private func externalReceiveSubtitle(addresses: [String], blockchainType: BlockchainType) -> String {
        let addresses = Array(Set(addresses))

        if addresses.count == 1 {
            return "transactions.from".localized(mapped(address: addresses[0], blockchainType: blockchainType))
        } else {
            return "transactions.multiple".localized
        }
    }
}

extension TransactionsViewItemFactory {
    private struct Transfers {
        let count: Int
        let tokens: [Token]
        /// set for exactly one transfer
        let direction: ValueType?
        let primaryValue: Value?
        let secondaryValue: Value?
    }

    /// The glyph of a row and the subtitles it shows while pending and once failed
    private struct Kind {
        let glyph: String
        let pendingText: String
        let failedText: String

        static var receive: Kind {
            Kind(glyph: "arrow_m_down", pendingText: "transactions.pending.receiving".localized, failedText: "transactions.failed.transfer".localized)
        }

        static var send: Kind {
            Kind(glyph: "arrow_m_up", pendingText: "transactions.pending.sending".localized, failedText: "transactions.failed.transfer".localized)
        }

        static var sendToSelf: Kind {
            Kind(glyph: "arrow_return", pendingText: "transactions.pending.sending".localized, failedText: "transactions.failed.transfer".localized)
        }

        static var approve: Kind {
            Kind(glyph: "unlock", pendingText: "transactions.pending.approving".localized, failedText: "transactions.failed.approval".localized)
        }

        static var shield: Kind {
            Kind(glyph: "shield", pendingText: "transactions.pending.shielding".localized, failedText: "transactions.failed.shielding".localized)
        }

        static var unshield: Kind {
            Kind(glyph: "shield_off", pendingText: "transactions.pending.unshielding".localized, failedText: "transactions.failed.unshielding".localized)
        }

        static var migrate: Kind {
            Kind(glyph: "arrow_out", pendingText: "transactions.pending.sending".localized, failedText: "transactions.failed.transfer".localized)
        }

        static var swap: Kind {
            Kind(glyph: "swap_e", pendingText: "transactions.pending.swapping".localized, failedText: "transactions.failed.swap".localized)
        }

        static var unknown: Kind {
            Kind(glyph: "warning", pendingText: "transactions.pending.generic".localized, failedText: "transactions.failed.transaction".localized)
        }

        /// A contract interaction; one that moved a single value reads as a transfer in that direction
        static func contract(direction: ValueType?) -> Kind {
            let pendingText: String
            let failedText: String

            switch direction {
            case .incoming:
                pendingText = "transactions.pending.receiving".localized
                failedText = "transactions.failed.transfer".localized
            case .outgoing:
                pendingText = "transactions.pending.sending".localized
                failedText = "transactions.failed.transfer".localized
            default:
                pendingText = "transactions.pending.generic".localized
                failedText = "transactions.failed.transaction".localized
            }

            return Kind(glyph: "list", pendingText: pendingText, failedText: failedText)
        }
    }
}
