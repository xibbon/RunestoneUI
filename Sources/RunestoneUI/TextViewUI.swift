//
// SwiftUI wrapper for Runestone's TextView, it additionally adds the possibility of showing
// breakpoint markers
//
// Copyright 2024 Miguel de Icaza
//
import SwiftUI
import GameController
import UIKit
@_exported import Runestone

/// Messages that are posted by the TextViewUI
public protocol TextViewUIDelegate {
    /// Callback that is invoked when the text changes and includes a handle to the TextView, so you can extract data as needed
    func uitextViewChanged (_ textView: TextView)
    /// Method invoked when the textView is created, and it gets a pointer to the underlying TextView
    func uitextViewLoaded (_ textView: TextView)
    /// Method invoked when the user tapped on the specified line in the gutter portion of the UI, usually used to toggle breakpoints on/off
    func uitextViewGutterTapped (_ textView: TextView, line: Int)
    /// The user tapped on "Lookup Symbol", so perform something with the symbol that was extracted (provided in `word`)
    func uitextViewRequestWordLookup (_ textView: TextView, at: UITextPosition, word: String)
    /// Invoked when the selectionchanges
    func uitextViewDidChangeSelection (_ textView: TextView)
    /// Invoked when virtual keyboard inserts return and determines weather to insert completion as result to return
    func uitextViewTryCompletion() -> Bool
    /// Invoked when there is reason to recalculate breakpoints when lines are added or removed
    func uitextViewDidInvalidateBreakpoints(_ textView: TextView, changeLineIndex: Int, diff: Int)
}

/// Default protocol implementaiton, does nothing
public extension TextViewUIDelegate{
    func uitextViewChanged (_ textView: TextView) {}
    func uitextViewLoaded (_ textView: TextView) {}
    func uitextViewGutterTapped (_ textView: TextView, line: Int) {}
    func uitextViewRequestWordLookup (_ textView: TextView, at: UITextPosition, word: String) {}
    func uitextViewDidChangeSelection (_ textView: TextView) {}
    func uitextViewTryCompletion() -> Bool { return false }
    func textViewDidInvalidateBreakpoints(_ textView: TextView, changeLineIndex: Int, diff: Int) {}
}
/// SwiftUI wrapper for RuneStone's TextView
///
/// Various properties are exposed to control the TextView externally, but for operations that can not
/// be exposed via a binding, users create a `TextViewCommands` instance and pass it here, and
/// then they can issue commands to control the `TextViewUI` in that way.
///
/// Some configuration options that can be applied include:
/// - `.language(TreeSitterLanguage?)` - to activate that particular language on the buffer
/// - `lineHeightMultiplier(Double)` - controls the height of the lines
/// - `.showSpaces(Bool)` - The text view renders invisible spaces in RuneStone
/// - `.showTabs(Bool)` - The text view renders invisible tabs when enabled. The tabsSymbol is used to render tabs.
/// - `.showLineNumbers(Bool)` - Controls whether to show line numbers in the gutter.
/// - `.highlightLine(Int?)` - If not nil, highlights this line in the editor
/// - `.characterPairs([CharacterPair])` - Character pairs are used by the editor to
/// automatically insert a trailing character when the user types the leading character.
/// - `.findInteraction(Bool)` - Controls whether the built-in find-interaction UI is shown on the TextViewUI,
/// defaults to true.
/// - `.includeLookupSymbol(Bool)` - Controls whether the "Lookup Symbol" menu is added to the text editor
public struct TextViewUI: UIViewRepresentable {
    @Environment(\.language) var language: TreeSitterLanguage?
    @Environment(\.lineHeightMultiplier) var lineHeightMultiplier: Double
    @Environment(\.showSpaces) var showSpaces: Bool
    @Environment(\.showTabs) var showTabs: Bool
    @Environment(\.showLineNumbers) var showLineNumbers: Bool
    @Environment(\.highlightLine) var highlightLine: Int?
    @Environment(\.characterPairs) var characterPairs: [CharacterPair]
    @Environment(\.findInteraction) var findInteraction: Bool
    @Environment(\.includeLookupSymbol) var includeLookupSymbol: Bool
    @Environment(\.autoCorrection) var autoCorrection: TextAutoCorrection
    @Environment(\.spellChecking) var spellChecking: SpellCheckType
    @Environment(\.indentStrategy) var indentStrategy: IndentStrategy
    @Environment(\.lineWrappingEnabled) var lineWrappingEnabled: Bool
    @Environment(\.characterPairTrailingComponentDeletionMode) var characterPairTrailingComponentDeletionMode: CharacterPairTrailingComponentDeletionMode
    @Environment(\.theme) var theme: Runestone.Theme
    @Binding var text: String
    @Binding var breakpoints: Set<Int>
    @Binding var keyboardOffset: CGFloat
    @State var showInputAccessoryView: Bool?
    let commands: TextViewCommands
    let delegate: TextViewUIDelegate

