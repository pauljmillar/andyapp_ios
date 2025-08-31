//
//  Models.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import Foundation

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

struct SurveyQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let type: QuestionType
    let options: [String]?
    let required: Bool
    
    enum QuestionType: String, Codable {
        case multipleChoice = "multiple_choice"
        case text = "text"
        case rating = "rating"
        case yesNo = "yes_no"
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
    let questionType: SurveyQuestion.QuestionType
}
