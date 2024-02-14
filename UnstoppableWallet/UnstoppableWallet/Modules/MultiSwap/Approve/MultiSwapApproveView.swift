import Foundation
import SwiftUI

struct MultiSwapApproveView: View {
    @ObservedObject var viewModel: MultiSwapApproveViewModel

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin32) {
                    VStack(spacing: .margin24) {
                        Text("Allow access to the following amount".localized)
                            .themeHeadline1()
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                        Text("You should grant permission to a smart contract to swap given token on your behalf. This permission sets amount that can be used by a smart contract. It doesn't affect your balance but requires a small fee to execute approval transaction.\n\nWhile it may be done on demand before each trade, it's cheaper to approve higher amount in advance for future trades.")
                            .themeSubhead2()
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
                    }

                    ListSection {
                        ClickableRow(action: {
                            viewModel.set(infinity: false)
                        }) {
                            row(text: viewModel.amountString, selected: !$viewModel.useInfinity)
                        }
                        ClickableRow(action: {
                            viewModel.set(infinity: true)
                        }) {
                            row(text: "Unlimited", selected: $viewModel.useInfinity)
                        }
                    }

                    if let status = viewModel.status {
                        HighlightedTextView(text: status, style: .yellow)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                Button(action: {
                    viewModel.onApprove()
                }) {
                    Text("button.unlock".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!viewModel.unlockEnabled)
            }
        }
        .navigationTitle("confirm".localized)
        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                KFImage.url(URL(string: viewModel.iconUrl))
//                    .resizable()
//                    .frame(width: .iconSize24, height: .iconSize24)
//            }
//
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("button.cancel".localized) {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            }
//        }
    }

    @ViewBuilder func row(text: String, selected: Binding<Bool>) -> some View {
        HStack(spacing: .margin16) {
            Image("check_2_20")
                .themeIcon(color: .themeJacob)
                .opacity(selected.wrappedValue ? 1 : 0)
                .frame(width: .iconSize20, height: .iconSize20, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                        .stroke(Color.themeGray, lineWidth: .heightOneDp + .heightOnePixel)
                )

            Text(text).themeSubhead2(color: .themeLeah)
        }
    }
}
