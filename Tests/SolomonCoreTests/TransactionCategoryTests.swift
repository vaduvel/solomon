import Testing
import Foundation
@testable import SolomonCore

@Suite struct TransactionCategoryTests {

    @Test func seventeenCategoriesDeclared() {
        // Spec §6.1 listează 17 categorii standard.
        #expect(TransactionCategory.allCases.count == 17)
    }

    @Test func rawValuesUseSpecSnakeCase() {
        #expect(TransactionCategory.foodGrocery.rawValue == "food_grocery")
        #expect(TransactionCategory.foodDelivery.rawValue == "food_delivery")
        #expect(TransactionCategory.rentMortgage.rawValue == "rent_mortgage")
        #expect(TransactionCategory.shoppingOnline.rawValue == "shopping_online")
        #expect(TransactionCategory.loansIFN.rawValue == "loans_ifn")
        #expect(TransactionCategory.bnpl.rawValue == "bnpl")
        #expect(TransactionCategory.unknown.rawValue == "unknown")
    }

    @Test func everyCategoryHasRomanianDisplayName() {
        for category in TransactionCategory.allCases {
            #expect(!category.displayNameRO.isEmpty)
        }
    }

    @Test func debtCategoriesIncludeIFNBNPLBankLoans() {
        #expect(TransactionCategory.debtCategories.contains(.loansIFN))
        #expect(TransactionCategory.debtCategories.contains(.loansBank))
        #expect(TransactionCategory.debtCategories.contains(.bnpl))
        #expect(TransactionCategory.debtCategories.count == 3)
    }

    @Test func grouping() {
        #expect(TransactionCategory.rentMortgage.group == .essentials)
        #expect(TransactionCategory.foodDelivery.group == .lifestyle)
        #expect(TransactionCategory.loansIFN.group == .debt)
        #expect(TransactionCategory.savings.group == .savings)
        #expect(TransactionCategory.unknown.group == .other)
    }

    @Test func codableRoundTrip() throws {
        let original: [TransactionCategory] = [.foodDelivery, .rentMortgage, .loansIFN]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([TransactionCategory].self, from: data)
        #expect(decoded == original)
    }
}
