import XCTest
@testable import GiveMeLeads

final class LeadTests: XCTestCase {
    func testLeadSampleDataExists() {
        XCTAssertFalse(Lead.samples.isEmpty)
    }
    
    func testLeadScoreColor() {
        XCTAssertEqual(Lead.samples[0].score != nil, true)
    }
    
    func testLeadStatusDisplayName() {
        let status = LeadStatus.new
        XCTAssertEqual(status.displayName, "New")
    }
}
