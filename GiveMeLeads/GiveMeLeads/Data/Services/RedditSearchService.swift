import Foundation

/// Searches Reddit's public JSON API for posts AND comments matching keywords.
/// Generates actionable intelligence: relevance insights, matching snippets, and approach suggestions.
final class RedditSearchService {
    
    struct RedditPost: Codable {
        let id: String
        let subreddit: String
        let author: String
        let title: String
        let selftext: String?
        let url: String
        let permalink: String
        let ups: Int
        let numComments: Int
        let createdUtc: Double
        
        enum CodingKeys: String, CodingKey {
            case id, subreddit, author, title, selftext, url, permalink, ups
            case numComments = "num_comments"
            case createdUtc = "created_utc"
        }
    }
    
    struct RedditComment: Codable {
        let id: String
        let subreddit: String
        let author: String
        let body: String
        let permalink: String
        let ups: Int
        let createdUtc: Double
        let linkTitle: String?
        
        enum CodingKeys: String, CodingKey {
            case id, subreddit, author, body, permalink, ups
            case createdUtc = "created_utc"
            case linkTitle = "link_title"
        }
    }
    
    /// Full intelligence result for a scored lead
    struct LeadIntelligence {
        let score: Int
        let breakdown: ScoreBreakdown
        let relevanceInsight: String
        let matchingSnippet: String
        let suggestedApproach: String
    }
    
    // MARK: - Search Posts
    
    func search(keywords: [String], subreddits: [String], limit: Int = 25) async throws -> [RedditPost] {
        var allPosts: [RedditPost] = []
        var seenIds = Set<String>()
        
        // Search with specific subreddits first
        let subredditStr = subreddits.prefix(8).joined(separator: "+")
        
        for keyword in keywords.prefix(8) {
            let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            let urlString = "https://www.reddit.com/r/\(subredditStr)/search.json?q=\(query)&sort=relevance&limit=\(limit)&restrict_sr=1&t=month"
            
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.setValue("ios:com.givemeleads:v1.0 (by /u/givemeleads)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { continue }
                let listing = try JSONDecoder().decode(RedditListing.self, from: data)
                
                for child in listing.data.children {
                    let post = child.data
                    if !seenIds.contains(post.id) && post.author != "[deleted]" && post.author != "AutoModerator" {
                        seenIds.insert(post.id)
                        allPosts.append(post)
                    }
                }
                try await Task.sleep(nanoseconds: 800_000_000)
            } catch { continue }
        }
        
        // FALLBACK: If subreddit-specific search found very few results, search r/all
        if allPosts.count < 5 {
            for keyword in keywords.prefix(3) {
                let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
                let urlString = "https://www.reddit.com/search.json?q=\(query)&sort=relevance&limit=\(limit)&t=month"
                
                guard let url = URL(string: urlString) else { continue }
                var request = URLRequest(url: url)
                request.setValue("ios:com.givemeleads:v1.0 (by /u/givemeleads)", forHTTPHeaderField: "User-Agent")
                request.timeoutInterval = 15
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { continue }
                    let listing = try JSONDecoder().decode(RedditListing.self, from: data)
                    
                    for child in listing.data.children {
                        let post = child.data
                        if !seenIds.contains(post.id) && post.author != "[deleted]" && post.author != "AutoModerator" {
                            seenIds.insert(post.id)
                            allPosts.append(post)
                        }
                    }
                    try await Task.sleep(nanoseconds: 800_000_000)
                } catch { continue }
            }
        }
        
