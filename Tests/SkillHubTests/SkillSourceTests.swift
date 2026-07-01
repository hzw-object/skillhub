import Testing
@testable import SkillHub

@Suite("SkillSource")
struct SkillSourceTests {
    @Test("allCases order is fixed")
    func allCasesOrder() {
        #expect(
            SkillSource.allCases.map(\.rawValue)
            == ["personal", "superpowers", "frontend_design", "ponytail", "glm_plan_usage", "other"]
        )
    }

    @Test("id is rawValue")
    func idIsRawValue() {
        #expect(SkillSource.personal.id == "personal")
    }

    @Test("displayName is non-empty for every case")
    func displayNameNonEmpty() {
        for s in SkillSource.allCases {
            #expect(!s.displayName.isEmpty, "\(s) has empty displayName")
        }
    }

    @Test("icon is a non-empty SF Symbol name for every case")
    func iconIsSFSymbolName() {
        for s in SkillSource.allCases {
            #expect(!s.icon.isEmpty, "\(s) has empty icon")
        }
    }
}
