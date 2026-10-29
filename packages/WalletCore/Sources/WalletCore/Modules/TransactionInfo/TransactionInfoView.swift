import MarketKit
import SwiftUI

struct TransactionInfoView: View {
    @StateObject private var viewModel: TransactionInfoViewModel
    @Binding private var isPresented: Bool

    init(viewModel: TransactionInfoViewModel, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _isPresented = isPresented
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin16) {
                ForEach(viewModel.sections.indices, id: \.self) { index in
                    sectionView(viewModel.sections[index])
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("tx_info.title".localized)
        .closeNavigation(isPresented: $isPresented)
    }

    @ViewBuilder private func sectionView(_ section: TransactionInfoModule.SectionViewItem) -> some View {
        if section.viewItems.count == 1, case let .warning(text) = section.viewItems[0] {
            AlertCardView(AlertCardViewItem(text: text, type: .caution, style: .structured))
        } else {
            ListSection(footer: section.footer) {
                ForEach(section.viewItems.indices, id: \.self) { index in
                    rowView(section.viewItems[index])
                }
            }
        }
    }

    @ViewBuilder private func rowView(_ viewItem: TransactionInfoModule.ViewItem) -> some View {
        switch viewItem {
        case let .actionTitle(iconName, iconDimmed, title, subTitle):
            Cell(
                left: {
                    if let iconName {
                        ThemeImage(iconName, size: .iconSize24, colorStyle: iconDimmed ? .secondary : .primary)
                    }
                },
                middle: {
                    ThemeText(title, style: .body)
                },
                right: {
                    if let subTitle, !subTitle.isEmpty {
                        RightMultiText(subtitle: ComponentText(text: subTitle, colorStyle: .primary))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            )
        case let .amount(title, subtitle, iconUrl, iconAlternativeUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type, coin):
            TransactionInfoAmountRow(
                title: title,
                subtitle: subtitle,
                iconUrl: iconUrl,
                iconAlternativeUrl: iconAlternativeUrl,
                iconPlaceholderImageName: iconPlaceholderImageName,
                coinAmount: coinAmount,
                currencyAmount: currencyAmount,
                colorStyle: type.colorStyle,
                action: coinAction(coin)
            )
        case let .status(status, notProcessed):
            TransactionInfoStatusRow(status: status, notProcessed: notProcessed, onInfo: openStatusInfo)
        case let .option(option):
            optionRow(option: option)
        case let .date(date):
            SimpleValueField(title: "tx_info.date".localized, value: DateHelper.instance.formatFullTime(from: date), isPrimary: true).listRow()
        case let .from(value, _, contactAddress):
            TransactionInfoAddressRow(title: "tx_info.from_hash".localized, value: value, contactAddress: contactAddress, statSection: .addressFrom)
        case let .to(value, _, contactAddress):
            TransactionInfoAddressRow(title: "tx_info.to_hash".localized, value: value, contactAddress: contactAddress, statSection: .addressTo)
        case let .spender(value, _, contactAddress):
            TransactionInfoAddressRow(title: "tx_info.spender".localized, value: value, contactAddress: contactAddress, statSection: .addressSpender)
        case let .recipient(value, _, contactAddress):
            TransactionInfoAddressRow(title: "tx_info.recipient_hash".localized, value: value, contactAddress: contactAddress, statSection: .addressRecipient)
        case let .contactName(name):
            SimpleValueField(title: "tx_info.contact_name".localized, value: name, isPrimary: true).listRow()
        case let .id(value):
            Cell(
                middle: {
                    MiddleTextIcon(text: "tx_info.transaction_id".localized)
                },
                right: {
                    HStack(spacing: .margin8) {
                        RightButtonText(text: ComponentText(text: value.shortened, colorStyle: .primary), textStyle: .subhead, icon: "copy_filled") {
                            CopyHelper.copyAndNotify(value: value)
                            stat(page: .transactionInfo, event: .copy(entity: .transactionId))
                        }

                        IconButton(icon: "share", style: .secondary, size: .small) {
                            Coordinator.shared.present { _ in
                                ActivityView(activityItems: [value])
                            }
                            stat(page: .transactionInfo, event: .share(entity: .transactionId))
                        }
                    }
                }
            )
        case let .rate(value):
            SimpleValueField(title: "tx_info.rate".localized, value: value, isPrimary: true).listRow()
        case let .fee(title, value):
            SimpleValueField(title: title, value: value, isPrimary: true).listRow()
        case let .price(price):
            Cell(
                middle: {
                    MiddleTextIcon(text: "tx_info.price".localized)
                },
                right: {
                    RightButtonText(text: ComponentText(text: price, colorStyle: .primary), textStyle: .subhead, icon: "swap_e") {
                        viewModel.togglePrice()
                    }
                }
            )
        case let .doubleSpend(txHash, conflictingTxHash):
            TransactionInfoNoteRow(icon: "double_send", text: "tx_info.double_spent_note".localized, showsInfo: true) {
                openDoubleSpend(transactionHash: txHash, conflictingTransactionHash: conflictingTxHash)
            }
        case let .lockInfo(lockState):
            let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

            TransactionInfoNoteRow(
                icon: lockState.locked ? "lock_filled" : "unlock_filled",
                text: lockState.locked ? "tx_info.locked_until".localized(formattedDate) : "tx_info.unlocked_at".localized(formattedDate),
                showsInfo: lockState.locked,
                action: lockState.locked ? openLockInfo : nil
            )
        case .sentToSelf:
            TransactionInfoNoteRow(icon: "arrow_return", text: "tx_info.to_self_note".localized, showsInfo: false, action: nil)
        case .rawTransaction:
            Cell(
                middle: {
                    MiddleTextIcon(text: "tx_info.raw_transaction".localized)
                },
                right: {
                    IconButton(icon: "copy_filled", style: .secondary, size: .small) {
                        if let rawTransaction = viewModel.rawTransaction {
                            CopyHelper.copyAndNotify(value: rawTransaction)
                        }
                    }
                }
            )
        case let .memo(text):
            Cell(
                middle: {
                    MiddleTextIcon(text: "tx_info.memo".localized)
                        .fixedSize(horizontal: true, vertical: false)
                },
                right: {
                    ThemeText(text, style: .subheadI, colorStyle: .primary)
                        .multilineTextAlignment(.trailing)
                }
            )
        case let .txSecretKey(text):
            Cell(
                middle: {
                    MiddleTextIcon(text: "tx_info.tx_secret_key".localized)
                        .fixedSize(horizontal: true, vertical: false)
                },
                right: {
                    RightButtonText(text: ComponentText(text: text, colorStyle: .primary), textStyle: .subheadI, icon: "copy_filled") {
                        CopyHelper.copyAndNotify(value: text)
                    }
                }
            )
        case let .service(value):
            SimpleValueField(title: "tx_info.service".localized, value: value, isPrimary: true).listRow()
        case let .value(title, value):
            SimpleValueField(title: title, value: value, isPrimary: true).listRow()
        case let .explorer(title, url):
            Cell(
                left: {
                    ThemeImage("globe", size: .iconSize24)
                },
                middle: {
                    ThemeText(title, style: .body)
                },
                right: {
                    ThemeImage("arrow_b_right", size: .iconSize20)
                },
                action: {
                    openExplorer(url: url)
                }
            )
        case let .warning(text):
            AlertCardView(AlertCardViewItem(text: text, type: .caution, style: .structured))
        }
    }

    private func optionRow(option: TransactionInfoModule.Option) -> some View {
        let item = optionItem(option: option)

        return Cell(
            left: {
                ThemeImage(item.icon, size: .iconSize24, colorStyle: item.colorStyle)
            },
            middle: {
                ThemeText(item.title, style: .body, colorStyle: item.colorStyle)
            },
            action: item.action
        )
    }

    private func optionItem(option: TransactionInfoModule.Option) -> (icon: String, title: String, colorStyle: ColorStyle, action: () -> Void) {
        switch option {
        case let .resend(type):
            let action = { viewModel.resend(type: type) }

            switch type {
            case .speedUp: return ("arrow_m_up", "tx_info.options.speed_up".localized, .yellow, action)
            case .cancel: return ("outgoingraw", "tx_info.options.cancel".localized, .red, action)
            }
        case .zcashResend:
            return ("arrow_m_up", "button.resend".localized, .yellow, { viewModel.zcashResend() })
        }
    }

    private func coinAction(_ coin: Coin?) -> (() -> Void)? {
        guard let coin else {
            return nil
        }

        return { Coordinator.shared.presentCoinPage(coin: coin, page: .transactionInfo) }
    }

    private func openStatusInfo() {
        InfoModule.present(viewItems: InfoModule.transactionStatusInfo)

        stat(page: .transactionInfo, section: .status, event: .open(page: .info))
    }

    private func openLockInfo() {
        InfoModule.present(viewItems: InfoModule.timeLockInfo)

        stat(page: .transactionInfo, section: .timeLock, event: .open(page: .info))
    }

    private func openDoubleSpend(transactionHash: String, conflictingTransactionHash: String) {
        Coordinator.shared.present { isPresented in
            DoubleSpendInfoView(transactionHash: transactionHash, conflictingTransactionHash: conflictingTransactionHash, isPresented: isPresented)
        }

        stat(page: .transactionInfo, event: .open(page: .doubleSpend))
    }

    private func openExplorer(url: String?) {
        guard let urlString = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else {
            return
        }

        Coordinator.shared.present(url: url)

        stat(page: .transactionInfo, event: .open(page: .externalBlockExplorer))
    }
}
