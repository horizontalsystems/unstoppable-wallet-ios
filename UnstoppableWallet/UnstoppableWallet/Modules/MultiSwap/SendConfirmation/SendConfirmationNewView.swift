import Kingfisher
import MarketKit
import SwiftUI

struct SendConfirmationNewView: View {
    @StateObject var viewModel: SendConfirmationNewViewModel
    @Binding var isParentPresented: Bool

    @State private var feeSettingsPresented = false

    init(sendData: SendDataNew, isParentPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SendConfirmationNewViewModel(sendData: sendData))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            if viewModel.syncing {
                ProgressView()
            } else if let data = viewModel.data {
                dataView(data: data)
            }
        }
        .sheet(isPresented: $feeSettingsPresented) {
            if let transactionService = viewModel.transactionService, let feeToken = viewModel.feeToken {
                transactionService.settingsView(
                    feeData: Binding<FeeData?>(get: { viewModel.data?.feeData }, set: { _ in }),
                    loading: $viewModel.syncing,
                    feeToken: feeToken,
                    currency: viewModel.currency,
                    feeTokenRate: $viewModel.feeTokenRate
                )
            }
        }
        .navigationTitle("send.confirmation.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    feeSettingsPresented = true
                }) {
                    Image("manage_2_20").renderingMode(.template)
                }
                .disabled(viewModel.syncing)
            }
        }
        .onReceive(viewModel.finishSubject) {
            isParentPresented = false
        }
    }

    @ViewBuilder private func dataView(data: ISendConfirmationData) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: .margin16) {
                    let sections = data.sections(feeToken: viewModel.feeToken, currency: viewModel.currency, feeTokenRate: viewModel.feeTokenRate)

                    if !sections.isEmpty {
                        ForEach(sections.indices, id: \.self) { sectionIndex in
                            let section = sections[sectionIndex]

                            if !section.isEmpty {
                                ListSection {
                                    ForEach(section.indices, id: \.self) { index in
                                        fieldRow(field: section[index])
                                    }
                                }
                            }
                        }
                    }

                    let cautions = (viewModel.transactionService?.cautions ?? []) + data.cautions(feeToken: viewModel.feeToken)

                    if !cautions.isEmpty {
                        VStack(spacing: .margin12) {
                            ForEach(cautions.indices, id: \.self) { index in
                                HighlightedTextView(caution: cautions[index])
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }

            Button(action: {
                viewModel.send()
            }) {
                HStack(spacing: .margin8) {
                    if viewModel.sending {
                        ProgressView()
                    }

                    Text(viewModel.sending ? "send.confirmation.sending".localized : "send.confirmation.slide_to_send".localized)
                }
            }
            .disabled(viewModel.sending)
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
            .padding(.vertical, .margin16)
            .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func tokenRow(title: String, token: Token, amount: Decimal, rate: Decimal?) -> some View {
        ListRow {
            KFImage.url(URL(string: token.coin.imageUrl))
                .resizable()
                .placeholder {
                    Circle().fill(Color.themeSteel20)
                }
                .clipShape(Circle())
                .frame(width: .iconSize24, height: .iconSize24)

            VStack(spacing: 1) {
                HStack(spacing: .margin4) {
                    Text(title).textSubhead2(color: .themeLeah)

                    Spacer()

                    if let formatted = ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: token), value: amount)) {
                        Text(formatted).textSubhead1(color: .themeLeah)
                    }
                }

                HStack(spacing: .margin4) {
                    if let protocolName = token.protocolName {
                        Text(protocolName).textCaption()
                    }

                    Spacer()

                    if let rate, let formatted = ValueFormatter.instance.formatFull(currency: viewModel.currency, value: amount * rate) {
                        Text(formatted).textCaption()
                    }
                }
            }
        }
    }

    @ViewBuilder private func fieldRow(field: SendConfirmField) -> some View {
        switch field {
        case let .amount(title, token, coinValue, currencyValue, type):
            ListRow {
                KFImage.url(URL(string: token.coin.imageUrl))
                    .resizable()
                    .placeholder {
                        Circle().fill(Color.themeSteel20)
                    }
                    .clipShape(Circle())
                    .frame(width: .iconSize24, height: .iconSize24)

                VStack(spacing: 1) {
                    HStack(spacing: .margin4) {
                        Text(title).textSubhead2(color: .themeLeah)

                        Spacer()

                        Text(coinValue).textSubhead1(color: .themeLeah)
                    }

                    HStack(spacing: .margin4) {
                        if let protocolName = token.protocolName {
                            Text(protocolName).textCaption()
                        }

                        Spacer()

                        if let currencyValue {
                            Text(currencyValue).textCaption()
                        }
                    }
                }
            }
        case let .value(title, description, coinValue, currencyValue):
            ListRow(padding: EdgeInsets(top: .margin12, leading: description == nil ? .margin16 : 0, bottom: .margin12, trailing: .margin16)) {
                if let description {
                    Text(title)
                        .textSubhead2()
                        .modifier(Informed(description: description))
                } else {
                    Text(title)
                        .textSubhead2()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    if let coinValue {
                        Text(coinValue)
                            .textSubhead1(color: .themeLeah)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("n/a".localized)
                            .textSubhead1()
                            .multilineTextAlignment(.trailing)
                    }

                    if let currencyValue {
                        Text(currencyValue)
                            .textCaption()
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        case let .levelValue(title, value, level):
            ListRow {
                Text(title).textSubhead2()
                Spacer()
                Text(value).textSubhead1(color: color(valueLevel: level))
            }
        case let .address(title, value, _, _):
            ListRow {
                Text(title).textSubhead2()

                Spacer()

                Text(value)
                    .textSubhead1(color: .themeLeah)
                    .multilineTextAlignment(.trailing)

                Button(action: {
                    CopyHelper.copyAndNotify(value: value)
                }) {
                    Image("copy_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            }
        }
    }

    private func color(valueLevel: SendConfirmField.ValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
//        case .notAvailable: return .themeGray50
        case .warning: return .themeJacob
        case .error: return .themeLucian
        }
    }
}
