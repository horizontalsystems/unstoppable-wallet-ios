import Kingfisher
import MarketKit
import SwiftUI

struct MultiSwapView: View {
    @ObservedObject var viewModel: MultiSwapViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectTokenInPresented = false
    @State private var selectTokenOutPresented = false
    @State private var quotesPresented = false
    @State private var confirmPresented = false
    @State private var settingsPresented = false
    @State private var feeSettingsPresented = false
    @State private var presentedSettingId: String?

    @State private var progress: Double = 0

    @FocusState var isInputActive: Bool

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack {
                    ScrollView {
                        VStack(spacing: .margin12) {
                            VStack(spacing: .margin8) {
                                boxIn().padding(.horizontal, .margin16)
                                boxSeparator()
                                boxOut().padding(.horizontal, .margin16)
                            }
                            .padding(.vertical, 20)
                            .modifier(ThemeListStyleModifier(themeListStyle: .lawrence))

                            Button(action: {
                                confirmPresented = true
                            }) {
                                HStack(spacing: .margin8) {
                                    if viewModel.loading {
                                        ProgressView()
                                    }

                                    Text(viewModel.loading ? "Loading" : "Next")
                                }
                            }
                            .disabled(viewModel.currentQuote == nil || viewModel.loading)
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))

                            if viewModel.currentQuote == nil,
                               let availableBalance = viewModel.availableBalance,
                               let tokenIn = viewModel.tokenIn,
                               let formatted = ValueFormatter.instance.formatShort(coinValue: CoinValue(kind: .token(token: tokenIn), value: availableBalance))
                            {
                                ListSection {
                                    HStack(spacing: .margin8) {
                                        Text("Available Balance").textSubhead2()
                                        Spacer()
                                        Text(formatted).textSubhead2(color: .themeLeah)
                                    }
                                    .frame(height: 40)
                                    .padding(.horizontal, .margin16)
                                }
                                .themeListStyle(.bordered)
                            }

                            if let currentQuote = viewModel.currentQuote {
                                ListSection {
                                    HStack(spacing: .margin8) {
                                        Button(action: {
                                            quotesPresented = true
                                        }) {
                                            HStack(spacing: .margin8) {
                                                Image(currentQuote.provider.icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: .iconSize24, height: .iconSize24)

                                                Text(currentQuote.provider.name).textSubhead1(color: .themeLeah)
                                                Image("arrow_small_down_20").themeIcon(color: .themeGray)
                                            }
                                        }

                                        Spacer()

                                        Button(action: {
                                            settingsPresented = true
                                        }) {
                                            if currentQuote.quote.settingsModified {
                                                Image("manage_2_20").themeIcon(color: .themeJacob)
                                            } else {
                                                Image("manage_2_20").renderingMode(.template)
                                            }
                                        }
                                        .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
                                    }
                                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin12))
                                    .frame(height: 40)
                                    .sheet(isPresented: $settingsPresented) {
                                        currentQuote.provider.settingsView()
                                    }

                                    VStack(spacing: 0) {
                                        if let price = viewModel.price {
                                            HStack(spacing: .margin8) {
                                                Text("Price").textSubhead2()

                                                Spacer()

                                                Button(action: {
                                                    viewModel.flipPrice()
                                                }) {
                                                    HStack(spacing: .margin8) {
                                                        Text(price).textSubhead2(color: .themeLeah)
                                                        Image("arrow_swap_3_20").themeIcon()
                                                    }
                                                }
                                            }
                                            .frame(height: 40)
                                            .padding(.horizontal, .margin16)
                                        }

                                        if let feeQuote = currentQuote.quote.feeQuote,
                                           let feeToken = viewModel.feeToken,
                                           let feeService = viewModel.feeService,
                                           let fee = feeService.fee(quote: feeQuote, token: feeToken),
                                           let formatted = ValueFormatter.instance.formatShort(coinValue: fee)
                                        {
                                            HStack(spacing: .margin8) {
                                                Text("Network Fee")
                                                    .textSubhead2()
                                                    .modifier(Informed(description: .init(title: "Network Fee", description: "Network Fee Description")))

                                                Spacer()

                                                Text(formatted).textSubhead2(color: .themeLeah)

                                                Button(action: {
                                                    feeSettingsPresented = true
                                                }) {
                                                    if feeService.modified {
                                                        Image("edit2_20").themeIcon(color: .themeJacob)
                                                    } else {
                                                        Image("edit2_20").renderingMode(.template)
                                                    }
                                                }
                                                .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
                                            }
                                            .frame(height: 40)
                                            .padding(.leading, .margin16)
                                            .padding(.trailing, .margin12)
                                        }

                                        if !currentQuote.quote.mainFields.isEmpty {
                                            ForEach(currentQuote.quote.mainFields) { (field: MultiSwapMainField) in
                                                HStack(spacing: .margin8) {
                                                    if let description = field.description {
                                                        Text(field.title)
                                                            .textSubhead2()
                                                            .modifier(Informed(description: description))
                                                    } else {
                                                        Text(field.title)
                                                            .textSubhead2()
                                                    }

                                                    Spacer()

                                                    Text(field.value).textSubhead2(color: color(valueLevel: field.valueLevel))

                                                    if let settingId = field.settingId {
                                                        Button(action: {
                                                            presentedSettingId = settingId
                                                        }) {
                                                            if field.modified {
                                                                Image("edit2_20").themeIcon(color: .themeJacob)
                                                            } else {
                                                                Image("edit2_20").renderingMode(.template)
                                                            }
                                                        }
                                                        .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
                                                    }
                                                }
                                                .frame(height: 40)
                                                .padding(.leading, .margin16)
                                                .padding(.trailing, field.settingId == nil ? .margin16 : .margin12)
                                            }
                                        }
                                    }
                                }
                                .themeListStyle(.bordered)
                                .sheet(isPresented: $feeSettingsPresented) {
                                    if let feeService = viewModel.feeService {
                                        feeService.settingsView()
                                    } else {
                                        Text("NO")
                                    }
                                }
                                .sheet(item: $presentedSettingId) { settingId in
                                    if let currentQuote = viewModel.currentQuote {
                                        currentQuote.provider.settingView(settingId: settingId)
                                    } else {
                                        Text("NO")
                                    }
                                }
                            }

                            if viewModel.tokenIn != nil, viewModel.tokenOut != nil, viewModel.amountIn != nil, viewModel.quotes.isEmpty, !viewModel.loading {
                                Text("No Routes Available")
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                        .sheet(isPresented: $quotesPresented) {
                            MultiSwapQuotesView(viewModel: viewModel, isPresented: $quotesPresented)
                        }
                    }

                    NavigationLink(
                        destination: MultiSwapConfirmView(viewModel: viewModel, isPresented: $confirmPresented),
                        isActive: $confirmPresented
                    ) {
                        EmptyView()
                    }
                }
            }
            .navigationTitle("swap.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.quoteTimerActive {
                        CircularProgressView(progress: progress)
                            .onAppear {
                                progress = viewModel.quoteTimeLeft / viewModel.autoRefreshDuration
                                withAnimation(.linear(duration: viewModel.quoteTimeLeft)) {
                                    progress = 0
                                }
                            }
                    } else {
                        EmptyView()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder private func boxIn() -> some View {
        HStack(spacing: .margin8) {
            VStack(spacing: 3) {
                TextField("", text: $viewModel.amountString, prompt: Text("0").foregroundColor(.themeGray))
                    .foregroundColor(.themeLeah)
                    .font(.themeHeadline1)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)

                if viewModel.rateIn != nil {
                    HStack(spacing: 0) {
                        Text(viewModel.currency.symbol).textBody(color: .themeGray)

                        TextField("", text: $viewModel.fiatAmountString, prompt: Text("0").foregroundColor(.themeGray))
                            .foregroundColor(.themeGray)
                            .font(.themeBody)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                    }
                } else {
                    Text("").textBody()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: 0) {
                        if viewModel.availableBalance != nil {
                            ForEach(1 ... 4, id: \.self) { multiplier in
                                let percent = multiplier * 25

                                Button(action: {
                                    viewModel.setAmountIn(percent: percent)
                                }) {
                                    Text("\(percent)%").textSubhead1(color: .themeLeah)
                                }
                                .frame(maxWidth: .infinity)

                                RoundedRectangle(cornerRadius: 0.5, style: .continuous)
                                    .fill(Color.themeSteel20)
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                            }
                        } else {
                            Spacer()
                        }

                        Button(action: {
                            isInputActive = false
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.themeSubhead1)
                                .foregroundColor(.themeLeah)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, -16)
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer()

            selectorButton(token: viewModel.tokenIn) {
                selectTokenInPresented = true
            }
            .sheet(isPresented: $selectTokenInPresented) {
                MultiSwapTokenSelectView(token: $viewModel.tokenIn, isPresented: $selectTokenInPresented)
            }
        }
    }

    @ViewBuilder private func boxSeparator() -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.themeSteel20)
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)

            Button(action: {
                viewModel.interchange()
            }) {
                Image("arrow_medium_2_down_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Rectangle()
                .fill(Color.themeSteel20)
                .frame(height: .heightOneDp)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func boxOut() -> some View {
        HStack(spacing: .margin8) {
            VStack(spacing: 3) {
                if let amountOutString = viewModel.amountOutString {
                    Text(amountOutString)
                        .themeHeadline1(color: .themeLeah, alignment: .leading)
                        .lineLimit(1)
                } else {
                    Text("0").themeHeadline1(color: .themeGray, alignment: .leading)
                }

                Text(viewModel.fiatAmountOut.map { "\(viewModel.currency.symbol)\($0.description)" } ?? "").themeBody(color: .themeGray, alignment: .leading)
            }

            Spacer()

            selectorButton(token: viewModel.tokenOut) {
                selectTokenOutPresented = true
            }
            .sheet(isPresented: $selectTokenOutPresented) {
                MultiSwapTokenSelectView(token: $viewModel.tokenOut, isPresented: $selectTokenOutPresented)
            }
        }
    }

    @ViewBuilder private func selectorButton(token: Token?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .margin8) {
                KFImage.url(token.flatMap { URL(string: $0.coin.imageUrl) })
                    .resizable()
                    .placeholder {
                        Circle().fill(Color.themeSteel20)
                    }
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)

                if let token {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(token.coin.code).textSubhead1(color: .themeLeah)

                        if let protocolName = token.protocolName {
                            Text(protocolName).textMicro()
                        }
                    }
                } else {
                    Text("Select").textSubhead1(color: .themeJacob)
                }

                Image("arrow_small_down_20").themeIcon(color: .themeGray)
            }
        }
    }

    private func color(valueLevel: MultiSwapValueLevel) -> Color {
        switch valueLevel {
        case .regular: return .themeLeah
        case .warning: return .themeJacob
        case .error: return .themeLucian
        }
    }
}
