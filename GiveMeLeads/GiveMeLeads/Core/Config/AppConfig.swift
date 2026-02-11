import Foundation

/// App-wide configuration loaded from environment
enum AppConfig {
    // Supabase
    static let supabaseURL = "https://sgsugbwxkqcdxbulsrgt.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnc3VnYnd4a3FjZHhidWxzcmd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NTAwOTMsImV4cCI6MjA4NjIyNjA5M30.5AaZkPt1x-KA3AEFOAE3td-4_sDyMbS1NlbV10Tfgz4"
    
    // Reddit
    static let redditClientID = "placeholder"
    static let redditClientSecret = "placeholder"
    
    // RevenueCat
    static let revenueCatAPIKey = "placeholder"
    
    // App
    static let appName = "GiveMeLeads"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
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
