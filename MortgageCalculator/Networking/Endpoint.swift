import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum Endpoint {
    case calculateMortgage(MortgageRequest)
    case getRates
    case saveScenario(MortgageScenario)
    
    var path: String {
        switch self {
        case .calculateMortgage:
            return "/calculate"
        case .getRates:
            return "/rates"
        case .saveScenario:
            return "/scenarios"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .calculateMortgage:
            return .post
        case .getRates:
            return .get
        case .saveScenario:
            return .post
        }
    }
    
    var headers: [String: String] {
        var headers = ["Accept": "application/json"]
        // Add any additional headers here (e.g., authentication)
        return headers
    }
    
    var body: Encodable? {
        switch self {
        case .calculateMortgage(let request):
            return request
        case .getRates:
            return nil
        case .saveScenario(let scenario):
            return scenario
        }
    }
} 