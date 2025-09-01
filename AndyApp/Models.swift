//
//  Models.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation

// MARK: - Panelist Profile (API Response)
struct PanelistProfile: Codable {
    let id: String
    let userId: String
    let pointsBalance: Int
    let totalPointsEarned: Int
    let totalPointsRedeemed: Int
    let surveysCompleted: Int
    let totalScans: Int
    let profileData: ProfileData
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pointsBalance = "points_balance"
        case totalPointsEarned = "total_points_earned"
        case totalPointsRedeemed = "total_points_redeemed"
        case surveysCompleted = "surveys_completed"
        case totalScans = "total_scans"
        case profileData = "profile_data"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        pointsBalance = try container.decode(Int.self, forKey: .pointsBalance)
        totalPointsEarned = try container.decode(Int.self, forKey: .totalPointsEarned)
        totalPointsRedeemed = try container.decode(Int.self, forKey: .totalPointsRedeemed)
        surveysCompleted = try container.decode(Int.self, forKey: .surveysCompleted)
        totalScans = try container.decode(Int.self, forKey: .totalScans)
        profileData = try container.decode(ProfileData.self, forKey: .profileData)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        
        // Handle date decoding with custom formatter
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let createdAtDate = dateFormatter.date(from: createdAtString) {
            createdAt = createdAtDate
        } else {
            // Fallback to standard ISO8601 format
            let fallbackFormatter = ISO8601DateFormatter()
            createdAt = fallbackFormatter.date(from: createdAtString) ?? Date()
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        if let updatedAtDate = dateFormatter.date(from: updatedAtString) {
            updatedAt = updatedAtDate
        } else {
            // Fallback to standard ISO8601 format
            let fallbackFormatter = ISO8601DateFormatter()
            updatedAt = fallbackFormatter.date(from: updatedAtString) ?? Date()
        }
    }
}

struct ProfileData: Codable {
    let firstName: String
    let lastName: String
    let age: Int?
    let gender: String?
    let location: Location?
    let demographics: Demographics?
    let interests: [String]?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case age, gender, location, demographics, interests
    }
}

struct Location: Codable {
    let city: String?
    let state: String?
    let country: String?
}

struct Demographics: Codable {
    let education: String?
    let employment: String?
    let incomeRange: String?
    
    enum CodingKeys: String, CodingKey {
        case education, employment
        case incomeRange = "income_range"
    }
}

// MARK: - Available Surveys API Response
struct AvailableSurveysResponse: Codable {
    let surveys: [AvailableSurvey]
    let total: Int
    let message: String?
}

struct AvailableSurvey: Codable {
    let id: String
    let title: String
    let description: String
    let pointsReward: Int
    let estimatedCompletionTime: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case pointsReward = "points_reward"
        case estimatedCompletionTime = "estimated_completion_time"
        case createdAt = "created_at"
    }
    
    var timeString: String {
        if estimatedCompletionTime < 60 {
            return "\(estimatedCompletionTime) min"
        } else {
            let hours = estimatedCompletionTime / 60
            let minutes = estimatedCompletionTime % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Point Ledger API Response
struct PointLedgerResponse: Codable {
    let ledgerEntries: [LedgerEntry]
    let pagination: PointLedgerPagination
    
    enum CodingKeys: String, CodingKey {
        case ledgerEntries = "ledgerEntries"
        case pagination
    }
}

struct LedgerEntry: Codable {
    let points: Int
    let transactionType: String
    let title: String
    let description: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case points
        case transactionType = "transaction_type"
        case title
        case description
        case createdAt = "created_at"
    }
    
    // Helper computed properties for display
    var formattedPoints: String {
        return points >= 0 ? "+\(points) points" : "\(points) points"
    }
    
    var transactionTypeDisplay: String {
        switch transactionType {
        case "survey_completion": return "Survey"
        case "manual_award": return "Award"
        case "bonus": return "Bonus"
        case "redemption": return "Redeem"
        case "account_signup_bonus": return "Signup Bonus"
        case "app_download_bonus": return "App Bonus"
        default: return transactionType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var transactionTypeColor: String {
        switch transactionType {
        case "survey_completion", "manual_award", "bonus", "account_signup_bonus", "app_download_bonus":
            return "Earn"
        case "redemption":
            return "Redeem"
        default:
            return "Other"
        }
    }
}

struct PointLedgerPagination: Codable {
    let limit: Int
    let offset: Int
    let total: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case limit
        case offset
        case total
        case hasMore
    }
}

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?
    let points: Int
    let joinDate: Date
    let surveysCompleted: Int
    let totalEarned: Int
    let totalRedeemed: Int
    let totalScans: Int
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        }
        return email
    }
}

