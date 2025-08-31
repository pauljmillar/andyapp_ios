//
//  APIService.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import Combine

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://survey-khaki-chi.vercel.app"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - Generic Request Method
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication Endpoints
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let loginRequest = LoginRequest(email: email, password: password)
        let body = try? JSONEncoder().encode(loginRequest)
        
        return makeRequest(
            endpoint: "/api/auth/login",
            method: .POST,
            body: body,
            responseType: APIResponse<AuthResponse>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, firstName: String?, lastName: String?) -> AnyPublisher<AuthResponse, APIError> {
        let registerRequest = RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName)
        let body = try? JSONEncoder().encode(registerRequest)
        
        return makeRequest(
            endpoint: "/api/auth/register",
            method: .POST,
            body: body,
            responseType: APIResponse<AuthResponse>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - User Profile Endpoints
    func getUserProfile() -> AnyPublisher<UserProfile, APIError> {
        return makeRequest(
            endpoint: "/api/user/profile",
            responseType: APIResponse<UserProfile>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Surveys Endpoints
    func getSurveys(category: SurveyCategory? = nil, page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<Survey>, APIError> {
        var endpoint = "/api/surveys?page=\(page)&limit=\(limit)"
        if let category = category {
            endpoint += "&category=\(category.rawValue)"
        }
        
        return makeRequest(
            endpoint: endpoint,
            responseType: PaginatedResponse<Survey>.self
        )
        .eraseToAnyPublisher()
    }
    
    func getSurvey(id: String) -> AnyPublisher<Survey, APIError> {
        return makeRequest(
            endpoint: "/api/surveys/\(id)",
            responseType: APIResponse<Survey>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    func submitSurveyResponse(_ response: SurveyResponse) -> AnyPublisher<PointsTransaction, APIError> {
        let body = try? JSONEncoder().encode(response)
        
        return makeRequest(
            endpoint: "/api/surveys/\(response.surveyId)/submit",
            method: .POST,
            body: body,
            responseType: APIResponse<PointsTransaction>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Points Endpoints
    func getPointsHistory(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<PointsTransaction>, APIError> {
        return makeRequest(
            endpoint: "/api/points/history?page=\(page)&limit=\(limit)",
            responseType: PaginatedResponse<PointsTransaction>.self
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Mail Endpoints
    func getMailMessages(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<MailMessage>, APIError> {
        return makeRequest(
            endpoint: "/api/mail?page=\(page)&limit=\(limit)",
            responseType: PaginatedResponse<MailMessage>.self
        )
        .eraseToAnyPublisher()
    }
    
    func markMessageAsRead(id: String) -> AnyPublisher<MailMessage, APIError> {
        return makeRequest(
            endpoint: "/api/mail/\(id)/read",
            method: .PUT,
            responseType: APIResponse<MailMessage>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Redemption Endpoints
    func getRedemptionOptions(category: RedemptionOption.RedemptionCategory? = nil) -> AnyPublisher<[RedemptionOption], APIError> {
        var endpoint = "/api/redeem/options"
        if let category = category {
            endpoint += "?category=\(category.rawValue)"
        }
        
        return makeRequest(
            endpoint: endpoint,
            responseType: APIResponse<[RedemptionOption]>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    func redeemPoints(optionId: String) -> AnyPublisher<PointsTransaction, APIError> {
        return makeRequest(
            endpoint: "/api/redeem/\(optionId)",
            method: .POST,
            responseType: APIResponse<PointsTransaction>.self
        )
        .tryMap { response in
            guard response.success, let data = response.data else {
                throw APIError.serverError(400)
            }
            return data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                return apiError
            }
            return APIError.decodingError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Activity Endpoints
    func getActivityFeed(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<ActivityItem>, APIError> {
        return makeRequest(
            endpoint: "/api/activity?page=\(page)&limit=\(limit)",
            responseType: PaginatedResponse<ActivityItem>.self
        )
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
