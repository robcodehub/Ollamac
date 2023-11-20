//
//  MessageView.swift
//  Ollamac
//
//  Created by Kevin Hermawan on 04/11/23.
//

import OptionalKit
import SwiftUI
import SwiftUIIntrospect
import ViewCondition
import ViewState

struct MessageView: View {
    private var chat: Chat
    
    @Environment(\.modelContext) private var modelContext
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(MessageViewModel.self) private var messageViewModel
    @Environment(OllamaViewModel.self) private var ollamaViewModel
    
    @FocusState private var isEditorFocused: Bool
    @State private var isEditorExpanded: Bool = false
    @State private var viewState: ViewState? = nil
    
    @State private var prompt: String = ""
    
    init(for chat: Chat) {
        self.chat = chat
    }
    
    var isGenerating: Bool {
        messageViewModel.sendViewState == .loading
    }
    
    var promptInputDisabled: Bool {
        if let model = chat.model, model.isNotAvailable { return true }
        
        return false
    }
    
    var sendButtonDisabled: Bool {
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if let model = chat.model, model.isNotAvailable { return true }
        
        return false
    }
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List(messageViewModel.messages.indices, id: \.self) { index in
                let message = messageViewModel.messages[index]
                
                MessageListItemView(message.prompt ?? "")
                    .assistant(false)
                
                MessageListItemView(message.response ?? "") {
                    regenerateAction(for: message)
                }
                .assistant(true)
                .generating(message.response.isNil && isGenerating)
                .finalMessage(index == messageViewModel.messages.endIndex - 1)
                .error(message.error, message: messageViewModel.sendViewState?.errorMessage)
                .id(message)
            }
            .onAppear {
                scrollToBottom(scrollViewProxy)
            }
            .onChange(of: messageViewModel.messages) {
                scrollToBottom(scrollViewProxy)
            }
            .onChange(of: messageViewModel.messages.last?.response?.count) {
                scrollToBottom(scrollViewProxy)
            }
            
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 16) {
                    PromptEditor(prompt: $prompt, large: false)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                isEditorExpanded = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .buttonStyle(.plain)
                            .keyboardShortcut("e", modifiers: .command)
                            .help("Expand editor (⌘ + E)")
                        }
                        .focused($isEditorFocused)
                        .disabled(promptInputDisabled)
                        .onSubmit(sendAction)
                    
                    Button(action: sendAction) {
                        Label("Send", systemImage: "paperplane")
                            .padding(8)
                            .foregroundStyle(.white)
                            .help("Send message (Return)")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sendButtonDisabled)
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .hide(if: isEditorExpanded)
        }
        .navigationTitle(chat.name)
        .navigationSubtitle(chat.model?.name ?? "")
        .task {
            initAction()
        }
        .onChange(of: chat) {
            initAction()
        }
        .sheet(isPresented: $isEditorExpanded, onDismiss: { isEditorFocused = true }) {
            PromptEditorExpandedView(prompt: $prompt) {
                sendAction()
            }
        }
    }
    
    // MARK: - Actions
    private func initAction() {
        try? messageViewModel.fetch(for: chat)
        
        isEditorFocused = true
    }
    
    private func sendAction() {
        guard !isGenerating else { return }

        let message = Message(prompt: prompt, response: nil)
        message.context = messageViewModel.messages.last?.context ?? []
        message.chat = chat

        Task {
            try chatViewModel.modify(chat)
            prompt = ""
            await messageViewModel.send(message)
        }
    }
    
    private func regenerateAction(for message: Message) {
        guard !isGenerating else { return }

        message.context = messageViewModel.messages.last?.context ?? []
        message.response = nil

        Task {
            try chatViewModel.modify(chat)
            await messageViewModel.regenerate(message)
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard messageViewModel.messages.count > 0 else { return }
        let lastIndex = messageViewModel.messages.count - 1
        let lastMessage = messageViewModel.messages[lastIndex]
        
        proxy.scrollTo(lastMessage, anchor: .bottom)
    }
}
