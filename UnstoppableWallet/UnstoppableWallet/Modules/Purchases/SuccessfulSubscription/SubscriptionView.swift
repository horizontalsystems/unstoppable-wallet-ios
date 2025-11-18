import SwiftUI

struct SubscriptionView: View {
    @StateObject var viewModel: PurchasesViewModel

    var body: some View {
        ThemeRadialView {
            ScrollView {
                VStack(spacing: 0) {
                    Image("box_2")
                        .padding(.vertical, .margin24)

                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 52)
                        .padding(.bottom, .margin24)

                    ListSection {
                        ForEach(viewModel.viewItems, id: \.self) { feature in
                            row(
                                title: "purchases.\(feature.title)".localized,
                                description: "purchases.\(feature.title).description".localized,
                                image: Image(feature.iconName),
                                action: {
                                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                        infoView(viewItem: feature, isPresented: isPresented)
                                    }
                                }
                            )
                        }
                    }
                    .themeListStyle(.lawrence)
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin4)

                    walletDescription()
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomContent()
            }
        }
    }

    private func activatedDescription() -> some View {
        Text("purchases.successful_subscription.subscribed".localized)
            .textSubhead2(color: .themeJacob)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .margin32)
            .padding(.top, .margin12)
            .padding(.bottom, .margin32)
    }

    private var title: AttributedString {
        let text = "premium.cell.description".localized("premium.cell.description.key".localized)
        var attributedString = AttributedString(text)
        attributedString.font = .headline1
        attributedString.foregroundColor = .themeLeah

        for range in text.ranges(of: "premium.cell.description.key".localized) {
            if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
               let upperBound = AttributedString.Index(range.upperBound, within: attributedString)
            {
                let attrRange = lowerBound ..< upperBound
                attributedString[attrRange].foregroundColor = .themeJacob
            }
        }

        return attributedString
    }

    @ViewBuilder private func bottomContent() -> some View {
        VStack(spacing: .margin8) {
            actionButtonView()
        }
        .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        .background(
            CustomBlurView(removeAllFilters: false)
                .edgesIgnoringSafeArea(.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
    }

    @ViewBuilder private func row(title: String, description: String, image: Image, action: @escaping () -> Void) -> some View {
        ClickableRow(padding: EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), action: action) {
            HStack(spacing: .margin16) {
                image
                    .renderingMode(.template)
                    .foregroundColor(.themeJacob)
                    .frame(width: 24, height: 24)

                VStack(spacing: .heightOneDp) {
                    Text(title).themeSubhead1(color: .themeLeah)
                    Text(description).themeCaption()
                }
            }
        }
    }

    @ViewBuilder private func walletDescription() -> some View {
        VStack {
            Text("purchases.wallet_description.title".localized)
                .themeHeadline2(alignment: .center)
                .multilineTextAlignment(.center)
                .padding(EdgeInsets(top: .margin32, leading: .margin32, bottom: .margin24, trailing: .margin32))

            Image("premium_security")

            approvedBy()
        }
    }

    @ViewBuilder private func approvedBy() -> some View {
        VStack {
            Text("purchases.wallet_description.approved".localized)
                .textSubhead2()
                .multilineTextAlignment(.center)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin16)

            LazyVGrid(columns: viewModel.approvedIcons.map { _ in GridItem(.flexible(), alignment: .center) }, spacing: .margin8) {
                ForEach(viewModel.approvedIcons, id: \.self) { icon in
                    Image(icon)
                        .renderingMode(.template)
                        .foregroundColor(.themeLeah)
                }
            }
            .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func actionButtonView() -> some View {
        let (title, disabled) = buttonState()

        Button(action: {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                PurchaseBottomSheetView(isPresented: isPresented) { [weak viewModel] _ in
                    viewModel?.didSubscribeSuccessful()
                }
            }
        }) {
            Text(title)
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
    }

    @ViewBuilder private func infoView(viewItem: PurchasesViewModel.ViewItem, isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            items: [
                .title(
                    icon: ComponentImage(viewItem.iconName, size: .iconSize72, colorStyle: .yellow),
                    title: ComponentText(text: "purchases.\(viewItem.title)".localized, colorStyle: .yellow)
                ),
                .text(text: "purchases.\(viewItem.title).info".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ],
        )
    }

    private func buttonState() -> (String, Bool) {
        var title = "purchases.button.try".localized
        var disabled = false

        switch viewModel.buttonState {
        case .tryForFree: ()
        case .activated:
            title = "purchases.button.activated".localized
            disabled = true
        case .upgrade:
            title = "purchases.button.upgrade".localized
            disabled = false
        }

        return (title, disabled)
    }
}

struct CustomBlurView: UIViewRepresentable {
    let removeAllFilters: Bool

    func makeUIView(context _: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        DispatchQueue.main.async {
            if let backdropLayer = uiView.layer.sublayers?.first {
                if removeAllFilters {
                    backdropLayer.filters = []
                } else {
                    backdropLayer.filters?.removeAll(where: { filter in
                        String(describing: filter) != "gaussianBlur"
                    })
                }
            }
        }
    }
}