// MARK: - Survey
struct Survey: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: SurveyCategory
    let pointsReward: Int
    let estimatedTime: Int // in minutes
    let isCompleted: Bool
    let isAvailable: Bool
    let createdAt: Date
    let expiresAt: Date?
    let questions: [SurveyQuestion]
    
    var timeString: String {
        if estimatedTime < 60 {
            return "\(estimatedTime) min"
        } else {
            let hours = estimatedTime / 60
            let minutes = estimatedTime % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

enum SurveyCategory: String, Codable, CaseIterable {
    case general = "General"
    case technology = "Technology"
    case health = "Health"
    case finance = "Finance"
    case entertainment = "Entertainment"
    case education = "Education"
    case lifestyle = "Lifestyle"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Survey Question Models
struct SurveyQuestion: Codable {
    let id: String
    let surveyId: String
    let questionText: String
    let questionType: String
    let questionOrder: Int
    let isRequired: Bool
    let options: [String]?
    let validationRules: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case surveyId = "survey_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case questionOrder = "question_order"
        case isRequired = "is_required"
        case options
        case validationRules = "validation_rules"
    }
    
    // Custom decoding to handle mixed types in validation rules
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        surveyId = try container.decode(String.self, forKey: .surveyId)
        questionText = try container.decode(String.self, forKey: .questionText)
        questionType = try container.decode(String.self, forKey: .questionType)
        questionOrder = try container.decode(Int.self, forKey: .questionOrder)
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        
        // Handle validation rules with mixed types
        if let validationRulesContainer = try? container.nestedContainer(keyedBy: ValidationRuleKeys.self, forKey: .validationRules) {
            var rules: [String: String] = [:]
            
            // Try to decode each validation rule as different types and convert to string
            if let maxValue = try? validationRulesContainer.decode(Int.self, forKey: .maxValue) {
                rules["max_value"] = "\(maxValue)"
            }
            if let minValue = try? validationRulesContainer.decode(Int.self, forKey: .minValue) {
                rules["min_value"] = "\(minValue)"
            }
            if let maxLength = try? validationRulesContainer.decode(Int.self, forKey: .maxLength) {
                rules["max_length"] = "\(maxLength)"
            }
            if let minLength = try? validationRulesContainer.decode(Int.self, forKey: .minLength) {
                rules["min_length"] = "\(minLength)"
            }
            if let maxSelections = try? validationRulesContainer.decode(Int.self, forKey: .maxSelections) {
                rules["max_selections"] = "\(maxSelections)"
            }
            if let minSelections = try? validationRulesContainer.decode(Int.self, forKey: .minSelections) {
                rules["min_selections"] = "\(minSelections)"
            }
            
            validationRules = rules.isEmpty ? nil : rules
        } else {
            validationRules = nil
        }
    }
    
    private enum ValidationRuleKeys: String, CodingKey {
        case maxValue = "max_value"
        case minValue = "min_value"
        case maxLength = "max_length"
        case minLength = "min_length"
        case maxSelections = "max_selections"
        case minSelections = "min_selections"
    }
    
    // Helper computed properties for UI
    var displayType: QuestionDisplayType {
        switch questionType {
        case "rating":
            return .rating
        case "yes_no":
            return .yesNo
        case "multiple_choice":
            return .multipleChoice
        case "checkbox":
            return .checkbox
        case "text":
            return .text
        default:
            return .text
        }
    }
}

struct SurveyQuestionsResponse: Codable {
    let questions: [SurveyQuestion]
}

// MARK: - Survey Response Models
struct SurveyCompletionRequest: Codable {
    let surveyId: String
    let panelistId: String
    let pointsEarned: Int
    let responseData: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
        case panelistId = "panelist_id"
        case pointsEarned = "points_earned"
        case responseData = "response_data"
    }
}

struct SurveyCompletionResponse: Codable {
    let id: String
    let surveyId: String
    let panelistId: String
    let pointsEarned: Int
    let responseData: [String: String]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case surveyId = "survey_id"
        case panelistId = "panelist_id"
        case pointsEarned = "points_earned"
        case responseData = "response_data"
        case createdAt = "created_at"
    }
}

struct AwardPointsRequest: Codable {
    let pPanelistId: String
    let pPoints: Int
    let pTransactionType: String
    let pTitle: String
    let pDescription: String
    let pMetadata: [String: String] // Changed from [String: Any] to [String: String]
    let pAwardedBy: String?
    let pEffectiveDate: String
    
    enum CodingKeys: String, CodingKey {
        case pPanelistId = "p_panelist_id"
        case pPoints = "p_points"
        case pTransactionType = "p_transaction_type"
        case pTitle = "p_title"
        case pDescription = "p_description"
        case pMetadata = "p_metadata"
        case pAwardedBy = "p_awarded_by"
        case pEffectiveDate = "p_effective_date"
    }
}

// MARK: - Question Display Types
enum QuestionDisplayType {
    case rating
    case yesNo
    case multipleChoice
    case checkbox
    case text
}

// MARK: - Survey Taking State
class SurveyTakingState: ObservableObject {
    @Published var currentQuestionIndex = 0
    @Published var responses: [String: String] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var shouldSubmitSurvey = false
    
    var currentQuestion: SurveyQuestion?
    var questions: [SurveyQuestion] = []
    var survey: SurveyViewItem?
    
    var canGoPrevious: Bool {
        return currentQuestionIndex > 0
    }
    
