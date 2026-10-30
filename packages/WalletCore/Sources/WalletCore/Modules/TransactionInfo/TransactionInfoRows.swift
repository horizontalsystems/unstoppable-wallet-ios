import SwiftUI

struct TransactionInfoAmountRow: View {
    let title: String
    let subtitle: String?
    let iconUrl: String?
    let iconAlternativeUrl: String?
    let iconPlaceholderImageName: String
    let coinAmount: String
    let currencyAmount: String?
    let colorStyle: ColorStyle
    let action: (() -> Void)?

    var body: some View {
        Cell(
            left: {
                IconView(url: iconUrl, alternativeUrl: iconAlternativeUrl, placeholderImage: iconPlaceholderImageName, type: .circle, size: .iconSize32)
            },
            middle: {
                MultiText(eyebrow: ComponentText(text: title, colorStyle: .primary), subtitle: subtitle)
            },
            right: {
                RightMultiText(eyebrow: ComponentText(text: coinAmount, colorStyle: colorStyle), subtitle: currencyAmount)
            },
            action: action
        )
    }
}

struct TransactionInfoStatusRow: View {
    let status: TransactionStatus
    let notProcessed: Bool
    let onInfo: () -> Void

    var body: some View {
        Cell(
            middle: {
                MiddleTextIcon(text: "status".localized, icon: "info_filled")
                    .onTapGesture(perform: onInfo)
            },
            right: {
                HStack(spacing: .margin8) {
                    ThemeText(text, style: .subhead, colorStyle: .primary)
                    icon
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(TestTags.txInfoStatus(stateName))
            }
        )
    }

    private var stateName: String {
        switch status {
        case .pending: return "pending"
        case .processing: return "processing"
        case .completed: return "completed"
        case .failed: return notProcessed ? "not_processed" : "failed"
        }
    }

    private var text: String {
        switch status {
        case .pending: return "transactions.pending".localized
        case .processing: return "transactions.processing".localized
        case .completed: return "transactions.completed".localized
        case .failed: return notProcessed ? "transactions.not_processed".localized : "transactions.failed".localized
        }
    }

    @ViewBuilder private var icon: some View {
        switch status {
        case .pending: spinner(progress: 0.2)
        case let .processing(progress): spinner(progress: progress * 0.8 + 0.2)
        case .completed: ThemeImage("done_e_filled_2", size: .iconSize20, colorStyle: .green)
        case .failed: ThemeImage("warning_filled", size: .iconSize20, colorStyle: notProcessed ? .secondary : .red)
        }
    }

    private func spinner(progress: Double) -> some View {
        ProgressView(value: progress)
            .progressViewStyle(DeterminiteSpinnerStyle())
            .frame(width: .iconSize20, height: .iconSize20)
            .spinning()
    }
}

struct TransactionInfoAddressRow: View {
    let title: String
    let value: String
    let contactAddress: ContactAddress?
    let statSection: StatSection

    var body: some View {
        Cell(
            middle: {
                // the title keeps its intrinsic width so a long address wraps on the right instead of squeezing it
                MiddleTextIcon(text: title)
                    .fixedSize(horizontal: true, vertical: false)
            },
            right: {
                HStack(spacing: .margin8) {
                    ThemeText(value, style: .subhead, colorStyle: .primary)
                        .multilineTextAlignment(.trailing)

                    if let contactAddress {
                        IconButton(icon: "user_plus", style: .secondary, size: .small) {
                            ContactBookModule.showAddition(contactAddress: contactAddress, statPage: .transactionInfo, statSection: statSection)
                        }
                    }

                    IconButton(icon: "copy_filled", style: .secondary, size: .small) {
                        CopyHelper.copyAndNotify(value: value)
                        stat(page: .transactionInfo, section: statSection, event: .copy(entity: .address))
                    }
                }
            }
        )
    }
}

struct TransactionInfoNoteRow: View {
    let icon: String
    let text: String
    let showsInfo: Bool
    let action: (() -> Void)?

    var body: some View {
        Cell(
            left: {
                ThemeImage(icon, size: .iconSize24)
            },
            middle: {
                ThemeText(text, style: .subhead)
                    .multilineTextAlignment(.leading)
            },
            right: {
                if showsInfo {
                    ThemeImage("info_filled", size: .iconSize20)
                }
            },
            action: action
        )
    }
}