    /// Creates a TextViewUI with the contents of the specified string, and it will invoke the onChange method when changes to it happen
    /// - Parameters:
    ///  - text: The text to edit, it is updated as the user makes changes to it
    ///  - commands: you create an instance of this class and pass it here, and you can then control the TextViewUI by issuing commands there
    ///  - keyboardOffset: if this is provided, the location of the keyboard offset is
    ///  - breakpoints: Optional, if set is a set of line numbers that should be flagged with a breakpoint indicator in the gutter portion of the text view
    ///  - delegate: instance that implements the various methods required to support the TextView
    public init (
        text: Binding<String>,
        commands: TextViewCommands,
        keyboardOffset: Binding<CGFloat> = .constant(0),
        breakpoints: Binding<Set<Int>> = .constant([]),
        delegate: TextViewUIDelegate
    ) {
        self._text = text
        self._keyboardOffset = keyboardOffset
        self.delegate = delegate
        self.commands = commands
        self._breakpoints = breakpoints
    }

    public func makeUIView(context: Context) -> TextView {
        let tv = PTextView ()
        for x in tv.interactions {
            print (x)
        }
        let menu = UIEditMenuInteraction(delegate: context.coordinator)
        tv.addInteraction(menu)
        tv.text = text
        tv.editorDelegate = context.coordinator
        tv.delegate = context.coordinator
        tv.ptDelegate = context.coordinator

        // Configuration options
        tv.backgroundColor = UIColor.systemBackground
        tv.includeLookupSymbol = context.coordinator.includeLookupSymbol
        tv.showLineNumbers = context.coordinator.showLineNumbers
        tv.lineHeightMultiplier = context.coordinator.lineHeightMultiplier
        let showSpaces = context.coordinator.showSpaces
        tv.showSpaces = showSpaces
        tv.showNonBreakingSpaces = showSpaces
        tv.showSoftLineBreaks = showSpaces
        tv.showLineBreaks = showSpaces
        tv.showTabs = context.coordinator.showTabs
        tv.highlightedLine = context.coordinator.highlightLine
        tv.autocorrectionType = switch context.coordinator.autocorrectionType {
        case .default:  UITextAutocorrectionType.default
        case .yes: UITextAutocorrectionType.yes
        case .no: UITextAutocorrectionType.no
        }
        tv.spellCheckingType = switch context.coordinator.spellcheckType {
        case .default: UITextSpellCheckingType.default
        case .yes: UITextSpellCheckingType.yes
        case .no: UITextSpellCheckingType.no
        }
        tv.indentStrategy = context.coordinator.indentStrategy
        tv.characterPairTrailingComponentDeletionMode = context.coordinator.characterPairTrailingComponentDeletionMode
        //tv.kern = 0.3
        tv.isLineWrappingEnabled = context.coordinator.lineWrappingEnabled
        tv.gutterMinimumCharacterCount = 3
        //tv.showPageGuide = true
        //tv.pageGuideColumn = 80
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.keyboardType = .alphabet
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.characterPairs = characterPairs
        tv.lineSelectionDisplayType = .line
        #if os(iOS)
            tv.inputAssistantItem.leadingBarButtonGroups = []
            tv.inputAssistantItem.trailingBarButtonGroups = []
            if GCKeyboard.coalesced == nil {
                tv.inputAccessoryView = KeyboardToolsView(textView: tv)
            }
        #endif

        delegate.uitextViewLoaded(tv)
        return tv
    }

