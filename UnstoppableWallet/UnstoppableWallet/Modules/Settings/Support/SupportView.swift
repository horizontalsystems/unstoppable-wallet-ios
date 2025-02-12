
import Chart
import MarketKit
import SwiftUI

struct SupportView: View {
    @StateObject private var viewModel: SupportViewModel

    @Environment(\.dismiss) private var dismiss

    init(onReceiveGroup: @escaping (String) -> Void) {
        _viewModel = StateObject(wrappedValue: SupportViewModel(onReceiveGroup: onReceiveGroup))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("support_2_24").themeIcon(color: .themeJacob)
                Text("purchases.vip_support").textHeadline2()

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)

            Image("premium_support")
                .padding(.vertical, .margin24)

            Text("settings.vip_support.description".localized)
                .multilineTextAlignment(.leading)
                .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin32, trailing: .margin32))

            Button(action: {
                viewModel.onFetchChat()
            }) {
                HStack(spacing: .margin8) {
                    if viewModel.buttonState == .loading {
                        ProgressView()
                    }
                    Text("settings.vip_support.start_chat".localized)
                }
            }
            .disabled(viewModel.buttonState == .loading)
            .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
            .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
        .background(Color.themeLawrence)
        .onReceive(viewModel.$isPresented) { newValue in
            if !newValue {
                dismiss()
            }
        }
    }
}
