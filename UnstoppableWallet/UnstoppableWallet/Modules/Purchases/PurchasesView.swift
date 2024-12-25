import SwiftUI

struct PurchasesView: View {
    @StateObject private var viewModel = PurchasesViewModel()
    
    @Environment(\.dismiss) private var dismiss
    @State private var bottomHeight: CGFloat = 0
    
    @State private var presentedSubscriptionType: PurchasesViewModel.FeaturesType?
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
                                                accented: feature.accented
                                            )
                                        }
                                    }
                                    .themeListStyle(.steel10WithBottomCorners([.bottomLeft, .bottomRight]))
                                    .padding(.horizontal, .margin16)
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
                            Button(action: {
                                presentedSubscriptionType = viewModel.featuresType
                            }) {
                                Text("purchases.button.try".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .yellowGradient))
                            
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
        .bottomSheet(
            item: $presentedSubscriptionType,
            configuration: ActionSheetConfiguration(style: .sheet).set(ignoreKeyboard: true),
            ignoreSafeArea: true,
            onDismiss: {
                if viewModel.subscribedSuccessful {
                    successfulSubscriptionPresented = true
                }
            }) { type in
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

    @ViewBuilder private func row(title: String, description: String, image: Image, accented: Bool) -> some View {
        ListRow(padding: EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16)) {
            HStack(spacing: .margin16) {
                image
                    .renderingMode(.template)
                    .foregroundColor(accented ? .themeYellow : .themeSteelLight)
                    .frame(width: 24, height: 24)

                VStack(spacing: .heightOneDp) {
                    Text(title).themeSubhead1(color: .themeLeah)
                    Text(description).themeCaption()
                }
            }
        }
    }
}

struct CustomBlurView: UIViewRepresentable {
    let removeAllFilters: Bool
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
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
