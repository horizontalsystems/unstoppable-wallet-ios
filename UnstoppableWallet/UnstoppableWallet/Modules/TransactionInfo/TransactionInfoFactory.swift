// import MarketKit

// class TransactionInfoFactory {
//     private func type(appValue: AppValue, condition: Bool = true, _ trueType: TransactionField.AmountType, _ falseType: TransactionField.AmountType? = nil) -> TransactionField.AmountType {
//         guard !appValue.zeroValue else {
//             return .neutral
//         }

//         return condition ? trueType : (falseType ?? trueType)
//     }

//     private func rate(rateValue: CurrencyValue?, code: String) -> TransactionField? {
//         guard let rateValue, let formattedValue = ValueFormatter.instance.formatFull(currencyValue: rateValue) else {
//             return nil
//         }

//         return .levelValue(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, code), level: .regular)
//     }

//     private func nftAmount(appValue: AppValue, type: TransactionField.AmountType, metadata: NftAssetBriefMetadata?, hidden: Bool) -> TransactionField {
//         .nftAmount(
//             iconUrl: metadata?.previewImageUrl,
//             iconPlaceholderImageName: "placeholder_nft_32",
//             nftAmount: hidden ? BalanceHiddenManager.placeholder : appValue.formattedFull(signType: type.signType) ?? "n/a".localized,
//             type: type,
//             providerCollectionUid: metadata?.providerCollectionUid,
//             nftUid: metadata?.nftUid
//         )
//     }

//     private func receiveFields(blockchainType: BlockchainType, appValue: AppValue, from: String?, rates: [Coin: CurrencyValue], mint: Bool = false, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], memo: String? = nil, status: TransactionStatus? = nil, hidden: Bool) -> [TransactionField] {
//         var fields = [TransactionField]()

//         var rateField: TransactionField?

//         switch appValue.kind {
//         case let .nft(nftUid, tokenName, _):
//             fields.append(
//                 .actionTitle(
//                     iconName: "arrow_medium_2_down_left_24",
//                     iconDimmed: true,
//                     title: mint ? "transactions.mint".localized : "transactions.receive".localized,
//                     subTitle: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
//                 )
//             )

//             fields.append(
//                 nftAmount(
//                     appValue: appValue,
//                     type: type(appValue: appValue, .incoming),
//                     metadata: nftMetadata[nftUid],
//                     hidden: hidden
//                 )
//             )
//         default:
//             let rateValue = appValue.coin.flatMap { rates[$0] }

//             fields.append(
//                 .amount(
//                     title: mint ? "transactions.mint".localized : "transactions.receive".localized,
//                     appValue: appValue,
//                     rateValue: rateValue,
//                     type: type(appValue: appValue, .incoming),
//                     hidden: hidden
//                 )
//             )

//             rateField = rate(rateValue: rateValue, code: appValue.code)
//         }

//         if !mint, let from {
//             fields.append(.address(title: "tx_info.from_hash".localized, value: from, blockchainType: blockchainType))
//         }

//         if let rateField {
//             fields.append(rateField)
//         }

//         if let memo {
//             fields.append(.memo(text: memo))
//         }

//         if let status {
//             fields.append(.status(status: status))
//         }

//         return fields
//     }

//     private func sendFields(blockchainType: BlockchainType, appValue: AppValue, to: String?, rates: [Coin: CurrencyValue], burn: Bool = false, nftMetadata: [NftUid: NftAssetBriefMetadata] = [:], sentToSelf: Bool = false, hidden: Bool) -> [TransactionField] {
//         var fields = [TransactionField]()

//         var rateField: TransactionField?

//         switch appValue.kind {
//         case let .nft(nftUid, tokenName, _):
//             fields.append(
//                 .actionTitle(
//                     iconName: burn ? "flame_24" : "arrow_medium_2_up_right_24",
//                     iconDimmed: true,
//                     title: burn ? "transactions.burn".localized : "transactions.send".localized,
//                     subTitle: nftMetadata[nftUid]?.name ?? tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
//                 )
//             )

//             fields.append(
//                 nftAmount(
//                     appValue: appValue,
//                     type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
//                     metadata: nftMetadata[nftUid],
//                     hidden: hidden
//                 )
//             )
//         default:
//             let rateValue = appValue.coin.flatMap { rates[$0] }

//             fields.append(
//                 .amount(
//                     title: burn ? "transactions.burn".localized : "transactions.send".localized,
//                     appValue: appValue,
//                     rateValue: rateValue,
//                     type: type(appValue: appValue, condition: sentToSelf, .neutral, .outgoing),
//                     hidden: hidden
//                 )
//             )

//             rateField = rate(rateValue: rateValue, code: appValue.code)
//         }

//         if !burn, let to {
//             fields.append(.address(title: "tx_info.to_hash".localized, value: to, blockchainType: blockchainType))
//         }

//         if let rateField {
//             fields.append(rateField)
//         }

//         return fields
//     }

//     private func feeString(appValue: AppValue, rate: CurrencyValue?) -> String {
//         var parts = [String]()

//         if let formattedCoinValue = appValue.formattedFull() {
//             parts.append(formattedCoinValue)
//         }

