//
//  RedeemView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct RedeemView: View {
    @StateObject private var authManager = ClerkAuthManager.shared
    @StateObject private var viewModel = RedeemViewModel()
    
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
            
            // Available offers list
            if viewModel.isLoading && viewModel.offers.isEmpty {
                LoadingView(message: "Loading offers...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    viewModel.loadData()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.offers.isEmpty {
                EmptyStateView(
                    icon: "gift",
                    title: "No Offers Available",
                    message: "Check back later for new redemption options.",
                    actionTitle: "Refresh",
                    action: {
                        viewModel.loadData()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        // Available offers section
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Available Offers")
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            ForEach(viewModel.offers) { offer in
                                OfferCard(offer: offer) {
                                    viewModel.redeemPoints(for: offer)
                                }
                            }
                        }
                        
                        // Historical redemptions section
                        if !viewModel.redemptions.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Text("Redemption History")
                                    .font(AppTypography.title2)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, AppSpacing.lg)
                                
                                ForEach(viewModel.redemptions.prefix(5)) { redemption in
                                    RedemptionHistoryCard(redemption: redemption)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .background(AppColors.background)
        .onAppear {
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .alert("Redemption Success!", isPresented: $viewModel.showingRedemptionSuccess) {
            Button("OK") {
                viewModel.showingRedemptionSuccess = false
                authManager.refreshUserProfile()
            }
        } message: {
            if let result = viewModel.redemptionResult {
                Text("You have successfully redeemed \(result.pointsSpent) points! Your new balance is \(result.newBalance) points.")
            }
        }
    }
}

// MARK: - Offer Card
struct OfferCard: View {
    let offer: Offer
    let onRedeem: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(offer.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(offer.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Points required
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text("\(offer.pointsRequired)")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.primaryGreen)
                        .fontWeight(.bold)
                    
                    Text("points")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Merchant info
            HStack {
                Text(offer.merchantName)
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCornerRadius.small)
                
                Spacer()
                
                // Redeem button
                Button("Redeem") {
                    onRedeem()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!offer.isActive)
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

// MARK: - Redemption History Card
struct RedemptionHistoryCard: View {
    let redemption: Redemption
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(redemption.merchantOffers.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(redemption.merchantOffers.merchantName)
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.small)
                }
                
                Spacer()
                
                // Points spent
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text("-\(redemption.pointsSpent)")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.error)
                        .fontWeight(.bold)
                    
                    Text("points")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Status and date
            HStack {
                // Status badge
                Text(redemption.status.capitalized)
                    .font(AppTypography.caption1)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(AppCornerRadius.small)
                
                Spacer()
                
                // Redemption date
                Text(formatDate(redemption.redemptionDate))
                    .font(AppTypography.caption2)
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
    
    private var statusColor: Color {
        switch redemption.status.lowercased() {
        case "completed":
            return AppColors.success
        case "pending":
            return AppColors.warning
        case "cancelled":
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Redeem View Model
class RedeemViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var redemptions: [Redemption] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingRedemptionSuccess = false
    @Published var redemptionResult: RedemptionResponse?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
    }
    
    func loadData() {
        loadOffers()
        loadRedemptionHistory()
    }
    
    func loadOffers() {
        isLoading = true
        error = nil
        
        apiService.getAvailableOffers(limit: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.offers = response.offers
                }
            )
            .store(in: &cancellables)
    }
    
    func loadRedemptionHistory() {
        apiService.getRedemptionHistory(limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load redemption history: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.redemptions = response.redemptions
                }
            )
            .store(in: &cancellables)
    }
    
    func redeemPoints(for offer: Offer) {
        isLoading = true
        error = nil
        
        apiService.redeemPoints(offerId: offer.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.redemptionResult = response
                    self?.showingRedemptionSuccess = true
                    // Refresh data after successful redemption
                    self?.loadData()
                }
            )
            .store(in: &cancellables)
    }
}
