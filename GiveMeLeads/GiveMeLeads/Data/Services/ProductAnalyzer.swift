import Foundation
import NaturalLanguage

/// On-device product analysis — extracts meaningful keywords and suggests relevant subreddits
/// from a user's product description using Apple's NaturalLanguage framework.
enum ProductAnalyzer {
    
    struct AnalysisResult {
        let keywords: [String]
        let subreddits: [String]
        let profileName: String
    }
    
    // MARK: - Comprehensive Stop Words
    
    private static let stopWords: Set<String> = [
        // Articles & determiners
        "a", "an", "the", "this", "that", "these", "those", "my", "your", "our", "its",
        // Pronouns
        "i", "me", "we", "us", "you", "he", "she", "it", "they", "them", "who", "whom",
        // Prepositions
        "in", "on", "at", "to", "for", "of", "with", "by", "from", "up", "about", "into",
        "through", "during", "before", "after", "above", "below", "between", "under", "over",
        // Conjunctions
        "and", "but", "or", "nor", "so", "yet", "both", "either", "neither",
        // Common verbs
        "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does",
        "did", "will", "would", "could", "should", "shall", "may", "might", "can", "must",
        "get", "got", "make", "made", "let", "put", "say", "said", "go", "went", "take", "took",
        "come", "came", "give", "gave", "tell", "told", "work", "find", "found", "know", "known",
        "think", "thought", "see", "seen", "want", "need", "use", "used", "try", "tried",
        "keep", "kept", "help", "helps", "run", "running",
        // Common adverbs & adjectives
        "very", "also", "just", "more", "most", "less", "much", "many", "some", "any", "all",
        "each", "every", "other", "own", "same", "such", "than", "too", "bit", "quite",
        "really", "well", "even", "still", "new", "old", "big", "small", "good", "great",
        "best", "first", "last", "long", "little", "right", "only",
        // Filler / context — NOT product-descriptive
        "like", "look", "looking", "thing", "things", "way", "ways", "people", "user", "users",
        "app", "tool", "platform", "software", "built", "build", "create", "offer", "offers",
        "based", "using", "allows", "able", "kind", "sort", "type", "here", "there", "where",
        "when", "what", "how", "which", "while", "then", "now", "not", "don", "doesn",
    ]
    
    // MARK: - Subreddit Map — PRECISE category-to-subreddit mapping
    // Each category maps ONLY to subreddits genuinely related to that category.
    
    private static let subredditMap: [String: [String]] = [
        // Tech & Software
        "saas": ["SaaS", "startups", "microsaas", "indiehackers"],
        "devtools": ["webdev", "programming", "selfhosted", "sideproject"],
        "mobile": ["iOSProgramming", "androiddev", "FlutterDev", "SwiftUI"],
        "ai": ["artificial", "MachineLearning", "ChatGPT", "LocalLLaMA"],
        
        // Business
        "ecommerce": ["ecommerce", "shopify", "FulfillmentByAmazon", "smallbusiness"],
        "marketing": ["marketing", "digital_marketing", "SEO", "socialmedia"],
        "finance": ["personalfinance", "FinancialPlanning", "accounting", "Bookkeeping"],
        "realestate": ["realestateinvesting", "RealEstate", "PropertyManagement", "landlords"],
        "consulting": ["consulting", "freelance", "Entrepreneur", "startups"],
        
        // Creative
        "design": ["design_critiques", "web_design", "graphic_design", "UI_Design"],
        "photography": ["photography", "videography", "Filmmakers", "editors"],
        "writing": ["writing", "selfpublish", "blogging", "copywriting"],
        
        // Lifestyle
        "productivity": ["productivity", "Notion", "ObsidianMD", "PKMS"],
        "health": ["HealthIT", "digitalhealth", "fitness", "mentalhealth"],
        "food": ["Cooking", "MealPrepSunday", "EatCheapAndHealthy", "fooddelivery"],
        "education": ["edtech", "OnlineLearning", "learnprogramming", "AskAcademia"],
        "gaming": ["gamedev", "IndieGaming", "gaming", "GameDesign"],
        
        // Islam & Muslim-Specific (DO NOT mix with other religions)
        "islam": ["islam", "MuslimLounge", "Quran", "izlam", "hijabis", "islamicfinance",
                  "progressive_islam", "muslimtechnet", "MuslimMarriage", "Islaam",
                  "converttoislam", "LightUponLight", "IslamicStudies"],
        
        // Arabic & Middle Eastern
        "arabic": ["learn_arabic", "arabic", "arabs", "ArabCulture"],
        "middleeast": ["MiddleEast", "saudiarabia", "UAE", "Egypt", "Jordan"],
        
        // Other Religions — SEPARATE from Islam, only matched by their own triggers
        "christianity": ["Christianity", "TrueChristian", "Bible", "Reformed"],
        "buddhism": ["Buddhism", "Meditation", "zen", "Mindfulness"],
        "judaism": ["Judaism", "jewish", "Torah"],
        "hinduism": ["hinduism", "Hindu"],
        "general_religion": ["religion", "spirituality"],
        
        // Meditation & mindfulness — secular or general
        "meditation": ["Meditation", "Mindfulness", "yoga", "zenhabits"],
        
        // Niche
        "crypto": ["CryptoCurrency", "ethereum", "defi", "web3"],
        "travel": ["travel", "solotravel", "backpacking", "digitalnomad"],
        "parenting": ["Parenting", "Mommit", "daddit", "beyondthebump"],
        "pets": ["dogs", "cats", "pets", "Dogtraining"],
        "music": ["WeAreTheMusicMakers", "musicproduction", "Guitar", "piano"],
        "sports": ["sports", "running", "bodyweightfitness", "homegym"],
        
        "general": ["Entrepreneur", "startups", "smallbusiness", "SideProject"],
    ]
    
