import MessageUI
import SwiftUI

struct SwapRequestRefundBottomSheetView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel: SwapRequestRefundViewModel
    @State private var mailPresented = false
    @State private var mailRecipient = ""

    init(swap: Swap, isPresented: Binding<Bool>) {
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: SwapRequestRefundViewModel(swap: swap))
    }

    var body: some View {
        BottomSheetView(items: items)
            .sheet(isPresented: $mailPresented) {
                MailView(
                    recipient: mailRecipient,
                    subject: viewModel.details.emailSubject,
                    body: viewModel.details.emailBody,
                    isPresented: $mailPresented
                )
            }
    }

    private var items: [BSModule.Item] {
        var items: [BSModule.Item] = [
            .title(icon: "warning_filled", title: "swap_info.request_refund".localized),
            .text(text: "swap_info.request_refund.description".localized),
            .list(items: [
                .init(title: "swap_info.swap_id".localized, value: viewModel.details.swapIdShort),
                .init(title: "swap_info.amount".localized, value: viewModel.details.amount),
                .init(title: "swap_info.refund_address".localized, value: viewModel.details.refundAddressShort),
            ]),
        ]

        if !viewModel.contactLinks.isEmpty {
            items.append(.custom(view: AnyView(contactList)))
        }

        items.append(.buttonGroup(.init(buttons: [
            .init(style: .yellow, title: "swap_info.copy_details".localized) {
                viewModel.copyBody()
            },
        ])))

        return items
    }

    private var contactList: some View {
        ListSection {
            ForEach(viewModel.contactLinks) { link in
                contactRow(link: link)
            }
        }
        .themeListStyle(.bordered)
        .padding(.horizontal, .margin16)
        .padding(.top, .margin8)
    }

    private func contactRow(link: SwapRequestRefundBuilder.ContactLink) -> some View {
        Cell(
            style: .primary,
            left: {
                Image(link.icon)
                    .themeIcon()
            },
            middle: {
                MultiText(title: link.label, subtitle: link.value)
            },
            right: {
                ThemeImage("arrow_b_right", size: .iconSize20)
            },
            action: {
                handle(link: link)
            }
        )
    }

    private func handle(link: SwapRequestRefundBuilder.ContactLink) {
        switch link.type {
        case .email:
            if MFMailComposeViewController.canSendMail() {
                mailRecipient = link.rawValue
                mailPresented = true
            } else {
                viewModel.open(contactLink: link)
            }
        case .telegram, .twitter, .website:
            viewModel.open(contactLink: link)
        }
    }
}
