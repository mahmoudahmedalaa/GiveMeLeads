import Foundation
import Combine

/// Searches Reddit's subreddit-search API for autocomplete validation
@MainActor
final class SubredditSearchService: ObservableObject {
    
    struct SubredditSuggestion: Identifiable, Equatable {
        let id: String  // = name
        let name: String
        let subscribers: Int
        let description: String
        
        var formattedSubscribers: String {
            if subscribers >= 1_000_000 {
                return String(format: "%.1fM", Double(subscribers) / 1_000_000)
            } else if subscribers >= 1_000 {
                return String(format: "%.0fK", Double(subscribers) / 1_000)
            }
            return "\(subscribers)"
        }
    }
    
    @Published var suggestions: [SubredditSuggestion] = []
    @Published var isSearching = false
    @Published var noResults = false
    
    private var searchTask: Task<Void, Never>?
    
    /// Debounced search — waits 300ms after last keystroke
    func search(query: String) {
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "r/", with: "")
        
        guard trimmed.count >= 2 else {
            suggestions = []
            noResults = false
            return
        }
        
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            isSearching = true
            defer { isSearching = false }
            
            do {
                let results = try await fetchSubreddits(query: trimmed)
                guard !Task.isCancelled else { return }
                suggestions = results
                noResults = results.isEmpty
            } catch {
                guard !Task.isCancelled else { return }
                suggestions = []
                noResults = true
            }
        }
    }
    
    func clear() {
        searchTask?.cancel()
        suggestions = []
        noResults = false
        isSearching = false
    }
    
    // MARK: - API Call
    
    private func fetchSubreddits(query: String) async throws -> [SubredditSuggestion] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.reddit.com/subreddits/search.json?q=\(encoded)&limit=8&include_over_18=false"
        
        guard let url = URL(string: urlString) else { return [] }
        var request = URLRequest(url: url)
        request.setValue("ios:com.givemeleads:v1.0 (by /u/givemeleads)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let listing = json["data"] as? [String: Any],
              let children = listing["children"] as? [[String: Any]] else { return [] }
        
        var results: [SubredditSuggestion] = []
        for child in children {
            guard let subredditData = child["data"] as? [String: Any],
                  let name = subredditData["display_name"] as? String else { continue }
            
            let subscribers = subredditData["subscribers"] as? Int ?? 0
            let description = subredditData["public_description"] as? String ?? ""
            
            results.append(SubredditSuggestion(
                id: name,
                name: name,
                subscribers: subscribers,
                description: String(description.prefix(100))
            ))
        }
        
        return results.sorted { $0.subscribers > $1.subscribers }
    }
}
