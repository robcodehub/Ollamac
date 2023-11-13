//
//  MessageListItemView.swift
//  Ollamac
//
//  Created by Kevin Hermawan on 04/11/23.
//

import MarkdownUI
import SwiftUI
import ViewCondition

struct MessageListItemView: View {
    private var isAssistant: Bool = false
    private var isGenerating: Bool = false
    private var isFinalMessage: Bool = false
    
    let text: String
    let regenerateAction: () -> Void
    
    init(_ text: String) {
        self.text = text
        self.regenerateAction = {}
    }
    
    init(_ text: String, regenerateAction: @escaping () -> Void) {
        self.text = text
        self.regenerateAction = regenerateAction
    }
    
    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false
    
    private var isCopyButtonVisible: Bool {
        isHovered && isAssistant && !isGenerating
    }
    
    private var isRegenerateButtonVisible: Bool {
        isCopyButtonVisible && isFinalMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? "Assistant" : "You")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.accent)
            
            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Markdown(text)
                    .textSelection(.enabled)
                    .markdownTextStyle(\.text) {
                        FontSize(NSFont.preferredFont(forTextStyle: .title3).pointSize)
                    }
                    .markdownTextStyle(\.code) {
                        FontFamily(.system(.monospaced))
                    }
                    .markdownBlockStyle(\.codeBlock) { configuration in
                        configuration
                            .label
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .markdownTextStyle {
                                FontSize(NSFont.preferredFont(forTextStyle: .title3).pointSize)
                                FontFamily(.system(.monospaced))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(nsColor: .separatorColor))
                            }
                            .padding(.bottom)
                    }
            }
            
            HStack(alignment: .center, spacing: 8) {
                Button(action: copyAction) {
                    Image(systemName: isCopied ? "list.clipboard.fill" : "clipboard")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Copy message")
                .visible(if: isCopyButtonVisible)
                
                Button(action: regenerateAction) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.accessoryBar)
                .clipShape(.circle)
                .help("Regenerate response")
                .visible(if: isRegenerateButtonVisible)
            }
            .padding(.top, 8)
            .visible(if: isAssistant, removeCompletely: true)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onHover {
            isHovered = $0
            isCopied = false
        }
    }
    
    // MARK: - Actions
    private func copyAction() {
        let content = MarkdownContent(text)
        let plainText = content.renderPlainText()
        
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(plainText, forType: .string)
        
        isCopied = true
    }
    
    // MARK: - Modifiers
    public func assistant(_ isAssistant: Bool) -> MessageListItemView {
        var view = self
        view.isAssistant = isAssistant
        
        return view
    }
    
    public func generating(_ isGenerating: Bool) -> MessageListItemView {
        var view = self
        view.isGenerating = isGenerating
        
        return view
    }
    
    public func finalMessage(_ isFinalMessage: Bool) -> MessageListItemView {
        var view = self
        view.isFinalMessage = isFinalMessage
        
        return view
    }
}

#Preview {
    List {
        MessageListItemView("Hello, world!")
            .assistant(false)
        
        MessageListItemView("Hello, world!")
            .assistant(true)
        
        MessageListItemView("Hello, world!")
            .generating(true)
    }
}
