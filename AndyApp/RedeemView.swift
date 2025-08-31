//
//  RedeemView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct RedeemView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = RedeemViewModel()
    @State private var selectedCategory: RedemptionOption.RedemptionCategory?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Points display
            PointsCard(
                points: authManager.currentUser?.points ?? 0,
                title: "Available Points",
                subtitle: "Redeem for rewards"
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            

            
            // Redemption options list
            if viewModel.isLoading && viewModel.options.isEmpty {
                LoadingView(message: "Loading rewards...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    viewModel.loadOptions()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredOptions.isEmpty {
                EmptyStateView(
                    icon: "gift",
                    title: searchText.isEmpty ? "No Rewards Available" : "No Results Found",
                    message: searchText.isEmpty ? 
                        "Check back later for new rewards to redeem." :
                        "Try adjusting your search or filters.",
                    actionTitle: "Refresh",
                    action: {
                        viewModel.loadOptions()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(filteredOptions) { option in
                            RedemptionOptionCard(
                                option: option,
                                userPoints: authManager.currentUser?.points ?? 0
                            ) {
                                viewModel.selectOption(option)
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
            viewModel.loadOptions()
        }
        .onChange(of: selectedCategory) { _, _ in
            viewModel.loadOptions(category: selectedCategory)
        }
        .refreshable {
            viewModel.loadOptions(category: selectedCategory)
        }
        .sheet(item: $viewModel.selectedOption) { option in
            RedemptionDetailView(option: option)
        }
        .alert("Redeem Confirmation", isPresented: $viewModel.showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Redeem") {
                viewModel.confirmRedemption()
            }
        } message: {
            if let option = viewModel.selectedOptionForRedemption {
                Text("Are you sure you want to redeem \(option.pointsCost) points for '\(option.title)'?")
            }
        }
        .alert("Success!", isPresented: $viewModel.showingSuccess) {
            Button("OK") {
                viewModel.showingSuccess = false
                authManager.refreshUserProfile()
            }
        } message: {
            if let option = viewModel.selectedOptionForRedemption {
                Text("You have successfully redeemed '\(option.title)' for \(option.pointsCost) points!")
            }
        }
    }
    
    private var filteredOptions: [RedemptionOption] {
        var options = viewModel.options
        
        // Filter by search text
        if !searchText.isEmpty {
            options = options.filter { option in
                option.title.localizedCaseInsensitiveContains(searchText) ||
                option.description.localizedCaseInsensitiveContains(searchText) ||
                option.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return options
    }
}

// MARK: - Redeem View Model
class RedeemViewModel: ObservableObject {
    @Published var options: [RedemptionOption] = []
    @Published var selectedOption: RedemptionOption?
    @Published var selectedOptionForRedemption: RedemptionOption?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingConfirmation = false
    @Published var showingSuccess = false
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadOptions(category: RedemptionOption.RedemptionCategory? = nil) {
        isLoading = true
        error = nil
        
        // TEMPORARY: Use mock data for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.options = [
                RedemptionOption(
                    id: "1",
                    title: "Amazon Gift Card",
                    description: "$10 Amazon gift card for online shopping",
                    pointsCost: 1000,
                    imageUrl: nil,
                    isAvailable: true,
                    category: .giftCards,
                    stock: 50
                ),
                RedemptionOption(
                    id: "2",
                    title: "Starbucks Gift Card",
                    description: "$5 Starbucks gift card for coffee and treats",
                    pointsCost: 500,
                    imageUrl: nil,
                    isAvailable: true,
                    category: .giftCards,
                    stock: 25
                ),
                RedemptionOption(
                    id: "3",
                    title: "Survey Rewards T-Shirt",
                    description: "Comfortable cotton t-shirt with our logo",
                    pointsCost: 750,
                    imageUrl: nil,
                    isAvailable: true,
                    category: .merchandise,
                    stock: 10
                ),
                RedemptionOption(
                    id: "4",
                    title: "Donate to Charity",
                    description: "Donate your points to support education initiatives",
                    pointsCost: 250,
                    imageUrl: nil,
                    isAvailable: true,
                    category: .donations,
                    stock: nil
                ),
                RedemptionOption(
                    id: "5",
                    title: "Premium Coffee Mug",
                    description: "High-quality ceramic mug with survey rewards branding",
                    pointsCost: 600,
                    imageUrl: nil,
                    isAvailable: false,
                    category: .merchandise,
                    stock: 0
                )
            ]
        }
        
        // Uncomment for real API calls:
        /*
        apiService.getRedemptionOptions(category: category)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] options in
                    self?.options = options
                }
            )
            .store(in: &cancellables)
        */
    }
    
    func selectOption(_ option: RedemptionOption) {
        selectedOption = option
    }
    
    func confirmRedemption() {
        guard let option = selectedOptionForRedemption else { return }
        
        apiService.redeemPoints(optionId: option.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] transaction in
                    self?.showingSuccess = true
                    self?.selectedOptionForRedemption = nil
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Redemption Option Card Component
struct RedemptionOptionCard: View {
    let option: RedemptionOption
    let userPoints: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Image placeholder
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.primaryGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "gift.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppColors.primaryGreen)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(option.title)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Stock indicator
                        if let stock = option.stock, stock < 10 {
                            Text("\(stock) left")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.warning)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.warning.opacity(0.1))
                                .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    
                    Text(option.description)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        // Category
                        Text(option.category.displayName)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.primaryGreen)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primaryGreen.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                        
                        Spacer()
                        
                        // Points
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primaryGreen)
                            
                            Text("\(option.pointsCost)")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
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
        .buttonStyle(PlainButtonStyle())
        .disabled(!option.isAvailable || userPoints < option.pointsCost)
        .opacity((option.isAvailable && userPoints >= option.pointsCost) ? 1.0 : 0.6)
    }
}

// MARK: - Redemption Detail View
struct RedemptionDetailView: View {
    let option: RedemptionOption
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = RedeemViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Image
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .fill(AppColors.primaryGreen.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "gift.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.primaryGreen)
                        )
                    
                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(option.title)
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(option.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        // Info cards
                        HStack(spacing: AppSpacing.md) {
                            RedemptionInfoCard(
                                icon: "star.fill",
                                title: "Points Required",
                                value: "\(option.pointsCost)",
                                color: AppColors.primaryGreen
                            )
                            
                            RedemptionInfoCard(
                                icon: "tag.fill",
                                title: "Category",
                                value: option.category.displayName,
                                color: AppColors.info
                            )
                        }
                        
                        if let stock = option.stock {
                            RedemptionInfoCard(
                                icon: "cube.fill",
                                title: "Stock",
                                value: "\(stock) available",
                                color: stock < 10 ? AppColors.warning : AppColors.success
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
                    
                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        if !option.isAvailable {
                            Button("Not Available") {
                                // Show why not available
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                            .disabled(true)
                        } else if (authManager.currentUser?.points ?? 0) < option.pointsCost {
                            VStack(spacing: AppSpacing.sm) {
                                Text("Insufficient Points")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.error)
                                
                                Text("You need \(option.pointsCost - (authManager.currentUser?.points ?? 0)) more points")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(AppCornerRadius.medium)
                        } else {
                            Button("Redeem for \(option.pointsCost) Points") {
                                viewModel.selectedOptionForRedemption = option
                                viewModel.showingConfirmation = true
                                dismiss()
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
            .navigationTitle("Reward Details")
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

// MARK: - Redemption Info Card Component
struct RedemptionInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(value)
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
        .cornerRadius(AppCornerRadius.medium)
    }
}

#Preview {
    RedeemView()
}