        return allPosts
    }
    
    // MARK: - Search Comments
    
    func searchComments(keywords: [String], subreddits: [String], limit: Int = 25) async throws -> [RedditComment] {
        var allComments: [RedditComment] = []
        var seenIds = Set<String>()
        
        let subredditStr = subreddits.prefix(8).joined(separator: "+")
        
        for keyword in keywords.prefix(5) {
            let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            let urlString = "https://www.reddit.com/r/\(subredditStr)/search.json?q=\(query)&sort=relevance&limit=\(limit)&restrict_sr=1&t=month&type=comment"
            
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.setValue("ios:com.givemeleads:v1.0 (by /u/givemeleads)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { continue }
                let listing = try JSONDecoder().decode(CommentListing.self, from: data)
                
                for child in listing.data.children {
                    let comment = child.data
                    if !seenIds.contains(comment.id) && comment.author != "[deleted]" && comment.author != "AutoModerator" {
                        seenIds.insert(comment.id)
                        allComments.append(comment)
                    }
                }
                try await Task.sleep(nanoseconds: 800_000_000)
            } catch { continue }
        }
        return allComments
    }
    
    // MARK: - Intelligence Generation
    
    /// Score a post AND generate actionable intelligence
    func analyzePost(_ post: RedditPost, keywords: [String], productDescription: String) -> LeadIntelligence? {
        let title = post.title.lowercased()
        let body = (post.selftext ?? "").lowercased()
        let fullText = title + " " + body
        
        let result = analyzeText(
            fullText: fullText,
            displayText: post.selftext ?? post.title,
            keywords: keywords,
            productDescription: productDescription,
            ups: post.ups,
            numComments: post.numComments,
            createdUtc: post.createdUtc,
            isComment: false
        )
        
        return result
    }
    
    /// Score a comment AND generate actionable intelligence
    func analyzeComment(_ comment: RedditComment, keywords: [String], productDescription: String) -> LeadIntelligence? {
        let body = comment.body.lowercased()
        let parentTitle = (comment.linkTitle ?? "").lowercased()
        let fullText = parentTitle + " " + body
        
        let result = analyzeText(
            fullText: fullText,
            displayText: comment.body,
            keywords: keywords,
            productDescription: productDescription,
            ups: comment.ups,
            numComments: 0,
            createdUtc: comment.createdUtc,
            isComment: true
        )
        
        return result
    }
    
    // MARK: - Core Analysis Engine
    
    private func analyzeText(
        fullText: String,
        displayText: String,
        keywords: [String],
        productDescription: String,
        ups: Int,
        numComments: Int,
        createdUtc: Double,
        isComment: Bool
    ) -> LeadIntelligence? {
        
        // ── Intent Detection ──────────────────────────────────
        var intentScore = 0
        var detectedIntents: [String] = []
        
        let intentPatterns: [(pattern: String, label: String, weight: Int)] = [
            // Direct request signals (highest value)
            ("looking for", "actively looking for a solution", 25),
            ("recommend", "asking for recommendations", 25),
            ("suggestion", "seeking suggestions", 20),
            ("any good", "evaluating options", 20),
            ("can anyone", "asking the community for help", 20),
            ("does anyone know", "seeking specific knowledge", 20),
            ("anyone tried", "researching options", 18),
            ("has anyone used", "researching options", 18),
            
            // Switching signals (very high value — they WILL pay)
            ("alternative to", "looking for alternatives", 30),
            ("switch from", "ready to switch solutions", 30),
            ("replacing", "actively replacing current tool", 28),
            ("moving away from", "unhappy with current solution", 28),
            ("tired of", "frustrated with status quo", 25),
            ("better than", "comparing solutions", 22),
            
            // Need signals
            ("i need", "has a specific need", 22),
            ("need help", "needs help with something", 20),
            ("how do you", "seeking how-to guidance", 15),
            ("what is the best", "seeking the best option", 22),
            ("want to try", "open to trying new things", 15),
            ("looking to", "actively searching", 18),
            
            // Wish / desire signals (gold for comments)
            ("i wish", "expressing an unmet need", 30),
            ("would be nice", "expressing a desire", 20),
            ("if only", "expressing frustration with gap", 22),
            ("is there a", "looking for something specific", 25),
            ("is there an", "looking for something specific", 25),
        ]
        
        for pattern in intentPatterns {
            if fullText.contains(pattern.pattern) {
                intentScore = min(100, intentScore + pattern.weight)
                detectedIntents.append(pattern.label)
            }
        }
        if fullText.contains("?") { intentScore = min(100, intentScore + 10) }
        
        // ── Keyword Matching ──────────────────────────────────
        var matchedKeywords: [String] = []
        for keyword in keywords {
            if fullText.contains(keyword.lowercased()) {
                matchedKeywords.append(keyword)
                intentScore = min(100, intentScore + 12)
            }
        }
        
        // ── Urgency Score ─────────────────────────────────────
        let hoursOld = (Date().timeIntervalSince1970 - createdUtc) / 3600
        var urgencyScore: Int
        if hoursOld < 6 { urgencyScore = 100 }
        else if hoursOld < 24 { urgencyScore = 80 }
        else if hoursOld < 48 { urgencyScore = 60 }
        else if hoursOld < 168 { urgencyScore = 40 }
        else { urgencyScore = 20 }
        
        if numComments > 20 { urgencyScore = min(100, urgencyScore + 15) }
        else if numComments > 5 { urgencyScore = min(100, urgencyScore + 10) }
        
        // ── Fit Score ─────────────────────────────────────────
        var fitScore = matchedKeywords.count * 25
        let descWords = productDescription.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 4 }
        var matchedDescWords: [String] = []
        for word in descWords.prefix(10) {
            if fullText.contains(word) {
                fitScore = min(100, fitScore + 10)
                matchedDescWords.append(word)
            }
        }
        fitScore = min(100, fitScore)
        
        // ── Overall Score ─────────────────────────────────────
        let overall = (intentScore * 4 + urgencyScore * 3 + fitScore * 3) / 10
        
        // Quality gate — only return leads worth showing
        guard overall >= 20 else { return nil }
        
        let breakdown = ScoreBreakdown(intent: intentScore, urgency: urgencyScore, fit: fitScore)
        
        // ── Extract Matching Snippet ──────────────────────────
        let snippet = extractSnippet(
            from: displayText,
            matchedKeywords: matchedKeywords,
            intentPatterns: intentPatterns.map(\.pattern)
        )
        
        // ── Generate Relevance Insight ────────────────────────
        let insight = generateInsight(
            detectedIntents: detectedIntents,
            matchedKeywords: matchedKeywords,
            matchedDescWords: matchedDescWords,
            isComment: isComment,
            score: overall
        )
        
        // ── Suggest Approach ──────────────────────────────────
        let approach = generateApproach(
            detectedIntents: detectedIntents,
            matchedKeywords: matchedKeywords,
            isComment: isComment
        )
        
        return LeadIntelligence(
            score: overall,
            breakdown: breakdown,
            relevanceInsight: insight,
            matchingSnippet: snippet,
            suggestedApproach: approach
        )
    }
    
    // MARK: - Snippet Extraction
    
    /// Find the most relevant sentence from the post/comment text
    private func extractSnippet(from text: String, matchedKeywords: [String], intentPatterns: [String]) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 10 && $0.count < 300 }
        
        guard !sentences.isEmpty else { return String(text.prefix(150)) }
        
        // Score each sentence — find the one with the most signal
        var bestSentence = sentences[0]
        var bestScore = 0
        
        for sentence in sentences {
            var score = 0
            let lower = sentence.lowercased()
            
            // Intent patterns in this sentence
            for pattern in intentPatterns {
                if lower.contains(pattern) { score += 10 }
            }
            
            // Keywords in this sentence
            for keyword in matchedKeywords {
                if lower.contains(keyword.lowercased()) { score += 8 }
            }
            
            // Question marks are high signal
            if sentence.contains("?") { score += 5 }
            
            if score > bestScore {
                bestScore = score
                bestSentence = sentence
            }
        }
        
        // Trim to reasonable length
        if bestSentence.count > 200 {
            return String(bestSentence.prefix(197)) + "..."
        }
        return bestSentence
    }
    
    // MARK: - Insight Generation
    
    /// Generate a human-readable explanation of WHY this lead matters
    private func generateInsight(
        detectedIntents: [String],
        matchedKeywords: [String],
        matchedDescWords: [String],
        isComment: Bool,
        score: Int
    ) -> String {
        var parts: [String] = []
        
        // Lead source context
        if isComment {
            parts.append("A user in this thread is")
        } else {
            parts.append("This person is")
        }
        
        // Primary intent
        if let topIntent = detectedIntents.first {
            parts.append(topIntent)
        } else if !matchedKeywords.isEmpty {
            parts.append("discussing topics relevant to your product")
        } else {
            parts.append("talking about something in your space")
        }
        
        // What matched
        if !matchedKeywords.isEmpty {
            let keywordList = matchedKeywords.prefix(3).map { "\"\($0)\"" }.joined(separator: ", ")
            parts.append("— mentions \(keywordList)")
        }
        
        // Strength indicator
        if score >= 75 {
            parts.append("which directly matches your offering")
        } else if score >= 50 {
            parts.append("which is relevant to what you offer")
        }
        
        return parts.joined(separator: " ") + "."
    }
    
    // MARK: - Approach Suggestion
    
    /// Generate actionable guidance on HOW to engage with this lead
    private func generateApproach(
        detectedIntents: [String],
        matchedKeywords: [String],
        isComment: Bool
    ) -> String {
        let intentsSet = Set(detectedIntents)
        
        // Switching/replacing intent — highest conversion potential
        if intentsSet.contains("ready to switch solutions") ||
           intentsSet.contains("actively replacing current tool") ||
           intentsSet.contains("unhappy with current solution") ||
           intentsSet.contains("looking for alternatives") {
            return "🎯 High conversion opportunity. This person is actively switching tools. Reply with a brief, genuine comment about how your product solves their specific pain point. Don't hard-sell — share your experience."
        }
        
        // Direct request — they're asking for help
        if intentsSet.contains("asking for recommendations") ||
           intentsSet.contains("actively looking for a solution") ||
           intentsSet.contains("seeking the best option") {
            let keywordMention = matchedKeywords.first.map { " Mention how it handles \($0)." } ?? ""
            return "💡 Direct opportunity. They're asking for exactly what you offer. Reply helpfully with your product as one option among others — authenticity converts better than promotion.\(keywordMention)"
        }
        
        // Wish/desire signals — unmet need
        if intentsSet.contains("expressing an unmet need") ||
           intentsSet.contains("expressing frustration with gap") ||
           intentsSet.contains("expressing a desire") {
            return "✨ Unmet need detected. This person wishes something existed that matches your product. Reply empathetically acknowledging their need, then naturally mention your solution."
        }
        
        // Research/evaluation phase
        if intentsSet.contains("researching options") ||
           intentsSet.contains("evaluating options") ||
           intentsSet.contains("comparing solutions") {
            return "🔍 Research phase. They're evaluating options. Provide genuine value first (tips, comparisons) and mention your product as something worth checking out."
        }
        
        // General discussion
        if isComment {
            return "💬 Comment thread opportunity. Join the conversation naturally. Add value to the discussion first, then mention your product if it genuinely helps."
        }
        
        return "📝 Relevant discussion. Engage authentically — share your expertise on the topic and mention your product only if it directly addresses their situation."
    }
}

// MARK: - Reddit JSON Response Models

private struct RedditListing: Codable {
    let data: ListingData
}

private struct ListingData: Codable {
    let children: [PostWrapper]
}

private struct PostWrapper: Codable {
    let data: RedditSearchService.RedditPost
}

private struct CommentListing: Codable {
    let data: CommentListingData
}

private struct CommentListingData: Codable {
    let children: [CommentWrapper]
}

private struct CommentWrapper: Codable {
    let data: RedditSearchService.RedditComment
}
