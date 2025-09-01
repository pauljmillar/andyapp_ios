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
                
                // Quick actions
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Quick Actions")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.md) {
                            InfoCard(
                                title: "Take Survey",
                                subtitle: "Earn points",
                                icon: "doc.text.fill",
                                color: AppColors.primaryGreen
                            ) {
                                // Navigate to survey tab
                            }
                            
                            InfoCard(
                                title: "Redeem Points",
                                subtitle: "Get rewards",
                                icon: "gift.fill",
                                color: AppColors.warning
                            ) {
                                // Navigate to redeem tab
                            }
                            
                            InfoCard(
                                title: "Check Mail",
                                subtitle: "New messages",
                                icon: "envelope.fill",
                                color: AppColors.info
                            ) {
                                // Navigate to mail tab
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
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
                    
                    // Survey cards
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
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(filteredSurveys) { survey in
                                SurveyCard(survey: survey) {
                                    // Navigate to survey detail
                                }
                                .padding(.horizontal, AppSpacing.lg)
                            }
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
                            ForEach(Array(viewModel.activities.prefix(3))) { activity in
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
            viewModel.loadSurveys()
            viewModel.loadActivity()
            authManager.refreshUserProfile()
        }
        .refreshable {
            viewModel.loadSurveys()
            viewModel.loadActivity()
            authManager.refreshUserProfile()
        }
    }
    
    private var filteredSurveys: [Survey] {
        guard let selectedCategory = selectedCategory else {
            return viewModel.surveys
        }
        
        return viewModel.surveys.filter { survey in
            survey.category.displayName == selectedCategory
        }
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
        
        // TEMPORARY: Use mock data for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingActivity = false
            self.activities = [
                ActivityItem(
                    id: "1",
                    type: .surveyCompleted,
                    title: "Survey Completed",
                    description: "Technology Usage Survey",
                    points: 150,
                    createdAt: Date().addingTimeInterval(-3600),
                    metadata: nil
                ),
                ActivityItem(
                    id: "2",
                    type: .pointsEarned,
                    title: "Points Earned",
                    description: "Bonus for quick completion",
                    points: 25,
                    createdAt: Date().addingTimeInterval(-7200),
                    metadata: nil
                ),
                ActivityItem(
                    id: "3",
                    type: .pointsRedeemed,
                    title: "Points Redeemed",
                    description: "Amazon Gift Card",
                    points: -500,
                    createdAt: Date().addingTimeInterval(-86400),
                    metadata: nil
                )
            ]
        }
        
        // Uncomment for real API calls:
        /*
        apiService.getActivityFeed(limit: 5)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingActivity = false
                    if case .failure = completion {
                        // Don't show error for activity loading
                    }
                },
                receiveValue: { [weak self] response in
                    self?.activities = response.data
                }
            )
            .store(in: &cancellables)
        */
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
