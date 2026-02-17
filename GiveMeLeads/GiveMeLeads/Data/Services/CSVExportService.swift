import Foundation

/// Service for exporting saved leads as CSV
final class CSVExportService {
    
    /// Generate a CSV string from an array of leads
    static func generateCSV(from leads: [Lead]) -> String {
        var csv = "Title,Subreddit,Author,Score,Status,Posted,Discovered,URL,Insight,Approach\n"
        
        for lead in leads {
            let fields = [
                escapeCSV(lead.title),
                escapeCSV("r/\(lead.subreddit)"),
                escapeCSV("u/\(lead.author)"),
                "\(lead.score ?? 0)",
                lead.status.displayName,
                formatDate(lead.postedAt),
                formatDate(lead.discoveredAt),
                escapeCSV(lead.url),
                escapeCSV(lead.relevanceInsight ?? ""),
                escapeCSV(lead.suggestedApproach ?? ""),
            ]
            csv += fields.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    /// Generate a temporary file URL for the CSV
    static func generateCSVFile(from leads: [Lead]) throws -> URL {
        let csv = generateCSV(from: leads)
        let fileName = "GiveMeLeads_Export_\(dateStamp()).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Private
    
    private static func escapeCSV(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
        return "\"\(escaped)\""
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
