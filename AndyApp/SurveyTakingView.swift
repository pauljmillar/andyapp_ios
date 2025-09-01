//
//  SurveyTakingView.swift
//  AndyApp
//
//  Created by Paul Millar on 9/1/25.
//

import SwiftUI
import Combine

struct SurveyTakingView: View {
    let survey: SurveyViewItem
    @StateObject private var viewModel = SurveyTakingViewModel()
    @StateObject private var surveyState = SurveyTakingState()
    @Environment(\.dismiss) private var dismiss
    @State private var showingExitConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress header
                VStack(spacing: AppSpacing.md) {
                    // Survey title and progress
                    VStack(spacing: AppSpacing.sm) {
                        Text(survey.title)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(surveyState.progressText)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Progress bar
                    if surveyState.questions.count > 0 {
                        ProgressView(value: Double(surveyState.currentQuestionIndex + 1), total: Double(surveyState.questions.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primaryGreen))
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
                .background(AppColors.cardBackground)
                
                // Question content
                if viewModel.isLoading {
                    LoadingView(message: "Loading survey...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        viewModel.loadSurveyData(survey: survey)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let currentQuestion = surveyState.currentQuestion {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Question display
                            QuestionView(
                                question: currentQuestion,
                                response: surveyState.getResponse(for: currentQuestion.id),
                                onResponseChanged: { response in
                                    surveyState.setResponse(for: currentQuestion.id, value: response)
                                }
                            )
                            .padding(.horizontal, AppSpacing.lg)
                            
                            // Navigation buttons
                            HStack(spacing: AppSpacing.md) {
                                // Previous button
                                Button("Previous") {
                                    surveyState.goToPreviousQuestion()
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .disabled(!surveyState.canGoPrevious)
                                
                                Spacer()
                                
                                // Next/Submit button
                                Button(surveyState.isLastQuestion ? "Submit" : "Next") {
                                    surveyState.goToNextQuestion()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!surveyState.canGoNext)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                        .padding(.vertical, AppSpacing.lg)
                    }
                } else {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "No Questions Available",
                        message: "This survey doesn't have any questions to display.",
                        actionTitle: "Go Back",
                        action: { dismiss() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        showingExitConfirmation = true
                    }
                    .foregroundColor(AppColors.error)
                }
            }
            .onAppear {
                surveyState.setSurvey(survey)
                viewModel.loadSurveyData(survey: survey)
            }
            .onReceive(viewModel.$surveyQuestions) { questions in
                if !questions.isEmpty {
                    surveyState.setQuestions(questions)
                }
            }
            .onReceive(surveyState.$shouldSubmitSurvey) { shouldSubmit in
                if shouldSubmit {
                    Task {
                        await viewModel.submitSurvey(survey: survey, responses: surveyState.responses)
                    }
                }
            }
            .alert("Exit Survey?", isPresented: $showingExitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to exit? Your progress will be lost.")
            }
            .sheet(isPresented: $viewModel.showingCompletion) {
                SurveyCompletionView(
                    survey: survey,
                    pointsEarned: survey.points,
                    onDismiss: {
                        dismiss()
                    }
                )
            }
        }
    }
}

// MARK: - Survey Taking View Model
class SurveyTakingViewModel: ObservableObject {
    @Published var surveyQuestions: [SurveyQuestion] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingCompletion = false
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadSurveyData(survey: SurveyViewItem) {
        isLoading = true
        error = nil
        
        print("🔄 Loading survey data for: \(survey.title)")
        
        // Load survey questions
        apiService.fetchSurveyQuestions(surveyId: survey.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error loading survey questions: \(error)")
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ Survey questions loaded: \(response.questions.count) questions")
                    self?.surveyQuestions = response.questions
                }
            )
            .store(in: &cancellables)
    }
    
    func submitSurvey(survey: SurveyViewItem, responses: [String: String]) async {
        print("🚀 Submitting survey completion...")
        print("📝 Survey ID: \(survey.id)")
        print("📝 Responses: \(responses)")
        
        // TODO: Implement actual API calls for survey submission
        // For now, just show completion and log the data
        
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            print("✅ Survey submission completed, showing completion view")
            showingCompletion = true
        }
    }
}

// MARK: - Question View
struct QuestionView: View {
    let question: SurveyQuestion
    let response: String?
    let onResponseChanged: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Question text
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(question.questionText)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                if question.isRequired {
                    Text("Required")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                }
            }
            
            // Question input based on type
            switch question.displayType {
            case .rating:
                RatingQuestionView(
                    response: response,
                    onResponseChanged: onResponseChanged
                )
            case .yesNo:
                YesNoQuestionView(
                    response: response,
                    onResponseChanged: onResponseChanged
                )
            case .multipleChoice:
                MultipleChoiceQuestionView(
                    options: question.options ?? [],
                    response: response,
                    onResponseChanged: onResponseChanged
                )
            case .checkbox:
                CheckboxQuestionView(
                    options: question.options ?? [],
                    response: response,
                    validationRules: question.validationRules,
                    onResponseChanged: onResponseChanged
                )
            case .text:
                TextQuestionView(
                    response: response,
                    validationRules: question.validationRules,
                    onResponseChanged: onResponseChanged
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
    }
}

