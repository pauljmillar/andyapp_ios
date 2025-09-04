//
//  APIService.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation
import Combine
import UIKit

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://survey-khaki-chi.vercel.app"
    private var authToken: String?
    
    var currentAuthToken: String? {
        return authToken
    }
    
    private init() {}
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        print("🔑 APIService: Setting auth token: \(token)")
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
    

    
    // MARK: - Generic Request Method (Combine)
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, APIError> {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ Invalid URL: \(baseURL)\(endpoint)")
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Making request to: \(url)")
        print("🌐 Method: \(method.rawValue)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AndyApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        if let token = authToken {
            // Use Bearer prefix for JWT tokens
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Authorization header set with Bearer token: \(token)")
        } else {
            print("⚠️ No auth token available")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.invalidResponse
                }
                
                print("📡 Response status code: \(httpResponse.statusCode)")
                print("📡 Response headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode == 401 {
                    print("❌ Unauthorized (401) - Check your auth token")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📡 Response body: \(responseString)")
                    }
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode >= 400 {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📡 Response body: \(responseString)")
                    }
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                print("✅ Request successful")
                
                // Log the response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Response body: \(responseString)")
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
    
    // MARK: - Generic Request Method (Async)
    private func makeRequestAsync<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ Invalid URL: \(baseURL)\(endpoint)")
            throw APIError.invalidURL
        }
        
        print("🌐 Making async request to: \(url)")
        print("🌐 Method: \(method.rawValue)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AndyApp-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Always get a fresh token from Clerk for each request
        do {
            let freshToken = try await ClerkAuthManager.shared.generateJWTToken()
            request.setValue("Bearer \(freshToken)", forHTTPHeaderField: "Authorization")
            print("🔑 Authorization header set with fresh Bearer token: \(freshToken)")
        } catch {
            print("⚠️ Failed to get fresh auth token: \(error)")
            throw APIError.unauthorized
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("📡 Response status code: \(httpResponse.statusCode)")
        print("📡 Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode == 401 {
            print("❌ Unauthorized (401) - Check your auth token")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body: \(responseString)")
            }
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode >= 400 {
            print("❌ Server error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body: \(responseString)")
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        print("✅ Async request successful")
        
        // Log the response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response body: \(responseString)")
        }
        
        return try JSONDecoder().decode(responseType, from: data)
    }
    
    // MARK: - Panelist Profile Endpoint
    func fetchPanelistProfile() -> AnyPublisher<PanelistProfile, APIError> {
        return makeRequest(
            endpoint: "/api/auth/panelist-profile",
            method: .GET,
            responseType: PanelistProfile.self
        )
    }
    
    // MARK: - Available Surveys Endpoint
    func fetchAvailableSurveys(limit: Int = 6, offset: Int = 0) -> AnyPublisher<AvailableSurveysResponse, APIError> {
        let endpoint = "/api/surveys/available?limit=\(limit)&offset=\(offset)"
        print("🌐 Available Surveys API - Endpoint: \(endpoint)")
        print("🌐 Available Surveys API - Full URL: \(baseURL)\(endpoint)")
        return makeRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: AvailableSurveysResponse.self
        )
    }
    
    // MARK: - Point Ledger Endpoint
    func fetchPointLedger(limit: Int = 6, offset: Int = 0, transactionType: String? = nil) -> AnyPublisher<PointLedgerResponse, APIError> {
        var endpoint = "/api/panelist/point-ledger?limit=\(limit)&offset=\(offset)"
        if let transactionType = transactionType {
            endpoint += "&transactionType=\(transactionType)"
        }
        print("🌐 Point Ledger API - Endpoint: \(endpoint)")
        print("🌐 Point Ledger API - Full URL: \(baseURL)\(endpoint)")
        return makeRequest(
            endpoint: endpoint,
            method: .GET,
            responseType: PointLedgerResponse.self
        )
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
    func getAvailableOffers(
        active: Bool? = true,
        minPoints: Int? = nil,
        maxPoints: Int? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) -> AnyPublisher<OffersResponse, APIError> {
        var endpoint = "/api/offers?limit=\(limit)&offset=\(offset)"
        
        if let active = active {
            endpoint += "&active=\(active)"
        }
        if let minPoints = minPoints {
            endpoint += "&min_points=\(minPoints)"
        }
        if let maxPoints = maxPoints {
            endpoint += "&max_points=\(maxPoints)"
        }
        
        print("🌐 Available Offers API - Endpoint: \(endpoint)")
        print("🌐 Available Offers API - Full URL: \(baseURL)\(endpoint)")
        
        return makeRequest(
            endpoint: endpoint,
            responseType: OffersResponse.self
        )
    }
    
    func getRedemptionHistory(
        status: String? = nil,
        limit: Int = 10,
        offset: Int = 0
    ) -> AnyPublisher<RedemptionsResponse, APIError> {
        var endpoint = "/api/redemptions?limit=\(limit)&offset=\(offset)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        print("🌐 Redemption History API - Endpoint: \(endpoint)")
        print("🌐 Redemption History API - Full URL: \(baseURL)\(endpoint)")
        
        return makeRequest(
            endpoint: endpoint,
            responseType: RedemptionsResponse.self
        )
    }
    
    func redeemPoints(offerId: String) -> AnyPublisher<RedemptionResponse, APIError> {
        print("🌐 Redeem Points API - Endpoint: /api/redemptions")
        print("🌐 Redeem Points API - Full URL: \(baseURL)/api/redemptions")
        print("🎁 Redeeming points for offer ID: \(offerId)")
        
        let request = RedemptionRequest(offerId: offerId)
        
        // Encode request to JSON data
        guard let jsonData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/redemptions",
            method: .POST,
            body: jsonData,
            responseType: RedemptionResponse.self
        )
    }
    
    // MARK: - Async Redemption Endpoints (with automatic token refresh)
    func getAvailableOffersAsync(
        active: Bool? = true,
        minPoints: Int? = nil,
        maxPoints: Int? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> OffersResponse {
        var endpoint = "/api/offers?limit=\(limit)&offset=\(offset)"
        
        if let active = active {
            endpoint += "&active=\(active)"
        }
        if let minPoints = minPoints {
            endpoint += "&min_points=\(minPoints)"
        }
        if let maxPoints = maxPoints {
            endpoint += "&max_points=\(maxPoints)"
        }
        
        print("🌐 Available Offers Async API - Endpoint: \(endpoint)")
        print("🌐 Available Offers Async API - Full URL: \(baseURL)\(endpoint)")
        
        return try await makeRequestAsync(
            endpoint: endpoint,
            responseType: OffersResponse.self
        )
    }
    
    func getRedemptionHistoryAsync(
        status: String? = nil,
        limit: Int = 10,
        offset: Int = 0
    ) async throws -> RedemptionsResponse {
        var endpoint = "/api/redemptions?limit=\(limit)&offset=\(offset)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        print("🌐 Redemption History Async API - Endpoint: \(endpoint)")
        print("🌐 Redemption History Async API - Full URL: \(baseURL)\(endpoint)")
        
        return try await makeRequestAsync(
            endpoint: endpoint,
            responseType: RedemptionsResponse.self
        )
    }
    
    func redeemPointsAsync(offerId: String) async throws -> RedemptionResponse {
        print("🌐 Redeem Points Async API - Endpoint: /api/redemptions")
        print("🌐 Redeem Points Async API - Full URL: \(baseURL)/api/redemptions")
        print("🎁 Redeeming points for offer ID: \(offerId)")
        
        let request = RedemptionRequest(offerId: offerId)
        
        // Encode request to JSON data
        guard let jsonData = try? JSONEncoder().encode(request) else {
            throw APIError.invalidResponse
        }
        
        return try await makeRequestAsync(
            endpoint: "/api/redemptions",
            method: .POST,
            body: jsonData,
            responseType: RedemptionResponse.self
        )
    }
    
    // MARK: - Activity Endpoints
    func getActivityFeed(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<ActivityItem>, APIError> {
        return makeRequest(
            endpoint: "/api/activity?page=\(page)&limit=\(limit)",
            responseType: PaginatedResponse<ActivityItem>.self
        )
        .eraseToAnyPublisher()
    }

    // MARK: - Survey Endpoints
    func fetchPanelistSurveys() -> AnyPublisher<PanelistSurveysResponse, APIError> {
        print("🌐 Panelist Surveys API - Endpoint: /api/panelist/surveys")
        print("🌐 Panelist Surveys API - Full URL: \(baseURL)/api/panelist/surveys")
        return makeRequest(
            endpoint: "/api/panelist/surveys",
            method: .GET,
            responseType: PanelistSurveysResponse.self
        )
    }
    
    // MARK: - Survey Taking Endpoints
    func fetchSurveyDetails(surveyId: String) -> AnyPublisher<PanelistSurvey, APIError> {
        print("🌐 Survey Details API - Endpoint: /api/surveys/\(surveyId)")
        print("🌐 Survey Details API - Full URL: \(baseURL)/api/surveys/\(surveyId)")
        return makeRequest(
            endpoint: "/api/surveys/\(surveyId)",
            method: .GET,
            responseType: PanelistSurvey.self
        )
    }
    
    func fetchSurveyQuestions(surveyId: String) -> AnyPublisher<SurveyQuestionsResponse, APIError> {
        print("🌐 Survey Questions API - Endpoint: /api/surveys/\(surveyId)/questions")
        print("🌐 Survey Questions API - Full URL: \(baseURL)/api/surveys/\(surveyId)/questions")
        return makeRequest(
            endpoint: "/api/surveys/\(surveyId)/questions",
            method: .GET,
            responseType: SurveyQuestionsResponse.self
        )
    }
    
    func submitSurveyCompletion(_ request: SurveyCompletionRequest) -> AnyPublisher<SurveyCompletion, APIError> {
        print("🌐 Survey Completion API - Endpoint: /api/panelist/survey-completion")
        print("🌐 Survey Completion API - Full URL: \(baseURL)/api/panelist/survey-completion")
        print("📝 Completion data: survey_id=\(request.surveyId), responses=\(request.responses.count)")
        
        // Encode request to JSON data
        guard let jsonData = try? JSONEncoder().encode(request) else {
            return Fail(error: APIError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        // Debug: Print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request JSON: \(jsonString)")
        }
        
        return makeRequest(
            endpoint: "/api/panelist/survey-completion",
            method: .POST,
            body: jsonData,
            responseType: SurveyCompletion.self
        )
    }
    
    // MARK: - Mail Package Management API
    func createMailPackage(request: CreateMailPackageRequest) async throws -> CreateMailPackageResponse {
        let endpoint = "/api/panelist/mail-packages"
        
        print("📦 Create Mail Package API - Endpoint: \(endpoint)")
        print("📦 Create Mail Package API - Full URL: \(baseURL)\(endpoint)")
        print("📝 Package data: name=\(request.packageName)")
        
        guard let jsonData = try? JSONEncoder().encode(request) else {
            throw APIError.invalidResponse
        }
        
        return try await makeRequestAsync(
            endpoint: endpoint,
            method: .POST,
            body: jsonData,
            responseType: CreateMailPackageResponse.self
        )
    }
    
    func updateMailPackage(mailPackageId: String, request: UpdateMailPackageRequest) async throws -> UpdateMailPackageResponse {
        let endpoint = "/api/panelist/mail-packages/\(mailPackageId)"
        
        print("🔄 Update Mail Package API - Endpoint: \(endpoint)")
        print("🔄 Update Mail Package API - Full URL: \(baseURL)\(endpoint)")
        print("📝 Update data: mailPackageId=\(mailPackageId)")
        
        guard let jsonData = try? JSONEncoder().encode(request) else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 PATCH Request Body: \(jsonString)")
        }
        
        print("🔍 Making PATCH request to: \(endpoint)")
        print("🔍 Method: \(HTTPMethod.PATCH.rawValue)")
        print("🔍 Body size: \(jsonData.count) bytes")
        
        do {
            print("🔄 Trying PATCH method first...")
            return try await makeRequestAsync(
                endpoint: endpoint,
                method: .PATCH,
                body: jsonData,
                responseType: UpdateMailPackageResponse.self
            )
        } catch {
            print("❌ PATCH request failed: \(error)")
            print("🔄 Trying PUT method as fallback...")
            
            // Try PUT as fallback (some APIs don't support PATCH)
            do {
                return try await makeRequestAsync(
                    endpoint: endpoint,
                    method: .PUT,
                    body: jsonData,
                    responseType: UpdateMailPackageResponse.self
                )
            } catch {
                print("❌ PUT request also failed: \(error)")
                print("❌ Endpoint: \(endpoint)")
                print("❌ Both PATCH and PUT methods failed")
                throw error
            }
        }
    }
    
    func uploadMailScan(request: MailScanUploadRequest) async throws -> MailScanUploadResponse {
        let endpoint = "/api/panelist/mail-scans/upload"
        
        print("📸 Upload Mail Scan API - Endpoint: \(endpoint)")
        print("📸 Upload Mail Scan API - Full URL: \(baseURL)\(endpoint)")
        print("📝 Upload data: mailPackageId=\(request.mailPackageId ?? "nil"), documentType=\(request.documentType)")
        
        // Configure JSON encoder to include nil values
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Create a custom dictionary to ensure nil values are included
        var requestDict: [String: Any] = [
            "document_type": request.documentType,
            "file_data": request.fileData,
            "filename": request.filename
        ]
        
        // Explicitly set mail_package_id to null if nil
        if let mailPackageId = request.mailPackageId {
            requestDict["mail_package_id"] = mailPackageId
        } else {
            requestDict["mail_package_id"] = NSNull()
        }
        
        // Add optional fields
        if let imageSequence = request.imageSequence {
            requestDict["image_sequence"] = imageSequence
        }
        if let mimeType = request.mimeType {
            requestDict["mime_type"] = mimeType
        }
        if let metadata = request.metadata {
            requestDict["metadata"] = metadata
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestDict) else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON Request Body: \(jsonString)")
        }
        
        return try await makeRequestAsync(
            endpoint: endpoint,
            method: .POST,
            body: jsonData,
            responseType: MailScanUploadResponse.self
        )
    }
    
    func processMailPackage(mailPackageId: String, request: ProcessMailPackageRequest) async throws -> ProcessMailPackageResponse {
        let endpoint = "/api/panelist/mail-packages/\(mailPackageId)/process"
        
        print("🤖 Process Mail Package API - Endpoint: \(endpoint)")
        print("🤖 Process Mail Package API - Full URL: \(baseURL)\(endpoint)")
        print("📝 Process data: mailPackageId=\(mailPackageId), inputText=\(request.inputText)")
        
        guard let jsonData = try? JSONEncoder().encode(request) else {
            throw APIError.invalidResponse
        }
        
        return try await makeRequestAsync(
            endpoint: endpoint,
            method: .POST,
            body: jsonData,
            responseType: ProcessMailPackageResponse.self
        )
    }
}

// MARK: - Combine to Async Extension
extension Publisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
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
