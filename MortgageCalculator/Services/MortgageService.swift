import Foundation

@MainActor
class MortgageService {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func calculateMortgage(request: MortgageRequest) async throws -> MortgageResponse {
        return try await apiClient.fetch(.calculateMortgage(request))
    }
    
    func getCurrentRates() async throws -> RatesResponse {
        return try await apiClient.fetch(.getRates)
    }
    
    func saveScenario(_ scenario: MortgageScenario) async throws {
        let _: EmptyResponse = try await apiClient.fetch(.saveScenario(scenario))
    }
}

// Helper type for endpoints that don't return data
private struct EmptyResponse: Codable {} 