// MARK: - Question Type Views
struct RatingQuestionView: View {
    let response: String?
    let onResponseChanged: (String) -> Void
    
    @State private var selectedRating: Int = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Rate from 1 to 5")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: AppSpacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        selectedRating = rating
                        onResponseChanged("\(rating)")
                    }) {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(rating <= selectedRating ? AppColors.primaryGreen : AppColors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            if let response = response, let rating = Int(response) {
                selectedRating = rating
            }
        }
    }
}

struct YesNoQuestionView: View {
    let response: String?
    let onResponseChanged: (String) -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Button("Yes") {
                    onResponseChanged("Yes")
                }
                .buttonStyle(SelectionButtonStyle(isSelected: response == "Yes"))
                .frame(maxWidth: .infinity)
                
                Button("No") {
                    onResponseChanged("No")
                }
                .buttonStyle(SelectionButtonStyle(isSelected: response == "No"))
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MultipleChoiceQuestionView: View {
    let options: [String]
    let response: String?
    let onResponseChanged: (String) -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    onResponseChanged(option)
                }
                .buttonStyle(SelectionButtonStyle(isSelected: response == option))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CheckboxQuestionView: View {
    let options: [String]
    let response: String?
    let validationRules: [String: String]?
    let onResponseChanged: (String) -> Void
    
    @State private var selectedOptions: Set<String> = []
    
    private var maxSelections: Int? {
        if let rules = validationRules,
           let maxSelectionsString = rules["max_selections"],
           let maxSelections = Int(maxSelectionsString) {
            return maxSelections
        }
        return nil
    }
    
    private var minSelections: Int? {
        if let rules = validationRules,
           let minSelectionsString = rules["min_selections"],
           let minSelections = Int(minSelectionsString) {
            return minSelections
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selectedOptions.contains(option) {
                        selectedOptions.remove(option)
                    } else {
                        if let maxSelections = maxSelections, selectedOptions.count >= maxSelections {
                            // Remove oldest selection if at max
                            if let oldest = selectedOptions.first {
                                selectedOptions.remove(oldest)
                            }
                        }
                        selectedOptions.insert(option)
                    }
                    updateResponse()
                }) {
                    HStack {
                        Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(selectedOptions.contains(option) ? AppColors.primaryGreen : AppColors.textSecondary)
                        
                        Text(option)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, AppSpacing.sm)
            }
            
            // Validation info
            if let minSelections = minSelections, let maxSelections = maxSelections {
                Text("Select \(minSelections) to \(maxSelections) options")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            } else if let minSelections = minSelections {
                Text("Select at least \(minSelections) option\(minSelections == 1 ? "" : "s")")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            } else if let maxSelections = maxSelections {
                Text("Select up to \(maxSelections) option\(maxSelections == 1 ? "" : "s")")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .onAppear {
            if let response = response, !response.isEmpty {
                selectedOptions = Set(response.components(separatedBy: ","))
            }
        }
    }
    
    private func updateResponse() {
        let responseString = selectedOptions.isEmpty ? "" : selectedOptions.sorted().joined(separator: ",")
        onResponseChanged(responseString)
    }
}

struct TextQuestionView: View {
    let response: String?
    let validationRules: [String: String]?
    let onResponseChanged: (String) -> Void
    
    @State private var text: String = ""
    @State private var showingError = false
    
    private var maxLength: Int? {
        if let rules = validationRules,
           let maxLengthString = rules["max_length"],
           let maxLength = Int(maxLengthString) {
            return maxLength
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            TextField("Enter your answer...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .onChange(of: text) { _, newValue in
                    onResponseChanged(newValue)
                }
            
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(AppTypography.caption1)
                        .foregroundColor(text.count > maxLength ? AppColors.error : AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            text = response ?? ""
        }
    }
}

// MARK: - Selection Button Style
struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.body)
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.primaryGreen : AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? AppColors.primaryGreen : AppColors.divider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Survey Completion View
struct SurveyCompletionView: View {
    let survey: SurveyViewItem
    let pointsEarned: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.success)
            
            // Success message
            VStack(spacing: AppSpacing.md) {
                Text("Survey Completed!")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Thank you for completing '\(survey.title)'")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Points earned
            VStack(spacing: AppSpacing.sm) {
                Text("Points Earned")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("+\(pointsEarned)")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.primaryGreen)
                    .fontWeight(.bold)
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            
            // Done button
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.xl)
        .background(AppColors.background)
    }
}

#Preview {
    SurveyTakingView(survey: SurveyViewItem(
        id: "preview",
        title: "Sample Survey",
        description: "A sample survey for preview",
        points: 50,
        status: "Ready",
        estimatedTime: "5 minutes",
        isCompleted: false,
        completedAt: nil
    ))
}
