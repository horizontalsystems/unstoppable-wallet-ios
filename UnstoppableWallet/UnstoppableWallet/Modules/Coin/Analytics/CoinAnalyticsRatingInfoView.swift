import SwiftUI

struct CoinAnalyticsRatingInfoView: View {
    let title: String
    let description: String
    let scores: [CoinAnalyticsModule.Rating: String]

    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin12) {
                    VStack(alignment: .leading, spacing: 0) {
                        InfoView.header1View(text: "coin_analytics.overall_score".localized)
                        InfoView.header3View(text: title)
                        InfoView.textView(text: description)
                    }

                    ListSection {
                        ForEach(CoinAnalyticsModule.Rating.allCases) { rating in
                            ListRow(spacing: .margin8) {
                                rating.imageNew
                                Text(rating.title.uppercased()).textSubhead1(color: rating.colorNew)

                                Spacer()

                                if let score = scores[rating] {
                                    Text(score).textSubhead1(color: rating.colorNew)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, .margin16)
                }
                .padding(.bottom, .margin32)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