    var canGoNext: Bool {
        guard let question = currentQuestion else { return false }
        return hasValidResponse(for: question)
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }
    
    var progressText: String {
        return "Question \(currentQuestionIndex + 1) of \(questions.count)"
    }
    
    func setSurvey(_ survey: SurveyViewItem) {
        self.survey = survey
        self.currentQuestionIndex = 0
        self.responses.removeAll()
        self.shouldSubmitSurvey = false
    }
    
    func setQuestions(_ questions: [SurveyQuestion]) {
        self.questions = questions.sorted { $0.questionOrder < $1.questionOrder }
        self.currentQuestionIndex = 0
        self.updateCurrentQuestion()
    }
    
    func updateCurrentQuestion() {
        guard currentQuestionIndex < questions.count else { return }
        currentQuestion = questions[currentQuestionIndex]
    }
    
    func goToNextQuestion() {
        guard canGoNext else { return }
        if isLastQuestion {
            // Submit survey
            submitSurvey()
        } else {
            currentQuestionIndex += 1
            updateCurrentQuestion()
        }
    }
    
    func goToPreviousQuestion() {
        guard canGoPrevious else { return }
        currentQuestionIndex -= 1
        updateCurrentQuestion()
    }
    
    func setResponse(for questionId: String, value: String) {
        responses[questionId] = value
    }
    
    func getResponse(for questionId: String) -> String? {
        return responses[questionId]
    }
    
    func hasValidResponse(for question: SurveyQuestion) -> Bool {
        guard question.isRequired else { return true }
        
        if let response = responses[question.id] {
            return !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private func submitSurvey() {
        print("🚀 Submitting survey with \(responses.count) responses")
        shouldSubmitSurvey = true
    }
}

// MARK: - Points Transaction
struct PointsTransaction: Codable, Identifiable {
    let id: String
    let amount: Int
    let type: TransactionType
    let description: String
    let surveyId: String?
    let createdAt: Date
    
    enum TransactionType: String, Codable {
        case earned = "earned"
        case redeemed = "redeemed"
        case bonus = "bonus"
        case adjustment = "adjustment"
    }
    
    var isPositive: Bool {
        return type == .earned || type == .bonus
    }
    
    var formattedAmount: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(amount) pts"
    }
}

// MARK: - Mail Message
struct MailMessage: Codable, Identifiable {
    let id: String
    let subject: String
    let body: String
    let isRead: Bool
    let isImportant: Bool
    let sender: String
    let createdAt: Date
    let attachments: [MailAttachment]?
}

struct MailAttachment: Codable, Identifiable {
    let id: String
    let name: String
    let url: String
    let size: Int
    let type: String
}

// MARK: - Redemption Option
struct RedemptionOption: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let pointsCost: Int
    let imageUrl: String?
    let isAvailable: Bool
    let category: RedemptionCategory
    let stock: Int?
    
    enum RedemptionCategory: String, Codable, CaseIterable {
        case giftCards = "Gift Cards"
        case merchandise = "Merchandise"
        case donations = "Donations"
        case experiences = "Experiences"
        
        var displayName: String {
            return rawValue
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: Codable, Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let description: String
    let points: Int?
    let createdAt: Date
    let metadata: [String: String]?
    
    enum ActivityType: String, Codable {
        case surveyCompleted = "survey_completed"
        case pointsEarned = "points_earned"
        case pointsRedeemed = "points_redeemed"
        case achievement = "achievement"
        case system = "system"
    }
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrev: Bool
}

// MARK: - Authentication Models
struct AuthResponse: Codable {
    let user: UserProfile
    let token: String
    let refreshToken: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
}

// MARK: - Survey Response
struct SurveyResponse: Codable {
    let surveyId: String
    let answers: [QuestionAnswer]
    let timeSpent: Int // in seconds
}

struct QuestionAnswer: Codable {
    let questionId: String
    let answer: String
    let questionType: String // Changed from SurveyQuestion.QuestionType to String
}

// MARK: - Survey Models
struct PanelistSurvey: Codable {
    let id: String
    let title: String
    let description: String
    let pointsReward: Int
    let estimatedCompletionTime: Int
    let status: String
    let createdAt: String
    let updatedAt: String
    let isCompleted: Bool
    let completedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case pointsReward = "points_reward"
        case estimatedCompletionTime = "estimated_completion_time"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
    }
}

struct PanelistSurveysResponse: Codable {
    let surveys: [PanelistSurvey]
}

struct SurveyViewItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let points: Int
    let status: String
    let estimatedTime: String
    let isCompleted: Bool
    let completedAt: String?
    
    static func fromPanelistSurvey(_ survey: PanelistSurvey) -> SurveyViewItem {
        return SurveyViewItem(
            id: survey.id,
            title: survey.title,
            description: survey.description,
            points: survey.pointsReward,
            status: survey.isCompleted ? "Completed" : "Ready",
            estimatedTime: "\(survey.estimatedCompletionTime) minutes",
            isCompleted: survey.isCompleted,
            completedAt: survey.completedAt
        )
    }
}
