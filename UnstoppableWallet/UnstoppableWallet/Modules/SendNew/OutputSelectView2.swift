import SwiftUI

struct OutputSelectorView2: View {
    @StateObject var viewModel: OutputSelectorViewModel2

    @Environment(\.presentationMode) private var presentationMode

    init(handler: BitcoinPreSendHandler) {
        _viewModel = StateObject(wrappedValue: OutputSelectorViewModel2(handler: handler))
    }

    var body: some View {
        ThemeView {
            VStack {
                ListSection {
                    ListRow(minHeight: .heightDoubleLineCell) {
                        HStack(spacing: .margin8) {
                            VStack(spacing: 1) {
                                Text("send.available_balance".localized).themeSubhead2(color: .themeGray)
                            }

                            Spacer()

                            VStack(spacing: 1) {
                                Text(viewModel.availableBalanceCoinValue).themeSubhead1(color: .themeLeah, alignment: .trailing)
                                if let subtitle = viewModel.availableBalanceFiatValue {
                                    Text(subtitle).themeSubhead2(alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))

                ScrollView {
                    ListSection {
                        ForEach(viewModel.outputsViewItems) { viewItem in
                            output(viewItem: viewItem)
                        }
                    }
                    .themeListStyle(.transparent)
                }

                HorizontalDivider(color: .themeSteel10, height: .heightOneDp)

                HStack {
                    Button(action: {
                        viewModel.unselectAll()
                    }) {
                        Text("send.unselect_all".localized).themeBody(color: viewModel.selectedSet.isEmpty ? .themeGray50 : .themeJacob)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.selectAll()
                    }) {
                        Text("send.select_all".localized).themeBody(color: viewModel.allSelected ? .themeGray50 : .themeJacob, alignment: .trailing)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: CGFloat(43), trailing: .margin16))
            }
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.resetEnabled)
    }

    @ViewBuilder func output(viewItem: OutputSelectorViewModel2.OutputViewItem) -> some View {
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
                    Text(viewItem.coinValue).themeBody(alignment: .trailing)
                    if let subtitle = viewItem.fiatValue {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }
}
