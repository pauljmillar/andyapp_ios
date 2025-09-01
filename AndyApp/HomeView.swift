//
//  HomeView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var authManager = ClerkAuthManager.shared
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCategory: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Announcement card
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Limited Time Offer")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                    
                    Text("Get 50% more points on your next scan!")
                        .font(AppTypography.body)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .background(Color.black)
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.lg)
                
                // Dashboard section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Your dashboard")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Metric cards - 2x2 grid
                    VStack(spacing: AppSpacing.sm) {
                        // Top row
                        HStack(spacing: AppSpacing.sm) {
                            // Top left - Points
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("points")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                
                                Text("\(authManager.currentUser?.points ?? 0)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(Color(hex: "#dc148c"))
                            .cornerRadius(AppCornerRadius.medium)
                            
                            // Top right - Redeemed
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("redeemed")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                
                                Text("\(authManager.currentUser?.totalRedeemed ?? 0)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(Color(hex: "#1e3264"))
                            .cornerRadius(AppCornerRadius.medium)
                        }
                        
                        // Bottom row
                        HStack(spacing: AppSpacing.sm) {
                            // Bottom left - Scans
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("scans")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                
                                Text("\(authManager.currentUser?.totalScans ?? 0)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(Color(hex: "#8400e7"))
                            .cornerRadius(AppCornerRadius.medium)
                            
                            // Bottom right - Surveys
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("surveys")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                
                                Text("\(authManager.currentUser?.surveysCompleted ?? 0)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(Color(hex: "#006450"))
                            .cornerRadius(AppCornerRadius.medium)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                
                // Earn points section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Earn points")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    Button(action: {
                        // Navigate to Mail view
                        // TODO: Implement navigation to Mail tab
                    }) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Earn more points today by scanning your junk mail now!")
                                .font(AppTypography.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.lg)
                        .background(Color(hex: "#509bf5"))
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Available surveys section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("Available Surveys")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button("View All") {
                            // Navigate to survey tab
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.primaryGreen)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Survey cards - horizontal scrolling
                    if viewModel.isLoading {
                        LoadingView(message: "Loading surveys...")
                            .frame(height: 200)
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            viewModel.loadSurveys()
                        }
                        .frame(height: 200)
                    } else if viewModel.surveys.isEmpty {
                        EmptyStateView(
                            icon: "doc.text",
                            title: "No Surveys Available",
                            message: "Check back later for new surveys to complete and earn points.",
                            actionTitle: "Refresh",
                            action: {
                                viewModel.loadSurveys()
                            }
                        )
                        .frame(height: 200)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.md) {
                                ForEach(filteredSurveys) { survey in
                                    SurveyCard(survey: survey) {
                                        // Navigate to survey detail
                                    }
                                    .frame(width: 280) // Fixed width for horizontal scrolling
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
                
                // Recent activity section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("Recent Activity")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button("View All") {
                            // Navigate to activity screen
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.primaryGreen)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    if viewModel.isLoadingActivity {
                        LoadingView(message: "Loading activity...")
                            .frame(height: 150)
                    } else if viewModel.activities.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "No Activity Yet",
                            message: "Complete your first survey to see activity here.",
                            actionTitle: nil,
                            action: nil
                        )
                        .frame(height: 150)
                    } else {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(viewModel.activities) { activity in
                                ActivityItemView(activity: activity)
                                    .padding(.horizontal, AppSpacing.lg)
                            }
                        }
                    }
                }
                

            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background)
        .onAppear {
            // Load panelist profile first to set auth token, then load surveys
            Task {
                await authManager.fetchPanelistProfile()
                await MainActor.run {
                    viewModel.loadSurveys()
                    viewModel.loadActivity()
                }
            }
        }
        .refreshable {
            Task {
                await authManager.fetchPanelistProfile()
                await MainActor.run {
                    viewModel.loadSurveys()
                    viewModel.loadActivity()
                }
            }
        }
    }
    
    private var filteredSurveys: [Survey] {
        // Since we removed category filtering, just return all surveys
        return viewModel.surveys
    }
}