    public func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(text: $text, keyboardOffset: $keyboardOffset, delegate: delegate, commands: commands, includeLookupSymbol: includeLookupSymbol) { isConnected in
            self.showInputAccessoryView = !isConnected
        }
    }

    public func updateUIView(_ tv: TextView, context: Context) {
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
        if let ptv = tv as? PTextView {
            ptv.setBreakpoints(new: breakpoints)
        }
        coordinator.commands.textView = tv

        tv.gutterTrailingPadding = (tv as? PTextView)?.breakpointSpace ?? 0
        coordinator.showSpaces = showSpaces
        tv.showSpaces = showSpaces
        tv.showNonBreakingSpaces = showSpaces
        tv.showSoftLineBreaks = showSpaces
        tv.showLineBreaks = showSpaces
        tv.autocorrectionType = switch autoCorrection {
        case .default:  UITextAutocorrectionType.default
        case .yes: UITextAutocorrectionType.yes
        case .no: UITextAutocorrectionType.no
        }
        tv.spellCheckingType = switch spellChecking {
        case .default: UITextSpellCheckingType.default
        case .yes: UITextSpellCheckingType.yes
        case .no: UITextSpellCheckingType.no
        }
        coordinator.showTabs = showTabs
        coordinator.indentStrategy = indentStrategy
        tv.indentStrategy = indentStrategy
        coordinator.characterPairTrailingComponentDeletionMode = characterPairTrailingComponentDeletionMode
        coordinator.lineWrappingEnabled = lineWrappingEnabled
        tv.showTabs = showTabs
        tv.characterPairTrailingComponentDeletionMode = characterPairTrailingComponentDeletionMode

        coordinator.showLineNumbers = showLineNumbers
        coordinator.highlightLine = highlightLine
        tv.highlightedLine = highlightLine
        tv.showLineNumbers = showLineNumbers
        tv.isLineWrappingEnabled = coordinator.lineWrappingEnabled

        tv.characterPairs = characterPairs
        coordinator.findInteraction = findInteraction
        tv.isFindInteractionEnabled = findInteraction
        if tv.theme !== theme {
            tv.theme = theme
        }
        coordinator.commands.textView = tv
#if !os(visionOS)
        // small delay required otherwise issues with view update during view rendering occur
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let showInputAccessoryView {
                if showInputAccessoryView {
                    tv.inputAccessoryView = KeyboardToolsView(textView: tv)
                    tv.reloadInputViews()
                } else {
                    tv.inputAccessoryView = nil
                    tv.reloadInputViews()
                }
                self.showInputAccessoryView = nil
            }
        }