    // MARK: - Category Detection — PRECISE triggers
    // Order matters: more specific patterns should come BEFORE generic ones.
    
    private static let categoryTriggers: [(pattern: String, category: String)] = [
        // Tech
        ("saas|subscription|recurring", "saas"),
        ("develop|code|program|api|sdk|github", "devtools"),
        ("mobile|ios|android|phone|iphone|ipad|swift", "mobile"),
        ("ai|artificial|machine learn|gpt|llm|neural|chatbot", "ai"),
        
        // Business
        ("ecommerce|shop|store|sell online|etsy|amazon|product listing", "ecommerce"),
        ("market|seo|ads|advertis|brand|social media|content", "marketing"),
        ("financ|money|account|budget|invoice|tax|payment", "finance"),
        ("real estate|property|rent|landlord|tenant|mortgage", "realestate"),
        ("freelanc|consult|agency|client", "consulting"),
        
        // Creative
        ("design|creative|ui|ux|figma|sketch", "design"),
        ("photo|camera|image|video|film|edit", "photography"),
        ("writ|blog|publish|book|author|copywriting", "writing"),
        
        // Lifestyle
        ("productiv|task|todo|note|organiz|planner|workflow", "productivity"),
        ("health|fitness|wellness|medical|doctor|patient|therap", "health"),
        ("food|cook|meal|restaurant|delivery|recipe|nutrition", "food"),
        ("educ|learn|course|teach|tutor|student|school|universit", "education"),
        ("game|gaming|player|multiplayer|indie game", "gaming"),
        
        // RELIGION — Specific religions FIRST, generic religion LAST
        // Islam-specific (comprehensive — catches Quran apps, Muslim tools, etc.)
        ("quran|qur'an|islamic|islam|muslim|mosque|prayer|salah|dua|hadith|sunnah|ramadan|eid|hijab|halal|imam|sheikh|fiqh|tafsir|surah|ayah|allah|prophet|muhammad|mecca|medina|ummah|dawah|zakat|hajj|umrah", "islam"),
        ("arabic|arab|عرب|القرآن", "arabic"),
        ("middle east|saudi|uae|egypt|jordan|gulf|khalij", "middleeast"),
        
        // Other specific religions — only match when explicitly mentioned
        ("christian|church|bible|gospel|jesus|baptist|catholic|protestant", "christianity"),
        ("buddhis|zen|dharma|sangha|siddhartha|nirvana|vipassana", "buddhism"),
        ("jewish|judaism|torah|synagogue|rabbi|kosher|shabbat", "judaism"),
        ("hindu|vedic|vedanta|karma|dharma|temple|puja|diwali", "hinduism"),
        
        // Generic religion/spirituality — ONLY if no specific religion matched
        ("religio|spiritual|faith|worship|soul", "general_religion"),
        
        // Meditation — separate from religion (many secular meditation apps)
        ("meditat|mindful|calm|breathe|relax|stress relief", "meditation"),
        
        // Niche
        ("crypto|blockchain|web3|bitcoin|ethereum|nft", "crypto"),
        ("travel|trip|flight|hotel|destination|backpack|nomad", "travel"),
        ("parent|child|baby|kid|family|mom|dad|toddler", "parenting"),
        ("pet|dog|cat|puppy|kitten|animal", "pets"),
        ("music|song|instrument|guitar|piano|drum|produc", "music"),
        ("sport|gym|workout|running|yoga|swim|train", "sports"),
    ]
    
    // MARK: - Public API
    
