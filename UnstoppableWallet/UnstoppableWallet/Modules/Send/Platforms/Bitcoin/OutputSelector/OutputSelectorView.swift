import SwiftUI

struct OutputSelectorView: View {
    @ObservedObject var amountViewModel: AmountOutputSelectorViewModel
    @ObservedObject var addressViewModel: AddressOutputSelectorViewModel
    @ObservedObject var feeViewModel: SendFeeViewModel
    @ObservedObject var viewModel: OutputSelectorViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin16) {
                    ListSection {
                        ListRow(minHeight: .heightDoubleLineCell) {
                            amount(subtitle: addressViewModel.address, viewItem: amountViewModel.viewItem)
                        }
                        ListRow(minHeight: .heightDoubleLineCell) {
                            fee(value: feeViewModel.value, spinnerVisible: feeViewModel.spinnerVisible)
                        }
                        if let changeViewItem = viewModel.changeViewItem {
                            ListRow(minHeight: .heightDoubleLineCell) {
                                change(viewItem: changeViewItem)
                            }
                        }
                    }
                    .themeListStyle(.borderedLawrence)

                    ListSection {
                        ForEach(viewModel.outputsViewItems) { viewItem in
                            output(viewItem: viewItem)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
                }
                .animation(.easeInOut, value: viewModel.changeViewItem)
                .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
            } bottomContent: {
                Button(action: {
                    viewModel.onTapDone()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(viewModel.buttonText)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!viewModel.doneEnabled)
            }
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.resetEnabled)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.reset()
                }
                .disabled(!viewModel.resetEnabled)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.doneEnabled)
            }
        }
    }

    @ViewBuilder func amount(subtitle: String?, viewItem: AmountOutputSelectorViewModel.ViewItem?) -> some View {
        HStack(spacing: .margin8) {
            VStack(spacing: 1) {
                Text("send.unspent_outputs.send_to".localized).themeBody()
                if let subtitle {
                    Text(subtitle).themeSubhead2()
                }
            }

            if let viewItem {
                Spacer()

                VStack(spacing: 1) {
                    Text(viewItem.title).themeBody(color: .themeJacob, alignment: .trailing)
                    if let subtitle = viewItem.subtitle {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder func fee(value: FeeCell.Value?, spinnerVisible: Bool) -> some View {
        HStack(spacing: .margin8) {
            Text("send.fee".localized).textBody()

            Spacer()

            if spinnerVisible {
                ProgressView().progressViewStyle(.circular)
            } else {
                switch value {
                case .none: EmptyView()
                case let .regular(text, secondaryText):
                    VStack(spacing: 1) {
                        Text(text).themeBody(alignment: .trailing)
                        if let secondaryText {
                            Text(secondaryText).themeSubhead2(alignment: .trailing)
                        }
                    }
                case let .error(text): Text(text).themeBody(color: .themeLucian, alignment: .trailing)
                case let .disabled(text): Text(text).themeBody(color: .gray, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder func change(viewItem: OutputSelectorViewModel.ChangeViewItem?) -> some View {
        if let viewItem {
            HStack(spacing: .margin8) {
                VStack(spacing: 1) {
                    Text("send.unspent_outputs.change".localized).themeBody()
                    Text(viewItem.address).themeSubhead2()
                }
                Spacer()

                VStack(spacing: 1) {
                    Text(viewItem.title).themeBody(alignment: .trailing)
                    if let subtitle = viewItem.subtitle {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder func output(viewItem: OutputSelectorViewModel.OutputViewItem) -> some View {
        ClickableRow(action: {
            viewModel.toggle(viewItem: viewItem)
        }) {
            HStack(spacing: .margin16) {
                Image("check_2_20")
                    .themeIcon(color: .themeJacob)
                    .opacity(viewModel.selectedSet.contains(viewItem.id) ? 1 : 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                            .stroke(Color.themeGray, lineWidth: .heightOneDp + .heightOnePixel)
                    )

                VStack(spacing: 1) {
                    Text(viewItem.date).themeBody()
                    Text(viewItem.address).themeSubhead2()
                }
                Spacer()

                VStack(spacing: 1) {
                    Text(viewItem.primary).themeBody(alignment: .trailing)
                    if let subtitle = viewItem.secondary {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }
}
