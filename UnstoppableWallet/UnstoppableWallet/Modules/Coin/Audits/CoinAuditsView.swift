import Kingfisher
import MarketKit
import SwiftUI

struct CoinAuditsView: View {
    @StateObject var viewModel: CoinAuditsViewModel

    init(audits: [Analytics.Audit]) {
        _viewModel = StateObject(wrappedValue: CoinAuditsViewModel(audits: audits))
    }

    var body: some View {
        ThemeView {
            ScrollView {
                LazyVStack(spacing: .margin24) {
                    ForEach(viewModel.viewItems.indices, id: \.self) { index in
                        let viewItem = viewModel.viewItems[index]

                        VStack(spacing: .margin12) {
                            VStack(spacing: 0) {
                                HorizontalDivider()

                                HStack(spacing: .margin16) {
                                    KFImage.url(viewItem.logoUrl.flatMap { URL(string: $0) })
                                        .resizable()
                                        .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeSteel20) }
                                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                        .frame(width: .iconSize32, height: .iconSize32)

                                    Text(viewItem.name).themeBody()
                                }
                                .padding(.horizontal, .margin16)
                                .padding(.vertical, .margin12)
                            }

                            ListSection {
                                ForEach(viewItem.auditViewItems.indices, id: \.self) { index in
                                    let audit = viewItem.auditViewItems[index]

                                    ClickableRow(spacing: .margin8) {
                                        if let url = audit.reportUrl {
                                            UrlManager.open(url: url)
                                        }
                                    } content: {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(audit.date).textBody()
                                            Text(audit.name).textSubhead2()
                                        }

                                        Spacer()

                                        Text(audit.issues).textSubhead1()
                                        Image.disclosureIcon
                                    }
                                }
                            }
                            .padding(.horizontal, .margin16)
                        }
                    }

                    VStack(spacing: .margin12) {
                        HorizontalDivider()
                        Text("Powered by Defiyield.app").textCaption()
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
            }
        }
        .navigationTitle("coin_analytics.audits".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
