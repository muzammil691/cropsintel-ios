import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel = NewsFeedViewModel()
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.articles.isEmpty {
                    LoadingView()
                } else {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("News")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Almond Market Intelligence by MAXONS")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error) {
                                viewModel.loadArticles()
                            }
                            .padding()
                        }

                        if viewModel.articles.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "newspaper")
                                    .font(.system(size: 48))
                                    .foregroundColor(.textSecondary)
                                Text("No Articles Yet")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text("Market news and analysis will appear here as they are published.")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.articles) { article in
                                        NewsArticleCard(article: article)
                                            .onTapGesture {
                                                if let urlString = article.url,
                                                   let url = URL(string: urlString) {
                                                    UIApplication.shared.open(url)
                                                } else {
                                                    selectedArticle = article
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 80)
                            }
                            .refreshable {
                                viewModel.loadArticles()
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedArticle) { article in
                NewsArticleDetailView(article: article)
            }
            .onAppear {
                if viewModel.articles.isEmpty {
                    viewModel.loadArticles()
                }
            }
        }
    }
}

// MARK: - News Article Card
struct NewsArticleCard: View {
    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source & Date
            HStack {
                if let source = article.source, !source.isEmpty {
                    Text(source.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.amberAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.amberAccent.opacity(0.15))
                        .cornerRadius(4)
                }
                Spacer()
                Text(article.displayDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // Title
            Text(article.title ?? "Untitled")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            // Summary
            if let summary = article.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            // Read more indicator
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("Read more")
                        .font(.caption)
                        .foregroundColor(.amberAccent)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.amberAccent)
                }
            }
        }
        .padding(16)
        .background(Color.darkSurface)
        .cornerRadius(14)
    }
}

// MARK: - Article Detail Sheet
struct NewsArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Source badge
                        if let source = article.source, !source.isEmpty {
                            Text(source.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.amberAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.amberAccent.opacity(0.15))
                                .cornerRadius(6)
                        }

                        Text(article.title ?? "Untitled")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(article.displayDate)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)

                        Divider()
                            .background(Color.darkCard)

                        if let summary = article.summary {
                            Text(summary)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(6)
                        }

                        if let urlString = article.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("Open Full Article")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.amberAccent)
                                .foregroundColor(.darkBackground)
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.amberAccent)
                }
            }
        }
    }
}
