import SwiftUI

struct PurchasesView: View {
    @StateObject private var viewModel = PurchasesViewModel()
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var bottomHeight: CGFloat = 0
    
    @State private var presentedSubscriptionType: PurchasesViewModel.FeaturesType?

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
                                    .themeListStyle(.white5WithBottomCorners)
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
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))
                            // .disabled(!viewModel.saveEnabled)
                            
                            Button(action: {
                                // viewModel.onTapSave()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("purchases.button.restore".localized)
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .transparent))
                            // .disabled(!viewModel.saveEnabled)
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
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .bottomSheet(item: $presentedSubscriptionType) { type in
            PurchaseBottomSheetView(type: type, isPresented: Binding(get: { presentedSubscriptionType != nil }, set: { if !$0 { presentedSubscriptionType = nil } })) {
                print("Selected : \($0)")
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
