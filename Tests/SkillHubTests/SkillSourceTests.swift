import XCTest
@testable import SkillHub

final class SkillSourceTests: XCTestCase {
    func testAllCasesOrder() {
        XCTAssertEqual(
            SkillSource.allCases.map(\.rawValue),
            ["personal", "superpowers", "frontend_design", "ponytail", "glm_plan_usage", "other"]
        )
    }

    func testIdIsRawValue() {
        XCTAssertEqual(SkillSource.personal.id, "personal")
    }

    func testDisplayNameNonEmpty() {
        for s in SkillSource.allCases {
            XCTAssertFalse(s.displayName.isEmpty, "\(s) has empty displayName")
        }
    }

    func testIconIsSFSymbolName() {
        for s in SkillSource.allCases {
            XCTAssertFalse(s.icon.isEmpty, "\(s) has empty icon")
        }
    }
}