    static func analyze(description: String) -> AnalysisResult {
        let desc = description.lowercased()
        var keywords = Set<String>()
        var categories = Set<String>()
        
        // 1. Detect categories from description
        for trigger in categoryTriggers {
            if desc.range(of: trigger.pattern, options: .regularExpression) != nil {
                categories.insert(trigger.category)
            }
        }
        
        // Special rule: If "islam" matched, DON'T also add generic religion or other religions
        if categories.contains("islam") {
            categories.remove("general_religion")
            categories.remove("christianity")
            categories.remove("buddhism")
            categories.remove("judaism")
            categories.remove("hinduism")
        }
        
        if categories.isEmpty { categories.insert("general") }
        
        // 2. Use NaturalLanguage framework for smart keyword extraction
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = description
        
        var nouns: [String] = []
        var adjectives: [String] = []
        
        tagger.enumerateTags(in: description.startIndex..<description.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(description[range]).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard word.count > 2, !stopWords.contains(word) else { return true }
            
            if tag == .noun {
                nouns.append(word)
            } else if tag == .adjective {
                adjectives.append(word)
            }
            return true
        }
        
        // Deduplicate nouns while preserving order
        var seenNouns = Set<String>()
        nouns = nouns.filter { seenNouns.insert($0).inserted }
        
        var seenAdj = Set<String>()
        adjectives = adjectives.filter { seenAdj.insert($0).inserted }
        
        // 3. Build meaningful keyword phrases
        // Single important nouns
        for noun in nouns {
            guard noun.count > 3 else { continue }
            keywords.insert(noun)
        }
        
        // Adjective + noun pairs (e.g. "quran reader", "islamic app", "daily prayers")
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        for i in 0..<(words.count - 1) {
            let w1 = words[i].trimmingCharacters(in: .punctuationCharacters)
            let w2 = words[i + 1].trimmingCharacters(in: .punctuationCharacters)
            guard w1.count > 2, w2.count > 2 else { continue }
            guard !stopWords.contains(w1), !stopWords.contains(w2) else { continue }
            
            // Only pair if both are meaningful (at least one is a noun)
            if nouns.contains(w1) || nouns.contains(w2) {
                keywords.insert("\(w1) \(w2)")
            }
        }
        
        // 3-word phrases for really specific terms
        for i in 0..<(words.count - 2) {
            let w1 = words[i].trimmingCharacters(in: .punctuationCharacters)
            let w2 = words[i + 1].trimmingCharacters(in: .punctuationCharacters)
            let w3 = words[i + 2].trimmingCharacters(in: .punctuationCharacters)
            guard w1.count > 2, w2.count > 2, w3.count > 2 else { continue }
            let nonStopCount = [w1, w2, w3].filter { !stopWords.contains($0) }.count
            if nonStopCount >= 2 && (nouns.contains(w1) || nouns.contains(w3)) {
                keywords.insert("\(w1) \(w2) \(w3)")
            }
        }
        
        // 4. Add intent/recommendation search phrases using the TOP UNIQUE domain noun
        // Only use the first (most relevant) noun to avoid noise
        if let primaryNoun = nouns.first {
            keywords.insert("looking for \(primaryNoun)")
            keywords.insert("\(primaryNoun) recommendation")
            keywords.insert("\(primaryNoun) alternative")
        }
        
        // 5. Collect subreddits from detected categories
        var subreddits = Set<String>()
        for cat in categories {
            if let subs = subredditMap[cat] {
                subs.forEach { subreddits.insert($0) }
            }
        }
        
        // 6. Generate a CLEAN profile name
        // Take unique meaningful nouns in order, max 3, skip duplicates
        let profileName = generateProfileName(from: description, nouns: nouns, adjectives: adjectives, categories: categories)
        
        // Sort keywords by length (longer = more specific = better), take top 10
        let sortedKeywords = Array(keywords)
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { String($0) }
        
        return AnalysisResult(
            keywords: sortedKeywords,
            subreddits: Array(subreddits).sorted().prefix(8).map { String($0) },
            profileName: profileName
        )
    }
    
    // MARK: - Smart Profile Name Generation
    
    /// Generates a clean, human-readable profile name like "Quran Meditation App"
    private static func generateProfileName(from description: String, nouns: [String], adjectives: [String], categories: Set<String>) -> String {
        // Strategy: pick the 2-3 most descriptive words from the description
        // Priority: adjective + noun combos > pure nouns > category fallback
        
        var nameWords: [String] = []
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // Walk through the description in order, pick meaningful words
        var seen = Set<String>()
        for word in words {
            guard !stopWords.contains(word) else { continue }
            guard seen.insert(word).inserted else { continue } // Skip duplicates
            
            if nouns.contains(word) || adjectives.contains(word) {
                nameWords.append(word.capitalized)
                if nameWords.count >= 3 { break }
            }
        }
        
        // If we got too few, add category context
        if nameWords.count < 2 {
            // Use the primary category as a fallback
            if let cat = categories.first(where: { $0 != "general" }) {
                nameWords.append(cat.capitalized)
            }
        }
        
        let name = nameWords.joined(separator: " ")
        return name.isEmpty ? "My Product" : name
    }
}
