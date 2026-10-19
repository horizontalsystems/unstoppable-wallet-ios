import MarketKit
import SwiftUI

// Offers to divide a large swap across several routes when that gives more of the receive token
struct MultiRouteSwapBottomSheetView: View {
    let plan: MultiRouteSwapPlan
    let tokenOut: Token
    @Binding var isPresented: Bool
    // Record the choice only; the caller acts on it once the sheet has been dismissed
    let onUseSplit: () -> Void
    let onKeepSingle: () -> Void

    var body: some View {
        BottomSheetView(items: items)
    }

    private var items: [BSModule.Item] {
        var items: [BSModule.Item] = [.title(title: "swap.multi_route.title".localized)]

        if let formattedGain = AppValue(token: tokenOut, value: plan.gain).formattedFull() {
            items.append(.custom(view: AnyView(gainView(formattedGain: formattedGain))))
        }

        items.append(contentsOf: [
            .text(text: "swap.multi_route.description".localized(plan.routeCount)),
            .customList(views: [AnyView(detailsView)]),
            .buttonGroup(.init(buttons: [
                .init(style: .yellow, title: "swap.multi_route.use_split".localized) {
                    onUseSplit()
                    isPresented = false
                },
                .init(style: .gray, title: "swap.multi_route.keep_single".localized) {
                    onKeepSingle()
                    isPresented = false
                },
            ])),
        ])

        return items
    }

    private func gainView(formattedGain: String) -> some View {
        ThemeText("+" + formattedGain, style: .headline1, colorStyle: .green)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, .margin32)
            .padding(.top, .margin16)
    }

    private var detailsView: some View {
        VStack(spacing: 0) {
            Cell(
                style: .secondary,
                middle: {
                    ThemeText("swap.multi_route.you_receive".localized, style: .subhead, colorStyle: .primary)
                },
                right: {
                    ThemeText(AppValue(token: tokenOut, value: plan.totalAmountOut).formattedFull() ?? "", style: .subheadSB, colorStyle: .primary)
                        .multilineTextAlignment(.trailing)
                }
            )

            Cell(
                style: .secondary,
                middle: {
                    HStack(spacing: .margin8) {
                        ThemeText("swap.provider.score".localized, style: .subhead, colorStyle: .secondary)
                        Image("information").icon(size: .iconSize20, colorStyle: .secondary)
                    }
                },
                right: {
                    MultiSwapQuotesView.view(type: plan.worstProviderType)
                },
                action: {
                    // stacks on top of this sheet; closing it returns here
                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                        MultiSwapProviderTypeBottomSheet(isPresented: isPresented)
                    }
                }
            )

            if let timeState = MultiSwapViewModel.timeState(for: plan.longestEstimatedTime, precise: plan.preciseEstimateTime, baseline: nil) {
                Cell(
                    style: .secondary,
                    middle: {
                        HStack(spacing: .margin8) {
                            ThemeText("swap.swapped_time".localized, style: .subhead, colorStyle: .secondary)
                            Image("information").icon(size: .iconSize20, colorStyle: .secondary)
                        }
                    },
                    right: {
                        MultiSwapQuotesView.view(time: timeState.value, colorStyle: timeState.colorStyle)
                    },
                    action: {
                        Coordinator.shared.present(info: .swapTime)
                    }
                )
            }
        }
        .padding(.vertical, .margin8)
    }
}