#endif
    }

    public static func dismantleUIView(_ uiView: TextView, coordinator: TextViewCoordinator) {
#if !os(visionOS)
        if let toolsInputView = uiView.getUnderlyingInputAccessoryView() as? KeyboardToolsView {
            toolsInputView.cleanup()
        }
#endif
    }

    public class TextViewCoordinator: NSObject, TextViewDelegate, UIScrollViewDelegate, PTextViewDelegate, UIEditMenuInteractionDelegate {
        var language: TreeSitterLanguage? = nil
        var lineHeightMultiplier: Double = 1.3
        var lineWrappingEnabled: Bool = true
        var showTabs: Bool = false
        var showSpaces: Bool = false
        var showLineNumbers: Bool = true
        var highlightLine: Int? = nil
        var autocorrectionType: TextAutoCorrection = .default
        var spellcheckType: SpellCheckType = .default
        var findInteraction: Bool = true
        var text: Binding<String>
        var keyboardOffset: Binding<CGFloat>
        var includeLookupSymbol: Bool
        let delegate: TextViewUIDelegate
        let commands: TextViewCommands
        var lastEnd: UITextPosition?
        var indentStrategy: IndentStrategy = .tab(length: 4)
        var characterPairTrailingComponentDeletionMode: CharacterPairTrailingComponentDeletionMode = .immediatelyFollowingLeadingComponent
        var updateKeyboardConnection: (Bool) -> ()

        init (text: Binding<String>, keyboardOffset: Binding<CGFloat>, delegate: TextViewUIDelegate, commands: TextViewCommands, includeLookupSymbol: Bool, updateKeyboardConnection: @escaping (Bool) -> ()) {
            self.text = text
            self.keyboardOffset = keyboardOffset
            self.delegate = delegate
            self.commands = commands
            self.includeLookupSymbol = includeLookupSymbol
            self.updateKeyboardConnection = updateKeyboardConnection
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidConnect),
                name: .GCKeyboardDidConnect,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardDidDisconnect),
                name: .GCKeyboardDidDisconnect,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidConnect, object: nil)
            NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidDisconnect, object: nil)
        }

        @objc private func keyboardDidConnect(notification: Notification) {
            updateKeyboardConnection(true)
        }

        @objc private func keyboardDidDisconnect(notification: Notification) {
            updateKeyboardConnection(false)
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let pt = scrollView as? PTextView else { return }
            pt.overlayView.frame.origin.y = scrollView.contentOffset.y
        }

        public func textViewDidChange(_ textView: TextView) {
            let newText = textView.text
            text.wrappedValue =  newText
            delegate.uitextViewChanged(textView)

            if let last = lastEnd {
                switch textView.compare(last, to: textView.endOfDocument) {
                case .orderedAscending:
                    break
                case .orderedDescending:
                    (textView as? PTextView)?.updateBreakpointView()
                case .orderedSame:
                    break
                }
            } else {
                (textView as? PTextView)?.updateBreakpointView()
            }
            self.lastEnd = textView.endOfDocument
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

        public func textViewDidChangeSelection (_ textView: TextView) {
            delegate.uitextViewDidChangeSelection(textView)
        }

        public func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            //print ("Range is: loc: \(range.location) len: \(range.length)")

            return true
        }

        func lookup(_ textView: PTextView, at: UITextPosition, word: String) {
            delegate.uitextViewRequestWordLookup(textView, at: at, word: word)
        }

        func updateKeyboardLocation (_ textView: PTextView, _ location: CGFloat) {
            keyboardOffset.wrappedValue = location - textView.contentOffset.y
        }

        public func textView(_ textView: TextView, canReplaceTextIn highlightedRange: HighlightedRange) -> Bool {
            return true
        }

        public func textViewTryCompletion() -> Bool {
            return delegate.uitextViewTryCompletion()
        }

        public func textViewIndent(_ textView: TextView, undo: Bool) {
            if undo {
                textView.shiftLeft()
            } else {
                textView.shiftRight()
            }
        }

        public func textViewDidInvalidateBreakpoints(_ textView: TextView, changeLineIndex: Int, diff: Int) {
            delegate.uitextViewDidInvalidateBreakpoints(textView, changeLineIndex: changeLineIndex, diff: diff)
        }
    }
}

/// The autocorrection behavior of TextViewUI
public enum TextAutoCorrection {
    /// Specifies an appropriate autocorrection behavior for the current script system.
    case `default`
    /// Enables autocorrection behavior.
    case yes
    /// Disables autocorrection behavior.
    case no

}

/// The spell-checking style for the TextViewUI
public enum SpellCheckType {
    /// Specifies the default spell checking behavior
    case `default`
    /// Enables spell-checking behavior.
    case yes
    /// Disables spell-checking behavior.
    case no
}

extension EnvironmentValues {
    @Entry public var language: TreeSitterLanguage? = nil
    @Entry public var lineHeightMultiplier: Double = 1.0
    @Entry public var showSpaces: Bool = false
    @Entry public var showTabs: Bool = false
    @Entry public var showLineNumbers: Bool = true
    @Entry public var includeLookupSymbol: Bool = false
    @Entry public var highlightLine: Int? = nil
    @Entry public var lineWrappingEnabled: Bool = true
    @Entry public var characterPairs: [CharacterPair] = []
    @Entry public var findInteraction: Bool = true
    @Entry public var globalWidth: CGFloat = 0.0
    @Entry public var spellChecking: SpellCheckType = .default
    @Entry public var autoCorrection: TextAutoCorrection = .default
    @Entry public var indentStrategy: IndentStrategy = .tab(length: 4)
    @Entry public var characterPairTrailingComponentDeletionMode: CharacterPairTrailingComponentDeletionMode = .disabled
    @Entry public var theme: Runestone.Theme = DefaultTheme()
}

extension View {
    /// Used to choose the indentation and coloring tree sitter for the text in the UI
    public func language(_ language: TreeSitterLanguage?) -> some View {
        environment(\.language, language)
    }

