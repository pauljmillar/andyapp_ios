//
//  MailView.swift
//  AndyApp
//
//  Created by Paul Millar on 8/31/25.
//

import SwiftUI
import Combine

struct MailView: View {
    @StateObject private var viewModel = MailViewModel()
    @State private var searchText = ""
    @State private var showingUnreadOnly = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            VStack(spacing: AppSpacing.md) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("Search messages...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
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
                
                // Filter toggle
                HStack {
                    Toggle("Unread Only", isOn: $showingUnreadOnly)
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
            }
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)
            
            // Message list
            if viewModel.isLoading && viewModel.messages.isEmpty {
                LoadingView(message: "Loading messages...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    viewModel.loadMessages()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredMessages.isEmpty {
                EmptyStateView(
                    icon: "envelope",
                    title: searchText.isEmpty ? "No Messages" : "No Results Found",
                    message: searchText.isEmpty ? 
                        "You're all caught up! Check back later for new messages." :
                        "Try adjusting your search or filters.",
                    actionTitle: "Refresh",
                    action: {
                        viewModel.loadMessages()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(filteredMessages) { message in
                            MessageCard(message: message) {
                                viewModel.selectMessage(message)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        // Load more button
                        if viewModel.hasMoreMessages && !viewModel.isLoading {
                            Button("Load More") {
                                viewModel.loadMoreMessages()
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
            viewModel.loadMessages()
        }
        .refreshable {
            viewModel.loadMessages()
        }
        .sheet(item: $viewModel.selectedMessage) { message in
            MessageDetailView(message: message)
        }
    }
    
    private var filteredMessages: [MailMessage] {
        var messages = viewModel.messages
        
        // Filter by read status
        if showingUnreadOnly {
            messages = messages.filter { !$0.isRead }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            messages = messages.filter { message in
                message.subject.localizedCaseInsensitiveContains(searchText) ||
                message.body.localizedCaseInsensitiveContains(searchText) ||
                message.sender.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return messages
    }
}

// MARK: - Mail View Model
class MailViewModel: ObservableObject {
    @Published var messages: [MailMessage] = []
    @Published var selectedMessage: MailMessage?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreMessages = true
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    
    func loadMessages() {
        isLoading = true
        error = nil
        currentPage = 1
        messages = []
        
        // TEMPORARY: Use mock data for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.messages = [
                MailMessage(
                    id: "1",
                    subject: "Welcome to Survey Rewards!",
                    body: "Thank you for joining our community. Start completing surveys to earn points and redeem them for amazing rewards.",
                    isRead: false,
                    isImportant: true,
                    sender: "Survey Rewards Team",
                    createdAt: Date().addingTimeInterval(-3600),
                    attachments: nil
                ),
                MailMessage(
                    id: "2",
                    subject: "New Survey Available",
                    body: "We have a new technology survey available that matches your profile. Complete it to earn 150 points!",
                    isRead: false,
                    isImportant: false,
                    sender: "Survey System",
                    createdAt: Date().addingTimeInterval(-7200),
                    attachments: nil
                ),
                MailMessage(
                    id: "3",
                    subject: "Points Redeemed Successfully",
                    body: "Your Amazon gift card has been processed and will be delivered to your email within 24 hours.",
                    isRead: true,
                    isImportant: false,
                    sender: "Rewards System",
                    createdAt: Date().addingTimeInterval(-86400),
                    attachments: [
                        MailAttachment(id: "1", name: "receipt.pdf", url: "", size: 1024, type: "pdf")
                    ]
                ),
                MailMessage(
                    id: "4",
                    subject: "Weekly Summary",
                    body: "This week you completed 3 surveys and earned 425 points. Great job!",
                    isRead: true,
                    isImportant: false,
                    sender: "Survey Rewards Team",
                    createdAt: Date().addingTimeInterval(-172800),
                    attachments: nil
                )
            ]
            self.hasMoreMessages = false
        }
        
        // Uncomment for real API calls:
        /*
        apiService.getMailMessages(page: currentPage, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.messages = response.data
                    self?.hasMoreMessages = response.pagination.hasNext
                }
            )
            .store(in: &cancellables)
        */
    }
    
    func loadMoreMessages() {
        guard !isLoading && hasMoreMessages else { return }
        
        isLoading = true
        currentPage += 1
        
        apiService.getMailMessages(page: currentPage, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.currentPage -= 1
                    }
                },
                receiveValue: { [weak self] response in
                    self?.messages.append(contentsOf: response.data)
                    self?.hasMoreMessages = response.pagination.hasNext
                }
            )
            .store(in: &cancellables)
    }
    
    func selectMessage(_ message: MailMessage) {
        selectedMessage = message
        markAsRead(message)
    }
    
    private func markAsRead(_ message: MailMessage) {
        guard !message.isRead else { return }
        
        apiService.markMessageAsRead(id: message.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] updatedMessage in
                    // Update the message in the list
                    if let index = self?.messages.firstIndex(where: { $0.id == message.id }) {
                        self?.messages[index] = updatedMessage
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Message Card Component
struct MessageCard: View {
    let message: MailMessage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Avatar
                Circle()
                    .fill(AppColors.primaryGreen)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(message.sender.prefix(1).uppercased())
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(message.subject)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Important indicator
                        if message.isImportant {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.warning)
                        }
                        
                        // Unread indicator
                        if !message.isRead {
                            Circle()
                                .fill(AppColors.primaryGreen)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(message.sender)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                    
                    Text(message.body)
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(timeAgo)
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        // Attachment indicator
                        if let attachments = message.attachments, !attachments.isEmpty {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("\(attachments.count)")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
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
        .buttonStyle(PlainButtonStyle())
        .opacity(message.isRead ? 0.8 : 1.0)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.createdAt, relativeTo: Date())
    }
}

// MARK: - Message Detail View
struct MessageDetailView: View {
    let message: MailMessage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Message header
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            // Avatar
                            Circle()
                                .fill(AppColors.primaryGreen)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(message.sender.prefix(1).uppercased())
                                        .font(AppTypography.title3)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(message.sender)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(timeAgo)
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Important indicator
                            if message.isImportant {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.warning)
                            }
                        }
                        
                        Text(message.subject)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
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
                    
                    // Message body
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Message")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(message.body)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
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
                    
                    // Attachments
                    if let attachments = message.attachments, !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Attachments (\(attachments.count))")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.textPrimary)
                            
                            ForEach(attachments) { attachment in
                                AttachmentCard(attachment: attachment)
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
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Message")
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
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.createdAt, relativeTo: Date())
    }
}

// MARK: - Attachment Card Component
struct AttachmentCard: View {
    let attachment: MailAttachment
    
    var body: some View {
        Button(action: {
            // Open attachment
        }) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primaryGreen)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(attachment.name)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(attachment.type.uppercased()) • \(formatFileSize(attachment.size))")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primaryGreen)
            }
            .padding(AppSpacing.md)
            .background(AppColors.background)
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

#Preview {
    MailView()
}
