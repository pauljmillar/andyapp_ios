//
//  HomeView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCategory: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Header with points
                PointsCard(
                    points: authManager.currentUser?.points ?? 0,
                    title: "Total Points",
                    subtitle: "Earn more by completing surveys"
                )
                .padding(.horizontal, AppSpacing.lg)
                
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
                    
                    // Category filters
                    FilterPillsView(
                        categories: SurveyCategory.allCases.map { $0.displayName },
                        selectedCategory: $selectedCategory
                    )
                    
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
                
                // Stats section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Your Stats")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    HStack(spacing: AppSpacing.md) {
                        StatCard(
                            title: "Surveys Completed",
                            value: "\(authManager.currentUser?.surveysCompleted ?? 0)",
                            icon: "checkmark.circle.fill",
                            color: AppColors.success
                        )
                        
                        StatCard(
                            title: "Total Earned",
                            value: "\(authManager.currentUser?.totalEarned ?? 0) pts",
                            icon: "star.fill",
                            color: AppColors.primaryGreen
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
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
        
        apiService.getSurveys(limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.surveys = response.data
                }
            )
            .store(in: &cancellables)
    }
    
    func loadActivity() {
        isLoadingActivity = true
        
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
