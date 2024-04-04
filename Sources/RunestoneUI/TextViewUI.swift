// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

import UIKit
@_exported import Runestone

public struct TextViewUI: UIViewRepresentable {
    @Environment(\.language) var language: TreeSitterLanguage?
    @Binding var text: String
    let onChange: (_ content: String, _ location: CGRect?, _ selectionRange: (TextLocation,TextLocation))->()

    /// Creates a TextViewUI with the contents of the specified string, and it will invoke the onChange method when changes to it happen
    /// - Parameters:
    ///  - text: The text to edit
    ///  - onChange: callback that is invoked when the text changes, it includes the complete text, the location in the screen where the cursor sits, and the selection range (the last componet is the location of the cursor)
    public init (text: Binding<String>, onChange: @escaping (_ content: String, _ location: CGRect?, _ selectionRange: (TextLocation,TextLocation))->()) {
        self._text = text
        self.onChange = onChange
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
        return TextViewCoordinator(text: $text, onChange: onChange)
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
        let onChange: (_ content: String, _ location: CGRect?, _ selectionRange: (TextLocation,TextLocation))->()

        init (text: Binding<String>, onChange: @escaping (_ content: String, _ location: CGRect?, _ selectionRange: (TextLocation,TextLocation))->()) {
            self.text = text
            self.onChange = onChange
        }
        
        public func textViewDidChange(_ textView: TextView) {
            let newText = textView.text
            text.wrappedValue = newText
            var region: CGRect? = nil
            
            if let r = textView.selectedTextRange {
                region = textView.firstRect(for: r)
            }
            let range = textView.selectedRange
            let start = textView.textLocation(at: range.location)
            let end = textView.textLocation(at: range.location + range.length)
            guard let start, let end else {
                // If this happened, something very wrong went on
                print ("Start and end were not resolved out of the \(range) returned by TextView on textViewChange")
                return
            }
            onChange (newText, region, (start, end))
        }
        
        public func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            print ("Range is: loc: \(range.location) len: \(range.length)")
            
            return true
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
