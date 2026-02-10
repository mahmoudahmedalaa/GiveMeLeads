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
        // Filler / context
        "like", "look", "looking", "thing", "things", "way", "ways", "people", "user", "users",
        "app", "tool", "platform", "software", "built", "build", "create", "offer", "offers",
        "based", "using", "allows", "able", "kind", "sort", "type", "here", "there", "where",
        "when", "what", "how", "which", "while", "then", "now", "not", "don", "doesn",
    ]
    
    // MARK: - Subreddit Map (much broader coverage)
    
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
        
        // Religion & Spirituality
        "islam": ["islam", "MuslimLounge", "Quran", "izlam", "hijabis", "islamicfinance"],
        "religion": ["religion", "spirituality", "meditation", "Buddhism", "Christianity"],
        "arabic": ["learn_arabic", "arabic", "arabs", "ArabCulture"],
        
        // Regional / Cultural
        "middleeast": ["MiddleEast", "saudiarabia", "UAE", "Egypt", "Jordan"],
        
        // Niche
        "crypto": ["CryptoCurrency", "ethereum", "defi", "web3"],
        "travel": ["travel", "solotravel", "backpacking", "digitalnomad"],
        "parenting": ["Parenting", "Mommit", "daddit", "beyondthebump"],
        "pets": ["dogs", "cats", "pets", "Dogtraining"],
        "music": ["WeAreTheMusicMakers", "musicproduction", "Guitar", "piano"],
        "sports": ["sports", "running", "bodyweightfitness", "homegym"],
        
        "general": ["Entrepreneur", "startups", "smallbusiness", "SideProject"],
    ]
    
    // MARK: - Category Detection (broader coverage)
    
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
        ("writ|blog|publish|book|author|content|copywriting", "writing"),
        
        // Lifestyle
        ("productiv|task|todo|note|organiz|planner|workflow", "productivity"),
        ("health|fitness|wellness|medical|doctor|patient|therap", "health"),
        ("food|cook|meal|restaurant|delivery|recipe|nutrition", "food"),
        ("educ|learn|course|teach|tutor|student|school|universit", "education"),
        ("game|gaming|player|multiplayer|indie game", "gaming"),
        
        // Religion & Spirituality
        ("quran|qur'an|islamic|islam|muslim|mosque|prayer|salah|dua|hadith|sunnah|ramadan|eid|hijab|halal|imam|sheikh|fiqh|tafsir|surah|ayah|allah|prophet|muhammad|mecca|medina|ummah|dawah|zakat|hajj|umrah", "islam"),
        ("arabic|arab|عرب|القرآن", "arabic"),
        ("middle east|saudi|uae|egypt|jordan|gulf|khalij", "middleeast"),
        ("religio|spiritual|faith|church|temple|worship|pray|meditation|mindful|soul", "religion"),
        
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
        
        // 4. Add intent/recommendation search phrases using top nouns
        let topNouns = Array(nouns.prefix(3))
        for noun in topNouns {
            keywords.insert("looking for \(noun)")
            keywords.insert("\(noun) recommendation")
            keywords.insert("best \(noun)")
            keywords.insert("\(noun) alternative")
        }
        
        // 5. Collect subreddits from detected categories
        var subreddits = Set<String>()
        for cat in categories {
            if let subs = subredditMap[cat] {
                subs.forEach { subreddits.insert($0) }
            }
        }
        
        // 6. Also try to find subreddit-worthy terms directly from description
        // If we found specific nouns, add them as potential subreddit names
        for noun in topNouns {
            // Capitalize for subreddit format
            subreddits.insert(noun)
        }
        
        // 7. Generate profile name from top nouns
        let profileName = topNouns.prefix(3)
            .map { $0.capitalized }
            .joined(separator: " ")
        
        // Sort keywords by length (longer = more specific = better), take top 10
        let sortedKeywords = Array(keywords)
            .sorted { $0.count > $1.count }
            .prefix(12)
            .map { String($0) }
        
        return AnalysisResult(
            keywords: sortedKeywords,
            subreddits: Array(subreddits).sorted().prefix(8).map { String($0) },
            profileName: profileName.isEmpty ? "My Product" : profileName
        )
    }
}
