import SwiftUI

struct SwapInfoView: View {
    @StateObject var viewModel: SwapInfoViewModel

    init(swap: Swap) {
        _viewModel = StateObject(wrappedValue: SwapInfoViewModel(swap: swap))
    }

    var body: some View {
        ThemeView {
            if viewModel.swap.status == .actionRequired {
                BottomGradientWrapper {
                    content
                } bottomContent: {
                    requestRefundButton
                }
            } else {
                content
            }
        }
        .navigationTitle("swap_info.title".localized)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                viewModel.sections.sectionViews

                if !viewModel.legs.isEmpty {
                    transactionStatusView
                }

                if viewModel.swap.status == .actionRequired {
                    AlertCardView(.init(
                        title: "swap_info.swap_stopped_by_provider".localized,
                        text: "swap_info.swap_stopped_by_provider.description".localized,
                        type: .critical,
                        style: .structured
                    ))
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
        }
    }

    private var transactionStatusView: some View {
        VStack(spacing: 0) {
            ThemeText("swap_info.status".localized, style: .subheadSB, colorStyle: .secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

            ListSection {
                VStack(spacing: 0) {
                    ForEach(viewModel.legs.indices, id: \.self) { index in
                        let leg = viewModel.legs[index]

                        HStack(spacing: 8) {
                            HStack(spacing: 16) {
                                legStatusIcon(leg: leg, index: index)
                                    .frame(width: 24, height: 40)

                                ThemeText(leg.title, style: .subhead, colorStyle: leg.status == .notStarted ? .secondary : .primary)
                            }

                            Spacer()

                            if leg.url != nil {
                                HStack(spacing: 12) {
                                    ThemeText("swap_info.view".localized, style: .subhead, colorStyle: .secondary)
                                    ThemeImage("arrow_b_right", size: 20)
                                }
                            }
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            Coordinator.shared.present(url: leg.url)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func legStatusIcon(leg: SwapInfoViewModel.Leg, index: Int) -> some View {
        ZStack {
            VStack(spacing: 0) {
                let color = leg.status == .completed || leg.status == .refunded ? Color.themeRemus : Color.themeBlade

                if index != 0 {
                    Rectangle()
                        .fill(color)
                        .frame(width: 2, height: 10)
                } else {
                    Spacer().frame(height: 10)
                }

                Spacer().frame(height: 20)

                if index != viewModel.legs.count - 1 {
                    Rectangle()
                        .fill(color)
                        .frame(width: 2, height: 10)
                } else {
                    Spacer().frame(height: 10)
                }
            }

            if leg.status != .completed {
                Circle()
                    .fill(Color.themeBlade)
                    .frame(width: 20, height: 20)
            }

            switch leg.status {
            case .completed, .refunded: ThemeImage("done_e_filled_2", size: 20, colorStyle: .green)
            case .failed: ThemeImage("close", size: 20, colorStyle: .red)
            case .pending, .swapping: ProgressView(value: 0.55)
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(width: 20, height: 20)
                .spinning()
            default: EmptyView()
            }
        }
    }

    private var requestRefundButton: some View {
        ThemeButton(text: "swap_info.request_refund".localized, spinner: viewModel.requestRefundLoading) {
            showRequestRefund()
        }
        .disabled(viewModel.requestRefundLoading)
    }

    private func showRequestRefund() {
        guard !viewModel.requestRefundLoading else {
            return
        }

        Task {
            await viewModel.preloadRefundContacts()
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                SwapRequestRefundBottomSheetView(swap: viewModel.swap, isPresented: isPresented)
            }
        }
    }
}
