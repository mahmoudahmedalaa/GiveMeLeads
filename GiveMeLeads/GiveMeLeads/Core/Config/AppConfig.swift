import Foundation

/// App-wide configuration loaded from environment
enum AppConfig {
    // Supabase
    static let supabaseURL = "https://sgsugbwxkqcdxbulsrgt.supabase.co"
    static let supabaseAnonKey = "sb_publishable_l2DpNT2iaR8xbnQuVmgt3g_jbWY4SXC"
    
    // Reddit
    static let redditClientID = "placeholder"
    static let redditClientSecret = "placeholder"
    
    // RevenueCat
    static let revenueCatAPIKey = "placeholder"
    
    // App
    static let appName = "GiveMeLeads"
    static let maxProfiles = 3
    static let maxKeywordsPerProfile = 10
    static let defaultScoreThreshold = 80
    static let maxNotificationsPerDay = 10
    static let trialDurationDays = 7
    static let subscriptionPrice = "$19"
    static let subscriptionPeriod = "month"
    
    // Reddit API
    static let redditBaseURL = "https://oauth.reddit.com"
    static let redditAuthURL = "https://www.reddit.com/api/v1/access_token"
    static let redditSearchLimit = 100
    static let redditScanIntervalMinutes = 30
}