// MARK: - Home View Model
class HomeViewModel: ObservableObject {
    @Published var surveys: [Survey] = []
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var isLoadingActivity = false
    @Published var error: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadSurveys() {
        isLoading = true
        error = nil
        
        print("🔄 Loading available surveys from API...")
        print("🔑 Current auth token: \(apiService.currentAuthToken ?? "No token")")
        
        apiService.fetchAvailableSurveys(limit: 6, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error loading surveys: \(error)")
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ Available surveys loaded: \(response.surveys.count) surveys")
                    print("📊 Total surveys available: \(response.total)")
                    
                    // Convert AvailableSurvey to Survey format for compatibility
                    self?.surveys = response.surveys.map { availableSurvey in
                        Survey(
                            id: availableSurvey.id,
                            title: availableSurvey.title,
                            description: availableSurvey.description,
                            category: .general, // Default category since API doesn't provide it
                            pointsReward: availableSurvey.pointsReward,
                            estimatedTime: availableSurvey.estimatedCompletionTime,
                            isCompleted: false, // Available surveys are not completed
                            isAvailable: true,
                            createdAt: Date(), // We'll use current date since API provides string
                            expiresAt: nil,
                            questions: [] // API doesn't provide questions for available surveys
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadActivity() {
        isLoadingActivity = true
        
        print("🔄 Loading point ledger from API...")
        print("🔑 Current auth token: \(apiService.currentAuthToken ?? "No token")")
        print("🔑 Auth token length: \(apiService.currentAuthToken?.count ?? 0)")
        
        apiService.fetchPointLedger(limit: 10, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingActivity = false
                    if case .failure(let error) = completion {
                        print("❌ Error loading point ledger: \(error)")
                        print("❌ Error type: \(type(of: error))")
                        print("❌ Error description: \(error.localizedDescription)")
                        // Don't show error for activity loading, just keep empty
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ Point ledger loaded: \(response.ledgerEntries.count) entries")
                    print("📊 Total ledger entries: \(response.pagination.total)")
                    print("📊 Pagination info: limit=\(response.pagination.limit), offset=\(response.pagination.offset), hasMore=\(response.pagination.hasMore)")
                    
                    // Log first few entries for debugging
                    for (index, entry) in response.ledgerEntries.prefix(3).enumerated() {
                        print("📝 Entry \(index + 1): \(entry.title) - \(entry.formattedPoints) (\(entry.transactionType))")
                    }
                    
                    // Convert LedgerEntry to ActivityItem for compatibility
                    self?.activities = response.ledgerEntries.map { ledgerEntry in
                        // Parse the created_at date string
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        let createdAtDate: Date
                        if let parsedDate = dateFormatter.date(from: ledgerEntry.createdAt) {
                            createdAtDate = parsedDate
                        } else {
                            // Fallback to standard ISO8601 format
                            let fallbackFormatter = ISO8601DateFormatter()
                            createdAtDate = fallbackFormatter.date(from: ledgerEntry.createdAt) ?? Date()
                        }
                        
                        return ActivityItem(
                            id: UUID().uuidString, // Generate unique ID since ledger doesn't provide one
                            type: self?.getActivityType(from: ledgerEntry.transactionType) ?? .pointsEarned,
                            title: ledgerEntry.title,
                            description: ledgerEntry.description ?? "",
                            points: ledgerEntry.points,
                            createdAt: createdAtDate, // Use parsed date from API
                            metadata: [
                                "transactionType": ledgerEntry.transactionType,
                                "formattedPoints": ledgerEntry.formattedPoints,
                                "transactionTypeDisplay": ledgerEntry.transactionTypeDisplay,
                                "transactionTypeColor": ledgerEntry.transactionTypeColor
                            ]
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Helper function to convert transaction type to ActivityType
    private func getActivityType(from transactionType: String) -> ActivityItem.ActivityType {
        switch transactionType {
        case "survey_completion":
            return .surveyCompleted
        case "redemption":
            return .pointsRedeemed
        case "bonus", "manual_award", "account_signup_bonus", "app_download_bonus":
            return .pointsEarned
        default:
            return .pointsEarned
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(value)
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(
            color: AppShadows.small.color,
            radius: AppShadows.small.radius,
            x: AppShadows.small.x,
            y: AppShadows.small.y
        )
    }
}

#Preview {
    NavigationView {
        HomeView()
    }
}
