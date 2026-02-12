import Foundation

/// Searches Reddit's public JSON API for posts AND comments matching keywords.
/// Generates actionable intelligence: relevance insights, matching snippets, and approach suggestions.
final class RedditSearchService: RedditSearchServiceProtocol {
    
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
    
    // MARK: - Core Analysis Engine (SALES-FOCUSED)
    //
    // DESIGN: This engine scores from a SALES perspective — we want to find people
    // who would actually BUY or DOWNLOAD a product, not just anyone who happens
    // to mention a keyword in an unrelated context (e.g., marriage advice ≠ app buyer).
    //
    // Three critical gates:
    // 1. NEGATIVE SIGNALS — immediately penalize personal advice, relationship, emotional posts
    // 2. PRODUCT CONTEXT — bonus for posts that mention apps/tools/products
    // 3. PRODUCT INTENT  — high-weight patterns are about PRODUCTS, not life advice
    
    /// Words that signal product/app/tool context — their presence means the post could be about discovering products
    private static let productContextWords: Set<String> = [
        "app", "apps", "application", "tool", "tools", "software", "program",
        "download", "install", "subscribe", "subscription", "free", "paid", "premium",
        "plugin", "extension", "widget", "feature", "features", "update", "version",
        "iphone", "android", "ios", "play store", "app store", "website", "platform",
        "saas", "service", "product", "startup", "alternative",
    ]
    
    /// Words that signal the post is about personal life, NOT about products
    private static let negativeSignalWords: [String] = [
        // Relationship / personal advice
        "marriage", "married", "husband", "wife", "spouse", "divorce", "wedding",
        "relationship", "boyfriend", "girlfriend", "dating", "breakup", "cheating",
        "toxic", "abuse", "abusive", "argument", "fighting", "ex ",
        // Emotional support
        "depressed", "suicidal", "self harm", "panic attack", "trauma",
        "crying", "scared", "afraid", "lonely", "heartbroken",
        // Legal / financial personal
        "custody", "alimony", "restraining order", "police", "arrest", "court",
        // Generic life advice
        "rant", "vent", "aita", "am i wrong", "throwaway",
        // Explicit non-product contexts
        "meme", "shitpost", "joke",
    ]
    
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
        
        // ══════════════════════════════════════════════════════
        // GATE 1: NEGATIVE SIGNALS — Kill personal advice posts immediately
        // ══════════════════════════════════════════════════════
        var negativePenalty = 0
        for word in Self.negativeSignalWords {
            if fullText.contains(word) {
                negativePenalty += 20
            }
        }
        // Hard kill: if 2+ negative signals, this is NOT a product-seeking post
        if negativePenalty >= 40 { return nil }
        