    /// The line-height is multiplied with the value.
    public func lineHeightMultiplier (_ value: Double) -> some View {
        environment(\.lineHeightMultiplier, value)
    }

    /// The text view renders invisible spaces in RuneStone
    public func showSpaces (_ value: Bool) -> some View {
        environment(\.showSpaces, value)
    }

    /// The text view renders invisible tabs when enabled. The tabsSymbol is used to render tabs.
    public func showTabs (_ value: Bool) -> some View {
        environment(\.showTabs, value)
    }

    /// Enable to show line numbers in the gutter.
    public func showLineNumbers (_ value: Bool) -> some View {
        environment(\.showLineNumbers, value)
    }

    /// If not nil, highlights this line in the editor
    public func highlightLine (_ value: Int?) -> some View {
        environment(\.highlightLine, value)
    }

    /// Controls whether the "Lookup Symbol" menu is added to the text editor
    public func includeLookupSymbol (_ value: Bool) -> some View {
        environment(\.includeLookupSymbol, value)
    }

    /// Character pairs are used by the editor to automatically insert a trailing character when the user types the leading character.
    /// Common usages of this includes the " character to surround strings and { } to surround a scope.
    public func characterPairs (_ value: [CharacterPair]) -> some View {
        environment(\.characterPairs, value)
    }

    /// When line wrapping is disabled, users can scroll the text view horizontally to see the entire line.
    public func lineWrappingEnabled(_ value: Bool) -> some View {
        environment(\.lineWrappingEnabled, value)
    }

    /// Controls whether the built-in find-interaction UI is shown on the TextViewUI, defaults to true.
    /// If you set this to false, you can not request the find UI from it.
    public func findInteraction (_ enable: Bool) -> some View {
        environment(\.findInteraction, enable)
    }

    /// Controls the spell checking used by the TextViewUI
    public func spellChecking(_ value: SpellCheckType) -> some View {
        environment(\.spellChecking, value)
    }

    /// Controls the autocorrection used by the TextViewUI
    public func autoCorrection(_ value: TextAutoCorrection) -> some View {
        environment(\.autoCorrection, value)
    }

    /// Strategy to use when indenting text, defaults to tabs using 4 spaces to be rendered
    public func indentStrategy(_ value: IndentStrategy) -> some View {
        environment(\.indentStrategy, value)
    }

    /// Determines what should happen to the trailing component of a character pair when deleting the leading component.
    public func characterPairTrailingComponentDeletionMode(_ value: CharacterPairTrailingComponentDeletionMode) -> some View {
        environment(\.characterPairTrailingComponentDeletionMode, value)
    }

    /// Injects Runestone theme to environment
    public func theme(_ value: Runestone.Theme) -> some View {
        environment(\.theme, value)
    }
}

/// Create an instance of this variable to trigger various actions on the TextView externally
/// you pass a binding to this value, and then call methods of this to trigger certain actions.
public class TextViewCommands {
    public init () {
    }

    public var keyboardAnchor: UIView?

    /// The textview that provides the backing services
    public weak var textView: TextView? {
        didSet {
            if let textView, pendingTextView.count > 0 {
                DispatchQueue.main.async {
                    let copyPendingTasks = self.pendingTextView
                    self.pendingTextView = []
                    for callback in copyPendingTasks {
                        callback(textView)
                    }
                }
            }
        }
    }

    var pendingTextView: [(TextView) -> ()] = []

    /// The TextView might not be instantiated when your code runs, use this to call a method when the textView is realized
    public func onTextViewReady(callback: @escaping (TextView)->()) {
        if let textView {
            callback(textView)
        } else {
            pendingTextView.append(callback)
        }
    }

    /// Requests that the TextView navigates to the specified line
    public func requestGoto(line: Int, completion: (() -> ())? = nil) {
        onTextViewReady { textView in
            if textView.goToLine(line) {
                // For some reason goToLine does not always update the cursor position,
                // not really a problem, because textView.goToLine already does this
                // same thing for another workaround related to the caret position
                if textView.isFirstResponder {
                    textView.resignFirstResponder()
                    textView.becomeFirstResponder()
                }
                if let completion {
                    completion()
                }
            }
        }
    }
    
    public func becomeFirstResponder() {
        textView?.becomeFirstResponder()
    }

