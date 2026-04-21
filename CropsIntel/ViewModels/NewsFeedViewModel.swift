import SwiftUI
import Combine

@MainActor
final class NewsFeedViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func loadArticles() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result: [NewsArticle] = try await supabase.query(
                    table: "news_articles",
                    select: "id,title,summary,published_at,source,url,status",
                    filters: ["status": "eq.published"],
                    order: "published_at.desc",
                    limit: 50
                )
                articles = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
