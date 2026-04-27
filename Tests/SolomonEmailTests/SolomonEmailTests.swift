import Testing
@testable import SolomonEmail

@Test func tenSenderCategoriesDeclared() {
    #expect(SolomonEmail.senderCategories.count == 10)
}
