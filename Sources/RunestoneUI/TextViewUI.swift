// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import UIKit
@_exported import Runestone

public struct TextViewUI: UIViewRepresentable {
    @Binding var text: String
    @Environment(\.language) var language: TreeSitterLanguage?
    
    public init (text: Binding<String>) {
        self._text = text
    }
    
    public func makeUIView(context: Context) -> TextView {
        let tv = TextView ()
        tv.text = text
        tv.editorDelegate = context.coordinator

        // Configuration options
        tv.backgroundColor = UIColor.systemBackground
        tv.showLineNumbers = true
        //tv.lineHeightMultiplier = 1.2
        //tv.kern = 0.3
        //tv.showSpaces = true
        //tv.showNonBreakingSpaces = true
        //tv.showTabs = true
        //tv.showLineBreaks = true
        //tv.showSoftLineBreaks = true
        tv.isLineWrappingEnabled = false
        //tv.showPageGuide = true
        //tv.pageGuideColumn = 80
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        
        return tv
    }
 
    public func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(text: $text)
    }
    
    public func updateUIView(_ uiView: Runestone.TextView, context: Context) {
        if let language {
            if language !== context.coordinator.language {
                uiView.setLanguageMode(TreeSitterLanguageMode (language: language))
                context.coordinator.language = language
            }
        }
        uiView.text = text
        
    }
    
    public class TextViewCoordinator: TextViewDelegate {
        var language: TreeSitterLanguage? = nil
        var text: Binding<String>
        
        init (text: Binding<String>) {
            self.text = text
        }
        
        public func textViewDidChange(_ textView: TextView) {
            text.wrappedValue = textView.text
        }
    }
}

public struct LanguageKey : EnvironmentKey {
    public static let defaultValue: TreeSitterLanguage? = nil
}

extension EnvironmentValues {
    public var language: TreeSitterLanguage? {
        get { self[LanguageKey.self] }
        set { self[LanguageKey.self] = newValue }
    }
}

extension View {
    public func language(_ language: TreeSitterLanguage) -> some View {
        environment(\.language, language)
    }
}