    /// Requests that the find UI is shown
    public func requestFind() {
        textView?.findInteraction?.presentFindNavigator(showingReplace: false)
    }

    /// Requests that the find and replace UI is shown
    public func requestFindAndReplace() {
        textView?.findInteraction?.presentFindNavigator(showingReplace: true)
    }

    /// Returns the position in a document that is closest to a specified point.
    public func closestPosition (to point: CGPoint) -> UITextPosition? {
        return textView?.closestPosition(to: point)
    }

    /// Returns the range between two text positions.
    public func textRange(from: UITextPosition, to: UITextPosition) -> UITextRange? {
        return textView?.textRange(from: from, to: to)
    }

    /// Replaces the text that is in the specified range.
    public func replace(_ range: UITextRange, withText text: String) {
        textView?.replace(range, withText: text)
    }

    /// Replaces the `text` in the specified `line` with the provided `withText`, the line is matched based on the .regularExpression/.caseInsensitive bits in NSString.CompareOptions, other options are ignored
    public func replaceTextAt (line: Int, text: String, withText: String, options: NSString.CompareOptions) {
        guard let textView else { return }
        guard let lineLoc = textView.location(at: TextLocation(lineNumber: line, column: 0)),
              let endLocP1 = textView.location(at: TextLocation(lineNumber: line+1, column: 0)),
              endLocP1 > 0 else {
            return
        }
        let sq = SearchQuery(text: text, matchMethod: options.contains(.regularExpression) ? .regularExpression : .contains, isCaseSensitive: !options.contains(.caseInsensitive), range: NSRange(location: lineLoc, length: endLocP1-lineLoc))
        let results = textView.search(for: sq, replacingMatchesWith: withText)

        // TODO: we currently only handle in the UI the first element of a match, not multiple elements per line
        guard let op = results.first else {
            return
        }
        let batch = BatchReplaceSet(replacements: [BatchReplaceSet.Replacement(range: op.range, text: op.replacementText)])
        textView.replaceText(in: batch)
    }

    /// The current selection range of the text view as a UITextRange.
    public var selectedTextRange: UITextRange? {
        get {
            textView?.selectedTextRange
        }
        set {
            textView?.selectedTextRange = newValue
        }
    }

    public func toggleInlineComment(_ delimiter: String) {
        textView?.toggleInlineComment(delimiter)
    }

    public func indent() {
        textView?.shiftRight()
    }

    public func unIdent() {
        textView?.shiftLeft()
    }
    
    public func getBufferInfo() -> (currentLine: Int?, lineCount: Int)? {
        guard let textView else { return nil }
        
        let loc = textView.textLocation(at: textView.selectedRange.location)
        return (loc?.lineNumber ?? nil, textView.lineCount())
    }
}

protocol PTextViewDelegate: AnyObject {
    func updateKeyboardLocation(_ textView: PTextView, _ location: CGFloat)
    func lookup(_ textView: PTextView, at: UITextPosition, word: String)
}

/// This is a subclass of TextView, which I use to implement the breakpoint features
class PTextView: TextView {
    // We put the breakpoint symbols here, under the line number text
    var underlayView: UIView
    var keyboardAnchor: KeyboardAnchorView
    var includeLookupSymbol: Bool

    // We put the tap handler here, over the view, on the gutter
    var overlayView: OverlayView
    weak var ptDelegate: PTextViewDelegate?

    var breakpointSpace: CGFloat {
        let f = theme.font
        return f.ascender + abs(f.descender) + f.leading
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let v = super.canPerformAction(action, withSender: sender)
        //print ("Can perform \(action) -> \(v)")
        return v
    }

    func getWordUnderSelection(pos: UITextRange) -> String? {
        if let left = tokenizer.position(from: pos.start, toBoundary: .word, inDirection: .layout(.left)),
           let right = tokenizer.position(from: pos.start, toBoundary: .word, inDirection: .layout(.right)),
           let range = textRange(from: left, to: right),
           let text = text(in: range) {
            return text
        }
        return nil
    }

