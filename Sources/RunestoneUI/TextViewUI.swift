// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

import UIKit
@_exported import Runestone

public struct TextViewUI: UIViewRepresentable {
    @Environment(\.language) var language: TreeSitterLanguage?
    @Environment(\.lineHeightMultiplier) var lineHeightMultiplier: Double
    @Environment(\.showSpaces) var showSpaces: Bool
    @Environment(\.showTabs) var showTabs: Bool
    @Environment(\.showLineNumbers) var showLineNumbers: Bool
    @Environment(\.characterPairs) var characterPairs: [CharacterPair]
    
    @Binding var text: String
    @Binding var gotoRequest: Int?
    let onChange: (_ textView: TextView) -> ()

    /// Creates a TextViewUI with the contents of the specified string, and it will invoke the onChange method when changes to it happen
    /// - Parameters:
    ///  - text: The text to edit
    ///  - onChange: callback that is invoked when the text changes and includes a handle to the TextView, so you can extract data as needed
    public init (text: Binding<String>, onChange: ((_ textView: TextView) ->())? = nil, gotoRequest: Binding<Int?>) {
        self._text = text
        self.onChange = onChange ?? { x in }
        self._gotoRequest = gotoRequest
    }
    
    public func makeUIView(context: Context) -> TextView {
        let tv = TextView ()
        tv.text = text
        tv.editorDelegate = context.coordinator

        // Configuration options
        tv.backgroundColor = UIColor.systemBackground
        tv.showLineNumbers = context.coordinator.showLineNumbers
        tv.lineHeightMultiplier = context.coordinator.lineHeightMultiplier
        let showSpaces = context.coordinator.showSpaces
        tv.showSpaces = showSpaces
        tv.showNonBreakingSpaces = showSpaces
        tv.showSoftLineBreaks = showSpaces
        tv.showLineBreaks = showSpaces
        tv.showTabs = context.coordinator.showTabs

        //tv.kern = 0.3
        tv.isLineWrappingEnabled = false
        //tv.showPageGuide = true
        //tv.pageGuideColumn = 80
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.characterPairs = characterPairs
        
        return tv
    }
 
    public func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(text: $text, onChange: onChange, gotoRequest: $gotoRequest)
    }
    
    public func updateUIView(_ tv: Runestone.TextView, context: Context) {
        let coordinator = context.coordinator
        if let language {
            if language !== coordinator.language {
                tv.setLanguageMode(TreeSitterLanguageMode (language: language))
                coordinator.language = language
            }
        }
        coordinator.lineHeightMultiplier = lineHeightMultiplier
        tv.lineHeightMultiplier = lineHeightMultiplier
        tv.text = text
    
        coordinator.showSpaces = showSpaces
        tv.showSpaces = showSpaces
        tv.showNonBreakingSpaces = showSpaces
        tv.showSoftLineBreaks = showSpaces
        tv.showLineBreaks = showSpaces
    
        coordinator.showTabs = showTabs
        tv.showTabs = showTabs
        
        coordinator.showLineNumbers = showLineNumbers
        tv.showLineNumbers = showLineNumbers
        
        tv.characterPairs = characterPairs
        
        if let line = gotoRequest {
            tv.goToLine(line)
            self.gotoRequest = nil
        }
    }
    
    public class TextViewCoordinator: TextViewDelegate {
        var language: TreeSitterLanguage? = nil
        var lineHeightMultiplier: Double = 1.3
        var showTabs: Bool = false
        var showSpaces: Bool = false
        var showLineNumbers: Bool = true
        var text: Binding<String>
        let onChange: (_ textView: TextView)->()
        let gotoRequest: Binding<Int?>
        
        init (text: Binding<String>, onChange: @escaping (_ textView: TextView)->(), gotoRequest: Binding<Int?>) {
            self.text = text
            self.onChange = onChange
            self.gotoRequest = gotoRequest
        }
        
        public func textViewDidChange(_ textView: TextView) {
            text.wrappedValue = textView.text
            onChange (textView)
            
            // This is the code that you would need to extract location information:
//            var region: CGRect? = nil
//            
//            if let r = textView.selectedTextRange {
//                region = textView.firstRect(for: r)
//            }
//            let range = textView.selectedRange
//            let start = textView.textLocation(at: range.location)
//            let end = textView.textLocation(at: range.location + range.length)
//            guard let start, let end else {
//                // If this happened, something very wrong went on
//                print ("Start and end were not resolved out of the \(range) returned by TextView on textViewChange")
//                return
//            }
//            onChange (textView, newText, region, (start, end))
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

public struct LineHeightMultiplierKey : EnvironmentKey {
    public static let defaultValue: Double = 1.0
}

public struct ShowLineNumbersKey: EnvironmentKey {
    public static let defaultValue: Bool = true
}

public struct ShowTabsKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public struct ShowSpacesKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public struct CharacterPairsKey: EnvironmentKey {
    public static let defaultValue: [CharacterPair] = []
}

extension EnvironmentValues {
    public var language: TreeSitterLanguage? {
        get { self[LanguageKey.self] }
        set { self[LanguageKey.self] = newValue }
    }
    public var lineHeightMultiplier: Double {
        get { self[LineHeightMultiplierKey.self] }
        set { self[LineHeightMultiplierKey.self] = newValue }
    }
    public var showSpaces: Bool {
        get { self[ShowSpacesKey.self] }
        set { self[ShowSpacesKey.self] = newValue }
    }
    public var showTabs: Bool {
        get { self[ShowTabsKey.self] }
        set { self[ShowTabsKey.self] = newValue }
    }
    public var showLineNumbers: Bool {
        get { self[ShowLineNumbersKey.self] }
        set { self[ShowLineNumbersKey.self] = newValue }
    }
    public var characterPairs: [CharacterPair] {
        get { self[CharacterPairsKey.self] }
        set { self[CharacterPairsKey.self] = newValue }
    }
}

extension View {
    public func language(_ language: TreeSitterLanguage?) -> some View {
        environment(\.language, language)
    }
    public func lineHeightMultiplier (_ value: Double) -> some View {
        environment(\.lineHeightMultiplier, value)
    }
    public func showSpaces (_ value: Bool) -> some View {
        environment(\.showSpaces, value)
    }
    public func showTabs (_ value: Bool) -> some View {
        environment(\.showTabs, value)
    }
    public func showLineNumbers (_ value: Bool) -> some View {
        environment(\.showLineNumbers, value)
    }
    public func characterPairs (_ value: [CharacterPair]) -> some View {
        environment(\.characterPairs, value)
    }
}
