import Foundation
import NaturalLanguage

/// On-device product analysis — extracts meaningful keywords and suggests relevant subreddits
/// from a user's product description using Apple's NaturalLanguage framework.
///
/// DESIGN PRINCIPLES:
/// 1. Subreddits must be WHERE PEOPLE DISCOVER AND DISCUSS PRODUCTS/APPS — NOT lifestyle/community subs
/// 2. Keywords must be PRODUCT-SEARCH phrases — "best quran app", "recommend quran app", not just "quran"
/// 3. Categories match ONLY on explicit domain words, never on generic terms
/// 4. SALES MINDSET: every subreddit must answer "would someone here BUY my product?"
enum ProductAnalyzer {
    
    struct AnalysisResult {
        let keywords: [String]
        let subreddits: [String]
        let profileName: String
    }
    
    // MARK: - Stop Words (expanded)
    
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
        "provide", "provides", "product", "service", "services", "solution", "solutions",
        "feature", "features", "mobile", "web", "online", "digital", "modern",
        "application", "applications", "system", "systems",
    ]
    
    // MARK: - Subreddit Map — PRODUCT DISCOVERY communities only
    //
    // SALES RULE: Every subreddit must be a place where someone would:
    //   ✅ Ask "what app should I use for X?"
    //   ✅ Post "looking for an app that does X"
    //   ✅ Discuss products, tools, and recommendations
    //
    // DO NOT include subreddits for:
    //   ❌ Personal advice (MuslimMarriage, relationships, AITA)
    //   ❌ Life issues / emotional support
    //   ❌ Developer communities (FlutterDev, SwiftUI)
    //   ❌ Meme/culture subs (izlam)
    //   ❌ Generic community subs without product discussion
    
    private static let subredditMap: [String: [String]] = [
        // Islam — PRODUCT-relevant subs only (where people ask about apps/tools)
        "islam": ["islam", "MuslimLounge", "Quran", "hijabis",
                  "progressive_islam", "converts"],
        
        // Arabic & Middle Eastern — language learning (app discovery)
        "arabic": ["learn_arabic", "arabic", "languagelearning"],
        "middleeast": ["saudiarabia", "UAE", "Egypt"],
        
        // Other Religions — ONLY subs where people discuss tools/apps
        "christianity": ["Christianity", "TrueChristian", "Bible"],
        "buddhism": ["Buddhism", "Meditation"],
        "judaism": ["Judaism", "jewish"],
        "hinduism": ["hinduism"],
        "general_religion": ["religion", "spirituality"],
        
        // Meditation & mindfulness — app-discovery focused
        "meditation": ["Meditation", "Mindfulness"],
        
        // Business & Entrepreneurship
        "startup": ["Entrepreneur", "startups", "smallbusiness", "SideProject", "indiehackers"],
        "ecommerce": ["ecommerce", "shopify", "FulfillmentByAmazon", "Etsy"],
        "marketing": ["marketing", "digital_marketing", "SEO", "socialmedia", "content_marketing"],
        "finance": ["personalfinance", "FinancialPlanning", "Bookkeeping"],
        "realestate": ["realestateinvesting", "RealEstate", "landlords"],
        "freelance": ["freelance", "WorkOnline", "remotework", "digitalnomad"],
        
        // Productivity & Tools — HIGH app-discovery traffic
        "productivity": ["productivity", "Notion", "ObsidianMD", "PKMS", "getdisciplined", "apps"],
        "projectmanagement": ["projectmanagement", "scrum", "agile"],
        
        // Health & Wellness — app-focused subs
        "health": ["digitalhealth", "fitness", "selfimprovement", "mentalhealth"],
        "diet": ["loseit", "nutrition", "MealPrepSunday"],
        
        // Education — learning app discovery
        "education": ["edtech", "OnlineLearning", "GetStudying", "languagelearning"],
        
        // Creative — tool/software focused
        "design": ["graphic_design", "web_design", "UI_Design"],
        "photography": ["photography", "videography"],
        "writing": ["writing", "selfpublish", "blogging", "copywriting"],
        "music": ["WeAreTheMusicMakers", "musicproduction"],
        
        // Lifestyle
        "food": ["Cooking", "MealPrepSunday", "recipes"],
        "gaming": ["gaming", "IndieGaming"],
        "travel": ["travel", "solotravel", "digitalnomad"],
        "parenting": ["Parenting", "Mommit", "daddit"],
        "pets": ["dogs", "cats", "Dogtraining"],
        "sports": ["running", "bodyweightfitness", "homegym"],
        
        // Tech — user-facing
        "ai_users": ["ChatGPT", "artificial", "singularity"],
        "crypto": ["CryptoCurrency", "ethereum", "Bitcoin"],
        "saas": ["SaaS", "microsaas"],
        
        // Catch-all
        "general": ["Entrepreneur", "startups", "smallbusiness", "SideProject"],
    ]
    
    // MARK: - Category Detection — STRICT triggers
    
    private static let categoryTriggers: [(words: [String], category: String)] = [
        // Islam
        (["quran", "qur'an", "islamic", "islam", "muslim", "mosque", "salah", "dua", "hadith",
          "sunnah", "ramadan", "eid", "hijab", "halal", "imam", "sheikh", "fiqh", "tafsir",
          "surah", "ayah", "allah", "prophet", "muhammad", "mecca", "medina", "ummah", "dawah",
          "zakat", "hajj", "umrah", "adhan", "wudu", "dhikr"], "islam"),
        
        (["arabic", "arab", "عرب", "القرآن"], "arabic"),
        (["middle east", "saudi", "uae", "egypt", "jordan", "gulf", "khalij"], "middleeast"),
        
        // Other religions
        (["christian", "church", "bible", "gospel", "jesus", "baptist", "catholic", "protestant"], "christianity"),
        (["buddhist", "buddhism", "dharma", "sangha", "nirvana", "vipassana"], "buddhism"),
        (["jewish", "judaism", "torah", "synagogue", "rabbi", "kosher", "shabbat"], "judaism"),
        (["hindu", "hinduism", "vedic", "vedanta", "temple", "puja", "diwali"], "hinduism"),
        (["religion", "religious", "spiritual", "spirituality", "faith", "worship"], "general_religion"),
        
        // Meditation
        (["meditation", "meditate", "mindfulness", "mindful", "breathwork", "calm", "stress relief"], "meditation"),
        
        // Business
        (["startup", "entrepreneur", "side project", "indie hacker", "bootstrapped", "solopreneur"], "startup"),
        (["ecommerce", "e-commerce", "online store", "shopify", "etsy", "amazon seller", "dropship"], "ecommerce"),
        (["marketing", "seo", "advertising", "social media marketing", "content marketing",
          "email marketing", "growth hacking", "lead generation"], "marketing"),
        (["finance", "financial", "accounting", "bookkeeping", "invoice", "tax", "budget",
          "payment", "billing", "debt", "loan", "refinanc", "mortgage"], "finance"),
        (["real estate", "property", "rent", "landlord", "tenant", "mortgage", "housing"], "realestate"),
        (["freelance", "freelancer", "contractor", "remote work", "work from home", "gig economy"], "freelance"),
        
        // Productivity
        (["productivity", "task management", "project management", "todo", "to-do", "planner",
          "workflow", "time management", "organize", "note-taking", "notes app"], "productivity"),
        (["project management", "scrum", "agile", "kanban", "sprint", "jira"], "projectmanagement"),
        
        // Health
        (["health", "fitness", "wellness", "medical", "doctor", "patient", "therapy",
          "mental health", "anxiety", "depression", "workout", "exercise"], "health"),
        (["diet", "nutrition", "weight loss", "meal prep", "calories", "keto", "vegan"], "diet"),
        
        // Education
        (["education", "learning", "course", "teach", "tutor", "student", "school",
          "university", "study", "homework", "classroom", "e-learning"], "education"),
        
        // Creative
        (["graphic design", "logo design", "illustration", "ui design", "ux design",
          "web design", "branding", "visual design"], "design"),
        (["photography", "photographer", "camera", "photo editing", "videography",
          "filmmaker", "video editing", "cinematography"], "photography"),
        (["writing", "writer", "blog", "publish", "author", "copywriting", "content writing"], "writing"),
        (["music", "musician", "song", "instrument", "guitar", "piano", "drum",
          "music production", "beat", "recording"], "music"),
        
        // Lifestyle
        (["cooking", "recipe", "meal", "restaurant", "food delivery", "chef", "baking"], "food"),
        (["gaming", "gamer", "video game", "game design", "esports", "twitch"], "gaming"),
        (["travel", "trip", "flight", "hotel", "destination", "backpack", "nomad", "tourism"], "travel"),
        (["parenting", "parent", "child", "baby", "kid", "family", "mom", "dad", "toddler"], "parenting"),
        (["pet", "dog", "cat", "puppy", "kitten", "animal", "veterinary"], "pets"),
        (["sport", "gym", "workout", "running", "marathon", "swim", "cycling", "yoga"], "sports"),
        
        // Tech
        (["chatgpt", "ai assistant", "artificial intelligence", "machine learning", "llm", "chatbot"], "ai_users"),
        (["cryptocurrency", "crypto", "bitcoin", "ethereum", "blockchain", "nft", "defi", "web3"], "crypto"),
        (["saas", "subscription software", "recurring revenue", "cloud software"], "saas"),
    ]
    
    // MARK: - Public API
    
    static func analyze(description: String) -> AnalysisResult {
        let desc = description.lowercased()
        var keywords = Set<String>()
        var categories = Set<String>()
        
        // 1. Detect categories using EXACT WORD matching
        let descWords = Set(desc.components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty })
        
        for trigger in categoryTriggers {
            var matched = false
            for word in trigger.words {
                if word.contains(" ") {
                    if desc.contains(word) {
                        matched = true
                        break
                    }
                } else {
                    if descWords.contains(word) {
                        matched = true
                        break
                    }
                }
            }
            if matched {
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
        
        // Similarly for other specific religions
        if categories.contains("christianity") || categories.contains("buddhism") ||
           categories.contains("judaism") || categories.contains("hinduism") {
            categories.remove("general_religion")
        }
        
        if categories.isEmpty { categories.insert("general") }
        
        // 2. Use NaturalLanguage for smart noun/adjective extraction
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = description
        
        var nouns: [String] = []
        var adjectives: [String] = []
        
        tagger.enumerateTags(in: description.startIndex..<description.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(description[range]).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard word.count > 2, !stopWords.contains(word) else { return true }
            
            if tag == .noun { nouns.append(word) }
            else if tag == .adjective { adjectives.append(word) }
            return true
        }
        
        // Deduplicate while preserving order
        var seenNouns = Set<String>()
        nouns = nouns.filter { seenNouns.insert($0).inserted }
        var seenAdj = Set<String>()
        adjectives = adjectives.filter { seenAdj.insert($0).inserted }
        
        // 3. Build PRODUCT-SEARCH keywords
        // The KEY insight: keywords MUST include "app" or "tool" context so we find
        // posts where people are looking for PRODUCTS, not just discussing topics
        
        // Core domain nouns
        for noun in nouns where noun.count > 3 {
            keywords.insert(noun)
        }
        
        // Adjacent word pairs from the description
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        for i in 0..<(words.count - 1) {
            let w1 = words[i].trimmingCharacters(in: .punctuationCharacters)
            let w2 = words[i + 1].trimmingCharacters(in: .punctuationCharacters)
            guard w1.count > 2, w2.count > 2 else { continue }
            guard !stopWords.contains(w1), !stopWords.contains(w2) else { continue }
            if nouns.contains(w1) || nouns.contains(w2) {
                keywords.insert("\(w1) \(w2)")
            }
        }
        
        // 4. Generate PRODUCT-INTENT search phrases
        // These MUST include "app" / "tool" context to ensure we find product-seekers
        if let primaryNoun = nouns.first {
            // Product-specific queries — these find BUYERS
            keywords.insert("best \(primaryNoun) app")
            keywords.insert("\(primaryNoun) app recommendation")
            keywords.insert("recommend \(primaryNoun) app")
            keywords.insert("looking for \(primaryNoun) app")
            keywords.insert("\(primaryNoun) app alternative")
            
            // Still include generic but they'll be lower priority
            keywords.insert("best \(primaryNoun)")
            keywords.insert("\(primaryNoun) recommendation")
            
            if nouns.count > 1 {
                let secondNoun = nouns[1]
                keywords.insert("\(primaryNoun) \(secondNoun) app")
                keywords.insert("best \(primaryNoun) \(secondNoun)")
            }
        }
        
        // 5. Collect subreddits from detected categories
        var subreddits = Set<String>()
        for cat in categories {
            if let subs = subredditMap[cat] {
                subs.forEach { subreddits.insert($0) }
            }
        }
        
        // 6. Generate clean profile name
        let profileName = generateProfileName(from: description, nouns: nouns, adjectives: adjectives, categories: categories)
        
        // Sort keywords: longer (more specific) first, take top 12
        let sortedKeywords = Array(keywords)
            .sorted { $0.count > $1.count }
            .prefix(12)
            .map { String($0) }
        
        return AnalysisResult(
            keywords: sortedKeywords,
            subreddits: Array(subreddits).sorted().prefix(8).map { String($0) },
            profileName: profileName
        )
    }
    
    // MARK: - Profile Name Generation
    
    private static func generateProfileName(from description: String, nouns: [String], adjectives: [String], categories: Set<String>) -> String {
        var nameWords: [String] = []
        let words = description.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && $0.count > 2 }
        
        var seen = Set<String>()
        for word in words {
            guard !stopWords.contains(word) else { continue }
            guard seen.insert(word).inserted else { continue }
            if nouns.contains(word) || adjectives.contains(word) {
                nameWords.append(word.capitalized)
                if nameWords.count >= 3 { break }
            }
        }
        
        if nameWords.count < 2 {
            if let cat = categories.first(where: { $0 != "general" }) {
                nameWords.append(cat.capitalized)
            }
        }
        
        let name = nameWords.joined(separator: " ")
        return name.isEmpty ? "My Product" : name
    }
}
