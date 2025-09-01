//
//  SurveyView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct SurveyView: View {
    @StateObject private var viewModel = SurveyViewModel()
    @Binding var selectedFilter: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Survey list
            if viewModel.isLoading && viewModel.surveyItems.isEmpty {
                LoadingView(message: "Loading surveys...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    viewModel.loadSurveys()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredSurveyItems.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: getEmptyStateTitle(),
                    message: getEmptyStateMessage(),
                    actionTitle: "Refresh",
                    action: {
                        viewModel.loadSurveys()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(filteredSurveyItems) { survey in
                            SurveyCard(survey: survey) {
                                // Navigate to survey detail
                                viewModel.selectSurvey(survey)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(.vertical, AppSpacing.md)
                }
            }
        }
        .background(AppColors.background)
        .onAppear {
            viewModel.loadSurveys()
        }
        .refreshable {
            viewModel.loadSurveys()
        }
        .sheet(item: $viewModel.selectedSurvey) { survey in
            SurveyTakingView(survey: survey)
        }
    }
    
    private var availableSurveys: [SurveyViewItem] {
        return viewModel.surveyItems.filter { !$0.isCompleted }
    }
    
    private var completedSurveys: [SurveyViewItem] {
        return viewModel.surveyItems.filter { $0.isCompleted }
    }
    
    private var filteredSurveyItems: [SurveyViewItem] {
        switch selectedFilter {
        case "Available":
            return availableSurveys
        case "Completed":
            return completedSurveys
        default: // "All" or nil
            return viewModel.surveyItems
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case "Available":
            return "No Available Surveys"
        case "Completed":
            return "No Completed Surveys"
        default:
            return "No Surveys Available"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch selectedFilter {
        case "Available":
            return "Check back later for new surveys to complete and earn points."
        case "Completed":
            return "Complete your first survey to see it here."
        default:
            return "Check back later for new surveys to complete and earn points."
        }
    }
}

// MARK: - Survey View Model
class SurveyViewModel: ObservableObject {
    @Published var surveyItems: [SurveyViewItem] = []
    @Published var selectedSurvey: SurveyViewItem?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadSurveys() {
        isLoading = true
        error = nil
        
        print("🔄 Loading panelist surveys...")
        
        apiService.fetchPanelistSurveys()
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
                    print("✅ Panelist surveys loaded: \(response.surveys.count) surveys")
                    
                    let surveyItems = response.surveys.map { survey in
                        SurveyViewItem.fromPanelistSurvey(survey)
                    }
                    
                    // Log survey details
                    for (index, item) in surveyItems.enumerated() {
                        print("📝 Survey \(index + 1): \(item.title) - \(item.status) - \(item.points) points")
                    }
                    
                    self?.surveyItems = surveyItems
                }
            )
            .store(in: &cancellables)
    }
    
    func selectSurvey(_ survey: SurveyViewItem) {
        selectedSurvey = survey
    }
}

// MARK: - Survey Detail View
struct SurveyDetailView: View {
    let survey: SurveyViewItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SurveyDetailViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Survey header
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(survey.title)
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(survey.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        // Survey info
                        HStack(spacing: AppSpacing.lg) {
                            SurveyInfoItem(
                                icon: "star.fill",
                                title: "Points",
                                value: "\(survey.points)",
                                color: AppColors.primaryGreen
                            )
                            
                            SurveyInfoItem(
                                icon: "clock.fill",
                                title: "Time",
                                value: survey.estimatedTime,
                                color: AppColors.warning
                            )
                            
                            SurveyInfoItem(
                                icon: "checkmark.circle.fill",
                                title: "Status",
                                value: survey.status,
                                color: survey.isCompleted ? AppColors.success : AppColors.info
                            )
                        }
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.medium)
                    .shadow(
                        color: AppShadows.small.color,
                        radius: AppShadows.small.radius,
                        x: AppShadows.small.x,
                        y: AppShadows.small.y
                    )
                    
                    // Completion info
                    if survey.isCompleted, let completedAt = survey.completedAt {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Completion Details")
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                                Text("Completed on \(completedAt)")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                        .shadow(
                            color: AppShadows.small.color,
                            radius: AppShadows.small.radius,
                            x: AppShadows.small.x,
                            y: AppShadows.small.y
                        )
                    }
                    
                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        if survey.isCompleted {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.success)
                                Text("Survey Completed")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.success)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.success.opacity(0.1))
                            .cornerRadius(AppCornerRadius.medium)
                        } else {
                            Button("Start Survey") {
                                // Navigate to survey taking view
                                viewModel.startSurvey(survey)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Survey Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Survey Detail View Model
class SurveyDetailViewModel: ObservableObject {
    func startSurvey(_ survey: SurveyViewItem) {
        // Navigate to survey taking view
        // This would be implemented in a real app
        print("🚀 Starting survey: \(survey.title)")
    }
}

// MARK: - Supporting Views
struct SurveyInfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SurveyView(selectedFilter: .constant(nil))
}
