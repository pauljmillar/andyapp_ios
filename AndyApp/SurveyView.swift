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
    @State private var selectedCategory: SurveyCategory?
    @State private var searchText = ""
    @State private var showingCompleted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Show completed toggle
            HStack {
                Toggle("Show Completed", isOn: $showingCompleted)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)
            
            // Survey list
            if viewModel.isLoading && viewModel.surveys.isEmpty {
                LoadingView(message: "Loading surveys...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    viewModel.loadSurveys()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredSurveys.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: searchText.isEmpty ? "No Surveys Available" : "No Results Found",
                    message: searchText.isEmpty ? 
                        "Check back later for new surveys to complete and earn points." :
                        "Try adjusting your search or filters.",
                    actionTitle: "Refresh",
                    action: {
                        viewModel.loadSurveys()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(filteredSurveys) { survey in
                            SurveyCard(survey: survey) {
                                // Navigate to survey detail
                                viewModel.selectSurvey(survey)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        // Load more button
                        if viewModel.hasMoreSurveys && !viewModel.isLoading {
                            Button("Load More") {
                                viewModel.loadMoreSurveys()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
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
        .onChange(of: selectedCategory) { _, _ in
            viewModel.loadSurveys(category: selectedCategory)
        }
        .refreshable {
            viewModel.loadSurveys(category: selectedCategory)
        }
        .sheet(item: $viewModel.selectedSurvey) { survey in
            SurveyDetailView(survey: survey)
        }
    }
    
    private var filteredSurveys: [Survey] {
        var surveys = viewModel.surveys
        
        // Filter by completion status
        if !showingCompleted {
            surveys = surveys.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            surveys = surveys.filter { survey in
                survey.title.localizedCaseInsensitiveContains(searchText) ||
                survey.description.localizedCaseInsensitiveContains(searchText) ||
                survey.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return surveys
    }
}

// MARK: - Survey View Model
class SurveyViewModel: ObservableObject {
    @Published var surveys: [Survey] = []
    @Published var selectedSurvey: Survey?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreSurveys = true
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private var currentCategory: SurveyCategory?
    
    func loadSurveys(category: SurveyCategory? = nil) {
        isLoading = true
        error = nil
        currentPage = 1
        currentCategory = category
        surveys = []
        
        // TEMPORARY: Use mock data for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.surveys = [
                Survey(
                    id: "1",
                    title: "Technology Usage Survey",
                    description: "Help us understand how you use technology in your daily life",
                    category: .technology,
                    pointsReward: 150,
                    estimatedTime: 10,
                    isCompleted: false,
                    isAvailable: true,
                    createdAt: Date(),
                    expiresAt: nil,
                    questions: [
                        SurveyQuestion(id: "1", question: "How many hours do you spend on your phone daily?", type: .multipleChoice, options: ["0-2", "2-4", "4-6", "6+"], required: true),
                        SurveyQuestion(id: "2", question: "What's your primary device?", type: .multipleChoice, options: ["iPhone", "Android", "Desktop", "Tablet"], required: true)
                    ]
                ),
                Survey(
                    id: "2",
                    title: "Health & Wellness",
                    description: "Share your thoughts on health and wellness habits",
                    category: .health,
                    pointsReward: 200,
                    estimatedTime: 15,
                    isCompleted: true,
                    isAvailable: true,
                    createdAt: Date(),
                    expiresAt: nil,
                    questions: [
                        SurveyQuestion(id: "3", question: "How often do you exercise?", type: .multipleChoice, options: ["Never", "Rarely", "Sometimes", "Regularly"], required: true)
                    ]
                ),
                Survey(
                    id: "3",
                    title: "Shopping Preferences",
                    description: "Tell us about your online shopping habits",
                    category: .lifestyle,
                    pointsReward: 100,
                    estimatedTime: 8,
                    isCompleted: false,
                    isAvailable: true,
                    createdAt: Date(),
                    expiresAt: nil,
                    questions: [
                        SurveyQuestion(id: "4", question: "Do you prefer online or in-store shopping?", type: .yesNo, options: nil, required: true)
                    ]
                ),
                Survey(
                    id: "4",
                    title: "Financial Habits",
                    description: "Understanding personal finance behaviors",
                    category: .finance,
                    pointsReward: 175,
                    estimatedTime: 12,
                    isCompleted: false,
                    isAvailable: true,
                    createdAt: Date(),
                    expiresAt: nil,
                    questions: [
                        SurveyQuestion(id: "5", question: "How do you primarily save money?", type: .multipleChoice, options: ["Savings Account", "Investment", "Cash", "Other"], required: true)
                    ]
                ),
                Survey(
                    id: "5",
                    title: "Entertainment Preferences",
                    description: "What do you enjoy watching and listening to?",
                    category: .entertainment,
                    pointsReward: 125,
                    estimatedTime: 7,
                    isCompleted: false,
                    isAvailable: false,
                    createdAt: Date(),
                    expiresAt: nil,
                    questions: [
                        SurveyQuestion(id: "6", question: "What's your favorite streaming service?", type: .multipleChoice, options: ["Netflix", "Disney+", "Hulu", "Other"], required: true)
                    ]
                )
            ]
            self.hasMoreSurveys = false
        }
        
        // Uncomment for real API calls:
        /*
        apiService.getSurveys(category: category, page: currentPage, limit: 20)
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
                    self?.hasMoreSurveys = response.pagination.hasNext
                }
            )
            .store(in: &cancellables)
        */
    }
    
    func loadMoreSurveys() {
        guard !isLoading && hasMoreSurveys else { return }
        
        isLoading = true
        currentPage += 1
        
        apiService.getSurveys(category: currentCategory, page: currentPage, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.currentPage -= 1
                    }
                },
                receiveValue: { [weak self] response in
                    self?.surveys.append(contentsOf: response.data)
                    self?.hasMoreSurveys = response.pagination.hasNext
                }
            )
            .store(in: &cancellables)
    }
    
    func selectSurvey(_ survey: Survey) {
        selectedSurvey = survey
    }
}

// MARK: - Survey Detail View
struct SurveyDetailView: View {
    let survey: Survey
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
                                value: "\(survey.pointsReward)",
                                color: AppColors.primaryGreen
                            )
                            
                            SurveyInfoItem(
                                icon: "clock.fill",
                                title: "Time",
                                value: survey.timeString,
                                color: AppColors.warning
                            )
                            
                            SurveyInfoItem(
                                icon: "tag.fill",
                                title: "Category",
                                value: survey.category.displayName,
                                color: AppColors.info
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
                    
                    // Questions preview
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Questions (\(survey.questions.count))")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ForEach(Array(survey.questions.prefix(3))) { question in
                            QuestionPreviewCard(question: question)
                        }
                        
                        if survey.questions.count > 3 {
                            Text("+ \(survey.questions.count - 3) more questions")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, AppSpacing.sm)
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
                        } else if survey.isAvailable {
                            Button("Start Survey") {
                                // Navigate to survey taking view
                                viewModel.startSurvey(survey)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(maxWidth: .infinity)
                        } else {
                            Button("Not Available") {
                                // Show why not available
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                            .disabled(true)
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
    func startSurvey(_ survey: Survey) {
        // Navigate to survey taking view
        // This would be implemented in a real app
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

struct QuestionPreviewCard: View {
    let question: SurveyQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(question.question)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Text(question.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.primaryGreen)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primaryGreen.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
                
                if question.required {
                    Text("Required")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .cornerRadius(AppCornerRadius.small)
    }
}

#Preview {
    SurveyView()
}