//         if let rate {
//             if let formattedCurrencyValue = ValueFormatter.instance.formatFull(currency: rate.currency, value: rate.value * appValue.value) {
//                 parts.append(formattedCurrencyValue)
//             }
//         }

//         return parts.joined(separator: " | ")
//     }

//     private func bitcoinFields(record: BitcoinTransactionRecord, lastBlockInfo _: LastBlockInfo?) -> [TransactionField] {
//         var fields = [TransactionField]()

//         // if record.showRawTransaction {
//         //     fields.append(.rawTransaction)
//         // }
//         // if let conflictingHash = record.conflictingHash {
//         //     fields.append(.doubleSpend(txHash: record.transactionHash, conflictingTxHash: conflictingHash))
//         // }
//         // if let lockState = record.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp) {
//         //     fields.append(.lockInfo(lockState: lockState))
//         // }
//         if let memo = record.memo {
//             fields.append(.memo(text: memo))
//         }

//         return fields
//     }

//     private func sentToSelfField() -> TransactionField {
//         .note(imageName: "arrow_return_24", text: "tx_info.to_self_note".localized)
//     }
// }

// extension TransactionInfoFactory {
//     func sections(
//         record: TransactionRecord,
//         lastBlockInfo: LastBlockInfo?,
//         rates: [Coin: CurrencyValue],
//         nftMetadata _: [NftUid: NftAssetBriefMetadata],
//         explorerTitle: String,
//         explorerUrl: String?,
//         balanceHidden: Bool
//     ) -> [TransactionRecord.Section] {
//         func _rate(_ value: AppValue) -> CurrencyValue? {
//             value.coin.flatMap { rates[$0] }
//         }

//         var feeField: TransactionField?
//         let status = record.status(lastBlockHeight: lastBlockInfo?.height)

//         var sections = [TransactionRecord.Section]()

//         if record.spam {
//             sections.append(.init(fields: [.warning(text: "tx_info.scam_warning".localized)]))
//         }

//         switch record {
//         case let record as BitcoinIncomingTransactionRecord:
//             sections.append(.init(fields: receiveFields(blockchainType: record.source.blockchainType, appValue: record.value, from: record.from, rates: rates, hidden: balanceHidden)))

//             let additionalFields = bitcoinFields(record: record, lastBlockInfo: lastBlockInfo)
//             if !additionalFields.isEmpty {
//                 sections.append(.init(fields: additionalFields))
//             }

//         case let record as BitcoinOutgoingTransactionRecord:
//             sections.append(.init(fields: sendFields(blockchainType: record.source.blockchainType, appValue: record.value, to: record.to, rates: rates, sentToSelf: record.sentToSelf, hidden: balanceHidden)))

//             var additionalFields = bitcoinFields(record: record, lastBlockInfo: lastBlockInfo)

//             if record.sentToSelf {
//                 additionalFields.insert(sentToSelfField(), at: 0)
//             }

//             if !additionalFields.isEmpty {
//                 sections.append(.init(fields: additionalFields))
//             }

//             if let fee = record.fee {
//                 feeField = .levelValue(title: "tx_info.fee".localized, value: feeString(appValue: fee, rate: _rate(fee)), level: .regular)
//             }

//             if record.source.blockchainType.resendable, record.replaceable {
//                 sections.append(.init(
//                     fields: [
//                         // .option(option: .resend(type: .speedUp)),
//                         // .option(option: .resend(type: .cancel)),
//                     ],
//                     footer: "tx_info.resend_description".localized
//                 ))
//             }

//         default: ()
//         }

//         var transactionFields: [TransactionField] = [
//             .date(date: record.date),
//             .status(status: status),
//         ]

//         if let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, let appValue = evmRecord.fee {
//             let title: String

//             switch status {
//             case .pending: title = "tx_info.fee.estimated".localized
//             case .processing, .failed, .completed: title = "tx_info.fee".localized
//             }

//             feeField = .levelValue(title: title, value: feeString(appValue: appValue, rate: _rate(appValue)), level: .regular)
//         }

//         if let tronRecord = record as? TronTransactionRecord, tronRecord.ownTransaction, let appValue = tronRecord.fee {
//             let title: String
//             switch status {
//             case .pending: title = "tx_info.fee.estimated".localized
//             case .processing, .failed, .completed: title = "tx_info.fee".localized
//             }

//             feeField = .levelValue(title: title, value: feeString(appValue: appValue, rate: _rate(appValue)), level: .regular)
//         }

//         if let feeField {
//             transactionFields.append(feeField)
//         }

//         transactionFields.append(.id(value: record.transactionHash))

//         sections.append(.init(fields: transactionFields))

//         // if actionEnabled, let evmRecord = record as? EvmTransactionRecord, evmRecord.ownTransaction, status.isPending {
//         //     sections.append(.init([
//         //         .option(option: .resend(type: .speedUp)),
//         //         .option(option: .resend(type: .cancel)),
//         //     ], footer: "tx_info.resend_description".localized))
//         // }

//         sections.append(.init(fields: [
//             .explorer(title: "tx_info.view_on".localized(explorerTitle), url: explorerUrl),
//         ]))

//         return sections
//     }
// }
