import SwiftUI

struct PurchasesView: View {
    @StateObject private var viewModel = PurchasesViewModel()

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeNavigationView {
            ThemeRadialView {
                ScrollView {
                    VStack(spacing: 0) {
                        Text("purchases.description".localized).themeBody(color: .themeGray)
                            .multilineTextAlignment(.center)
                            .padding(.top, .margin12)
                            .padding(.horizontal, .margin32)
                            .padding(.bottom, .margin32)

                        ListSection {
                            row(
                                title: "purchases.trading".localized,
                                description: "purchases.trading.description".localized,
                                displayPrice: viewModel.products.first { $0.id == "trading_1y" }?.displayPrice,
                                image: Image("premium_trading")
                            )

                            row(
                                title: "purchases.security".localized,
                                description: "purchases.security.description".localized,
                                displayPrice: viewModel.products.first { $0.id == "security_1y" }?.displayPrice,
                                image: Image("premium_security")
                            )

                            row(
                                title: "purchases.vip_support".localized,
                                description: "purchases.vip_support.description".localized,
                                displayPrice: viewModel.products.first { $0.id == "vip_support_1y" }?.displayPrice,
                                image: Image("premium_support")
                            )
                        }
                        .themeListStyle(.blur)
                        .padding(.horizontal, .margin24)

                        VStack(spacing: .margin16) {
                            Text("Products")

                            ForEach(viewModel.products) { product in
                                HStack {
                                    Button {
                                        viewModel.purchase(product: product)
                                    } label: {
                                        Text("\(product.displayPrice) - \(product.displayName)")
                                    }

                                    if viewModel.purchasedProductIds.contains(product.id) {
                                        Text("Purchased")
                                    }
                                }
                            }

                            Button {
                                viewModel.restorePurchases()
                            } label: {
                                Text("Restore Purchases")
                            }

                            Button {
                                viewModel.loadPurchases()
                            } label: {
                                Text("Load Purchases")
                            }
                        }
                    }
                    .padding(.bottom, .margin32)
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
            // .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder private func row(title: String, description: String, displayPrice: String?, image: Image) -> some View {
        ListRow(padding: EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16)) {
            VStack(spacing: .margin16) {
                Text(title).themeHeadline1()
                Text(description).themeSubhead2()
                Spacer()

                if let displayPrice {
                    Text("From \(displayPrice) / month").themeSubhead2(color: .themeJacob)
                }
            }

            image
                .frame(width: 124, height: 130)
        }
    }
}
