import SwiftUI

struct PurchasesView: View {
    @StateObject private var viewModel = PurchasesViewModel()

    @Environment(\.dismiss) private var dismiss
    @State private var bottomHeight: CGFloat = 0

    @State private var presentedInfoViewItem: PurchasesViewModel.ViewItem?
    @State private var presentedSubscriptionType: PurchaseManager.SubscriptionType?
    @State private var successfulSubscriptionPresented = false

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                ZStack {
                    VStack(spacing: 0) {
                        Text("purchases.description".localized).textBody(color: .themeGray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, .margin16)
                            .padding(.horizontal, .margin32)
                            .padding(.bottom, .margin24)

                        PurchaseSegmentView(selection: $viewModel.featuresType)
                            .onChange(of: viewModel.featuresType) { newValue in
                                viewModel.setType(newValue)
                            }
                            .clipShape(RoundedCorner(radius: .margin16, corners: [.topLeft, .topRight]))
                            .padding(.horizontal, .margin16)

                        ThemeRadialView {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ListSection {
                                        ForEach(viewModel.viewItems, id: \.self) { feature in
                                            row(
                                                title: "purchases.\(feature.title)".localized,
                                                description: "purchases.\(feature.title).description".localized,
                                                image: Image(feature.iconName),
                                                accented: feature.accented,
                                                action: {
                                                    presentedInfoViewItem = feature
                                                }
                                            )
                                        }
                                    }
                                    .themeListStyle(.steel10WithBottomCorners([.bottomLeft, .bottomRight]))
                                    .padding(.horizontal, .margin16)

                                    walletDescription()
                                }
                                .padding(.bottom, .margin24)
                            }
                            .safeAreaInset(edge: .bottom) {
                                Color.clear.frame(height: bottomHeight)
                            }
                        }
                    }

                    VStack {
                        Spacer()
                        VStack(spacing: .margin8) {
                            actionButtonView()

                            Button(action: {
                                successfulSubscriptionPresented = true
                            }) {
                                Text("purchases.button.restore".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .transparent))
                        }
                        .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
                        .background(
                            GeometryReader { geometry in
                                CustomBlurView(removeAllFilters: false)
                                    .edgesIgnoringSafeArea(.bottom)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    .onAppear {
                                        bottomHeight = geometry.size.height
                                    }
                            }
                        )
                    }
                }
                .navigationTitle("purchases.title".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("button.close".localized) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .bottomSheet(item: $presentedInfoViewItem) { viewItem in
            ActionSheetView(
                image: .local(name: viewItem.iconName, tint: .warning),
                title: "purchases.\(viewItem.title)".localized,
                titleColor: .themeJacob,
                items: [
                    .description(text: "purchases.\(viewItem.title).info".localized),
                ],
                onDismiss: { presentedInfoViewItem = nil }
            )
        }
        .bottomSheet(
            item: $presentedSubscriptionType,
            configuration: ActionSheetConfiguration(style: .sheet).set(ignoreKeyboard: true),
            ignoreSafeArea: true,
            onDismiss: {
                if viewModel.subscribedSuccessful {
                    successfulSubscriptionPresented = true
                }
            }
        ) { type in
            PurchaseBottomSheetView(type: type, isPresented: Binding(get: { presentedSubscriptionType != nil }, set: { if !$0 { presentedSubscriptionType = nil } })) { _ in
                viewModel.onSubscribe()
                presentedSubscriptionType = nil
            }
        }
        .sheet(isPresented: $successfulSubscriptionPresented) {
            SuccessfulSubscriptionView(type: viewModel.featuresType) {
                dismiss()
            }
        }
    }

    @ViewBuilder private func row(title: String, description: String, image: Image, accented: Bool, action: @escaping () -> Void) -> some View {
        ClickableRow(padding: EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), action: action) {
            HStack(spacing: .margin16) {
                image
                    .renderingMode(.template)
                    .foregroundColor(accented ? .themeYellow : .themeLeah)
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
                .themeHeadline2()
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
            presentedSubscriptionType = viewModel.featuresType
        }) {
            Text(title)
        }
        .disabled(disabled)
        .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
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