        // ══════════════════════════════════════════════════════
        // GATE 2: PRODUCT CONTEXT — Does this post mention products/apps/tools?
        // ══════════════════════════════════════════════════════
        var productContextScore = 0
        let textWords = Set(fullText.components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty })
        
        for word in Self.productContextWords {
            if word.contains(" ") {
                if fullText.contains(word) { productContextScore += 15 }
            } else {
                if textWords.contains(word) { productContextScore += 15 }
            }
        }
        productContextScore = min(100, productContextScore)
        
        // ══════════════════════════════════════════════════════
        // INTENT DETECTION — Split into PRODUCT-SEEKING vs GENERIC
        // ══════════════════════════════════════════════════════
        var intentScore = 0
        var detectedIntents: [String] = []
        
        // HIGH-VALUE: Product-specific intent (someone looking for a PRODUCT)
        let productIntentPatterns: [(pattern: String, label: String, weight: Int)] = [
            // App/tool seeking — GOLD (these people will download/buy)
            ("recommend.*app", "asking for app recommendations", 35),
            ("best app", "seeking the best app", 35),
            ("looking for.*app", "looking for an app", 35),
            ("any good app", "evaluating apps", 30),
            ("app for", "searching for app by purpose", 30),
            ("tool for", "searching for tool by purpose", 30),
            ("app recommendation", "explicitly wants recommendations", 35),
            ("what app", "asking about apps", 30),
            ("which app", "comparing apps", 30),
            ("suggest.*app", "wants app suggestions", 30),
            ("anyone use.*app", "researching specific apps", 25),
            ("anyone tried", "researching options", 25),
            ("has anyone used", "researching options", 25),
            ("does anyone know", "seeking specific knowledge", 22),
            
            // Switching/alternative signals — HIGHEST conversion potential
            ("alternative to", "looking for alternatives", 35),
            ("switch from", "ready to switch solutions", 35),
            ("replacing", "actively replacing current tool", 30),
            ("moving away from", "unhappy with current solution", 30),
            ("better than", "comparing solutions", 25),
            
            // Product evaluation
            ("is it worth", "evaluating purchase", 25),
            ("worth paying", "considering payment", 30),
            ("free version", "evaluating pricing", 25),
            ("premium worth", "considering premium", 30),
            ("review of", "reading reviews", 20),
        ]
        
        // MEDIUM-VALUE: Generic but still could be product-related if context matches
        let genericIntentPatterns: [(pattern: String, label: String, weight: Int)] = [
            ("looking for", "actively looking for something", 12),
            ("recommend", "asking for recommendations", 12),
            ("suggestion", "seeking suggestions", 10),
            ("any good", "evaluating options", 10),
            ("can anyone", "asking community for help", 8),
            ("i need", "has a specific need", 10),
            ("what is the best", "seeking the best option", 15),
            ("is there a", "looking for something specific", 12),
            ("is there an", "looking for something specific", 12),
            ("how do you", "seeking how-to guidance", 8),
            ("want to try", "open to trying new things", 8),
            ("looking to", "actively searching", 10),
            ("i wish", "expressing an unmet need", 12),
            ("if only", "expressing frustration with gap", 10),
        ]
        
        // Check product-specific intent first (high weight)
        for pattern in productIntentPatterns {
            if pattern.pattern.contains(".*") {
                // Simple regex-like check: split on .* and check both parts exist
                let parts = pattern.pattern.components(separatedBy: ".*")
                if parts.count == 2 {
                    if let range1 = fullText.range(of: parts[0]),
                       fullText[range1.upperBound...].contains(parts[1]) {
                        intentScore = min(100, intentScore + pattern.weight)
                        detectedIntents.append(pattern.label)
                    }
                }
            } else {
                if fullText.contains(pattern.pattern) {
                    intentScore = min(100, intentScore + pattern.weight)
                    detectedIntents.append(pattern.label)
                }
            }
        }
        
        // Check generic intent (lower weight, but still useful with product context)
        for pattern in genericIntentPatterns {
            if fullText.contains(pattern.pattern) {
                intentScore = min(100, intentScore + pattern.weight)
                detectedIntents.append(pattern.label)
            }
        }
        
        if fullText.contains("?") { intentScore = min(100, intentScore + 5) }
        
        // ══════════════════════════════════════════════════════
        // KEYWORD MATCHING
        // ══════════════════════════════════════════════════════
        var matchedKeywords: [String] = []
        for keyword in keywords {
            if fullText.contains(keyword.lowercased()) {
                matchedKeywords.append(keyword)
                intentScore = min(100, intentScore + 15)
            }
        }
        
        // ══════════════════════════════════════════════════════
        // URGENCY SCORE
        // ══════════════════════════════════════════════════════
        let hoursOld = (Date().timeIntervalSince1970 - createdUtc) / 3600
        var urgencyScore: Int
        if hoursOld < 6 { urgencyScore = 100 }
        else if hoursOld < 24 { urgencyScore = 80 }
        else if hoursOld < 48 { urgencyScore = 60 }
        else if hoursOld < 168 { urgencyScore = 40 }
        else { urgencyScore = 20 }
        
        if numComments > 20 { urgencyScore = min(100, urgencyScore + 15) }
        else if numComments > 5 { urgencyScore = min(100, urgencyScore + 10) }
        
        // ══════════════════════════════════════════════════════
        // FIT SCORE — How well does this match the product?
        // ══════════════════════════════════════════════════════
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
        
        // ══════════════════════════════════════════════════════
        // OVERALL SCORE — with product-context bonus/penalty
        // ══════════════════════════════════════════════════════
        //
        // Formula: intent (40%) + urgency (20%) + fit (25%) + productContext (15%)
        // Then subtract negative penalty
        //
        var overall = (intentScore * 4 + urgencyScore * 2 + fitScore * 25/10 + productContextScore * 15/10) / 10
        
        // Apply negative penalty
        overall = max(0, overall - negativePenalty)
        
        // HARD GATE: If NO product context AND NO keyword match AND score is just from
        // generic intent patterns, this is probably a personal advice post — reject.
        if productContextScore == 0 && matchedKeywords.isEmpty && intentScore < 40 {
            return nil
        }
        
        // Quality gate — raised to 30 (from 20) for better signal-to-noise
        guard overall >= 30 else { return nil }
        
        let breakdown = ScoreBreakdown(intent: intentScore, urgency: urgencyScore, fit: fitScore)
        
        // ── Extract Matching Snippet ──────────────────────────
        let allPatterns = productIntentPatterns.map(\.pattern) + genericIntentPatterns.map(\.pattern)
        let snippet = extractSnippet(
            from: displayText,
            matchedKeywords: matchedKeywords,
            intentPatterns: allPatterns
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