    override func buildMenu(with builder: any UIMenuBuilder) {
        super.buildMenu(with: builder)
        builder.remove(menu: .autoFill)
        builder.remove(menu: .share)

        if includeLookupSymbol {
            if let selection = selectedTextRange, let word = getWordUnderSelection (pos: selection) {
                // Need to callout and determine if this is:
                // * Needs a lookup option

                let action = UIAction(title: "Lookup Symbol") { action in
                    self.ptDelegate?.lookup(self, at: selection.start, word: word)
                }
                builder.replace(menu: .lookup, with: UIMenu(title: "", image: nil, identifier: nil, options: [.displayInline], children: [action]))
            }
        } else {
            builder.remove(menu: .lookup)
        }
    }

    // This class exists just so that we can get nice information at debug time
    class BreakpointView: UIView {
    }

    // We put this window on top of the textview, so we can capture taps on the gutter, which
    // we translate into enabling/disabling a breakpoint.
    class OverlayView: UIView {
        weak var container: PTextView?

        override init (frame: CGRect) {
            self.container = nil
            super.init (frame: frame)

            // To debug if the view is in the right place, you can use this
            // backgroundColor = UIColor (red: 0.5, green: 0.0, blue: 0.0, alpha: 0.5)
            backgroundColor = UIColor.clear
            isUserInteractionEnabled = true

            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gutterTapped)))
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        @objc
        func gutterTapped (sender: UITapGestureRecognizer) {
            guard let container else { return }
            guard let coordinator = container.editorDelegate as? TextViewUI.TextViewCoordinator else {
                return
            }
            guard sender.state == .ended else { return }
            let location = sender.location (in: self)
            if let tapLocation = container.closestPosition(to: CGPoint(x: location.x, y: location.y+container.contentOffset.y)) {
                let tapOffset = container.offset(from: container.beginningOfDocument, to: tapLocation)
                if let line = container.textLocation(at: tapOffset) {
                    coordinator.delegate.uitextViewGutterTapped(container, line: line.lineNumber)
                }
            }
        }
    }

    /// This view sole purpose is to track the location of the bottom we can render on
    class KeyboardAnchorView: UIView {
        weak var container: PTextView? = nil

        public override var frame: CGRect {
            get {
                super.frame
            }
            set {
                super.frame = newValue
                if let container {
                    container.ptDelegate?.updateKeyboardLocation(container, frame.minY)
                }
            }
        }
        public override var bounds: CGRect {
            get {
                super.bounds
            }
            set {
                super.bounds = newValue
                if let container {
                    container.ptDelegate?.updateKeyboardLocation(container, frame.minY)
                }
            }
        }
    }

    override public init(frame: CGRect) {
        underlayView = BreakpointView(frame: frame)
        underlayView.backgroundColor = UIColor.clear
        overlayView = OverlayView (frame: frame)
        keyboardAnchor = KeyboardAnchorView()
        keyboardAnchor.backgroundColor = .red
        keyboardAnchor.translatesAutoresizingMaskIntoConstraints = false
        includeLookupSymbol = false
        super.init (frame: frame)
        overlayView.container = self
        keyboardAnchor.container = self
        addSubview(overlayView)
        addSubview(keyboardAnchor)

        // Add constraints to the keyboard anchor view to track the location of the keyboard
        NSLayoutConstraint.activate([
            keyboardAnchor.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardAnchor.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardAnchor.heightAnchor.constraint(equalToConstant: 10),
            keyboardAnchor.widthAnchor.constraint(equalToConstant: 10),
            keyboardAnchor.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let f = frame
        overlayView.frame = CGRect (x: 0, y: contentOffset.y, width: gutterWidth, height: f.height)

        let host = lineNumbersContainerView
        if underlayView.superview == nil {
            underlayView.frame = host.frame
            host.addSubview(underlayView)
        }
        underlayView.frame = host.frame

        bringSubviewToFront(overlayView)
        updateBreakpointView()
    }

    var breakpointViews: [Int:UIView] = [:]


    func setBreakpoints (new: Set<Int>) {
        let removed = breakpoints.subtracting(new)
        for line in removed {
            if let view = breakpointViews [line] {
                view.removeFromSuperview()
                breakpointViews.removeValue(forKey: line)
            }
        }
        let added = new.subtracting(breakpoints)
        self.breakpoints = new
        updateBreakpointView(for: added)
    }

    func updateBreakpointView() {
        updateBreakpointView(for: breakpoints)
    }

    func updateBreakpointView (for breakpoints: Set<Int>) {
        for bpLine in breakpoints {
            let tl = TextLocation (lineNumber: bpLine, column: 0)
            guard let loc = location(at: tl) else {
                if let v = breakpointViews.removeValue(forKey: bpLine) {
                    v.removeFromSuperview()
                }
                return
            }
            guard let p = position(from: beginningOfDocument, offset: loc) else {
                if let v = breakpointViews.removeValue(forKey: bpLine) {
                    v.removeFromSuperview()
                }
                return
            }
            let rect = caretRect(for: p)
            let bpFrame = CGRect(x: gutterLeadingPadding, y: rect.minY, width: gutterWidth-gutterLeadingPadding-5, height: rect.height)
            if let bpView = breakpointViews [bpLine] {
                bpView.frame = bpFrame
            } else {
                let prv = PointedRectangleView(frame: bpFrame)
                prv.backgroundColor = UIColor.clear
                underlayView.addSubview(prv)
                breakpointViews [bpLine] = prv
            }
        }
    }

    class PointedRectangleView: UIView {
        let arrowSize: CGFloat = 5

        override func draw(_ rect: CGRect) {
            // Define the start point of the path
            let startPoint = CGPoint(x: rect.minX, y: rect.midY)

            // Define the other points of the path
            let topLeft = CGPoint(x: rect.minX, y: rect.minY)
            let topRight = CGPoint(x: rect.maxX - arrowSize, y: rect.minY)
            let pointRight = CGPoint(x: rect.maxX, y: rect.midY)
            let bottomRight = CGPoint(x: rect.maxX - arrowSize, y: rect.maxY)
            let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

            // Create the bezier path
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addLine(to: topLeft)
            path.addLine(to: topRight)
            path.addLine(to: pointRight)
            path.addLine(to: bottomRight)
            path.addLine(to: bottomLeft)
            path.close()

            UIColor.systemBlue.setFill()
            //Color.accentColor.opacity(0.3)
            path.fill()

            // Set the stroke color and stroke the path
            UIColor.tintColor.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }
}

#if DEBUG
struct DemoPreview: View, TextViewUIDelegate {
    func uitextViewDidInvalidateBreakpoints(_ textView: Runestone.TextView, changeLineIndex: Int, diff: Int) {
        
    }
    
    @State var text = "Hello\n\tWorld\nCat"

    var body: some View {
        TextViewUI(text: $text, commands: TextViewCommands(), delegate: self)
            .highlightLine(0)
            .showTabs(true)
    }

}

#Preview {
    DemoPreview()
}
#endif

/// Default theme used by Runestone when no other theme has been set.
public class CodeEditorTheme: Runestone.Theme {
    public var font: UIFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    public var textColor: UIColor { base.textColor }
    public var gutterBackgroundColor: UIColor { base.gutterBackgroundColor }
    public var gutterHairlineColor: UIColor { base.gutterHairlineColor }
    public var lineNumberColor: UIColor { base.lineNumberColor }
    public var lineNumberFont: UIFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    public var selectedLineBackgroundColor: UIColor { base.selectedLineBackgroundColor }
    public var highlightedLineBackgroundColor: UIColor {base.highlightedLineBackgroundColor }
    public var selectedLinesLineNumberColor: UIColor { base.selectedLinesLineNumberColor }
    public var selectedLinesGutterBackgroundColor: UIColor {base.selectedLinesGutterBackgroundColor }
    public var invisibleCharactersColor: UIColor { base.invisibleCharactersColor }
    public var pageGuideHairlineColor: UIColor { base.pageGuideHairlineColor }
    public var pageGuideBackgroundColor: UIColor { base.pageGuideBackgroundColor }
    public var markedTextBackgroundColor: UIColor { base.markedTextBackgroundColor }

    public func textColor(for highlightName: String) -> UIColor? {
        base.textColor(for: highlightName)
    }

    var base: Runestone.Theme
    public init(base: Runestone.Theme = DefaultTheme(), fontFamily: String = "", fontSize: CGFloat = 16) {
        self.base = base
        self.setFont(fontFamily, fontSize)
    }

    public func setFont(_ family: String, _ size: CGFloat) {
        if family == "" || family == "System Font" {
            font = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        } else {
            font = UIFont(name: family, size: size) ?? UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        lineNumberFont = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
