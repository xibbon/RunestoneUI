//
// SwiftUI wrapper for Runestone's TextView, it additionally adds the possibility of showing
// breakpoint markers
//
// Copyright 2024 Miguel de Icaza
//
import SwiftUI

import UIKit
@_exported import Runestone

/// SwiftUI wrapper for RuneStone's TextView
///
/// Various properties are exposed to control the TextView externally, but for operations that can not
/// be exposed via a binding, users create a `TextViewCommands` instance and pass it here, and
/// then they can issue commands to control the `TextViewUI` in that way.
public struct TextViewUI: UIViewRepresentable {
    @Environment(\.language) var language: TreeSitterLanguage?
    @Environment(\.lineHeightMultiplier) var lineHeightMultiplier: Double
    @Environment(\.showSpaces) var showSpaces: Bool
    @Environment(\.showTabs) var showTabs: Bool
    @Environment(\.showLineNumbers) var showLineNumbers: Bool
    @Environment(\.highlightLine) var highlightLine: Int?
    @Environment(\.characterPairs) var characterPairs: [CharacterPair]
    @Environment(\.findInteraction) var findInteraction: Bool
    
    @Binding var text: String
    @Binding var breakpoints: Set<Int>
    @Binding var keyboardOffset: CGFloat
    let commands: TextViewCommands
    let onChange: (_ textView: TextView) -> ()
    let onLoaded: (_ textView: TextView) -> ()
    let gutterTap: (_ textView: TextView, _ line: Int) -> ()

    /// Creates a TextViewUI with the contents of the specified string, and it will invoke the onChange method when changes to it happen
    /// - Parameters:
    ///  - text: The text to edit, it is updated as the user makes changes to it
    ///  - commands: you create an instance of this class and pass it here, and you can then control the TextViewUI by issuing commands there
    ///  - keyboardOffset: if this is provided, the location of the keyboard offset is
    ///  - breakpoints: Optional, if set is a set of line numbers that should be flagged with a breakpoint indicator in the gutter portion of the text view
    ///  - onLoaded: method invoked when the textView is created, and it gets a pointer to the underlying TextView
    ///  - onChange: callback that is invoked when the text changes and includes a handle to the TextView, so you can extract data as needed
    public init (text: Binding<String>, commands: TextViewCommands, keyboardOffset: Binding<CGFloat> = .constant(0), breakpoints: Binding<Set<Int>> = .constant([]), onLoaded: ((_ textView: TextView) ->())? = nil, onChange: ((_ textView: TextView) ->())? = nil, gutterTap: ((_ textView: TextView, _ line: Int) -> ())? = nil) {
        self._text = text
        self._keyboardOffset = keyboardOffset
        self.onChange = onChange ?? { x in }
        self.onLoaded = onLoaded ?? { x in }
        self.gutterTap = gutterTap ?? { x, y in }
        self.commands = commands
        self._breakpoints = breakpoints
    }
    
    public func makeUIView(context: Context) -> TextView {
        let tv = PTextView ()
        tv.text = text
        tv.editorDelegate = context.coordinator
        tv.delegate = context.coordinator
        tv.ptDelegate = context.coordinator

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
        tv.highlightedLine = context.coordinator.highlightLine

        //tv.kern = 0.3
        tv.isLineWrappingEnabled = false
        tv.gutterMinimumCharacterCount = 3
        //tv.showPageGuide = true
        //tv.pageGuideColumn = 80
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.characterPairs = characterPairs
        tv.lineSelectionDisplayType = .line
        #if os(iOS)
            tv.inputAccessoryView = KeyboardToolsView(textView: tv)
        #endif
        
        onLoaded (tv)
        return tv
    }
 
    public func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(text: $text, keyboardOffset: $keyboardOffset, onChange: onChange, gutterTap: gutterTap, commands: commands)
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
    
        coordinator.showTabs = showTabs
        tv.showTabs = showTabs
        
        coordinator.showLineNumbers = showLineNumbers
        coordinator.highlightLine = highlightLine
        tv.showLineNumbers = showLineNumbers
        
        tv.characterPairs = characterPairs
        coordinator.findInteraction = findInteraction
        tv.isFindInteractionEnabled = findInteraction
        coordinator.commands.textView = tv
    }
    
    public class TextViewCoordinator: NSObject, TextViewDelegate, UIScrollViewDelegate, PTextViewDelegate {
        var language: TreeSitterLanguage? = nil
        var lineHeightMultiplier: Double = 1.3
        var showTabs: Bool = false
        var showSpaces: Bool = false
        var showLineNumbers: Bool = true
        var highlightLine: Int? = nil
        var findInteraction: Bool = true
        var text: Binding<String>
        var keyboardOffset: Binding<CGFloat>

        let onChange: (_ textView: TextView)->()
        let gutterTap: (_ textView: TextView, _ line: Int) -> ()
        let commands: TextViewCommands
        var lastEnd: UITextPosition?
        
        init (text: Binding<String>, keyboardOffset: Binding<CGFloat>, onChange: @escaping (_ textView: TextView)->(), gutterTap: @escaping (_ textView: TextView, _ line: Int) -> (), commands: TextViewCommands) {
            self.text = text
            self.keyboardOffset = keyboardOffset
            self.onChange = onChange
            self.commands = commands
            self.gutterTap = gutterTap
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let pt = scrollView as? PTextView else { return }
            pt.overlayView.frame.origin.y = scrollView.contentOffset.y
        }
        
        public func textViewDidChange(_ textView: TextView) {
            let newText = textView.text
            text.wrappedValue =  newText
            onChange (textView)

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
        
        public func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            //print ("Range is: loc: \(range.location) len: \(range.length)")
            
            return true
        }
        
        func updateKeyboardLocation (_ textView: PTextView, _ location: CGFloat) {
            print ("Location is \(location) and the textView content is: \(textView.contentOffset.y)")
            keyboardOffset.wrappedValue = location - textView.contentOffset.y
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

public struct HighlightLineKey: EnvironmentKey {
    public static let defaultValue: Int? = nil
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

public struct FindInteractionKey: EnvironmentKey {
    public static let defaultValue: Bool = true
}

public struct GlobalWidthKey: EnvironmentKey {
    public static let defaultValue: CGFloat = 0.0
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
    public var highlightLine: Int? {
        get { self[HighlightLineKey.self] }
        set { self[HighlightLineKey.self] = newValue }
    }
    public var characterPairs: [CharacterPair] {
        get { self[CharacterPairsKey.self] }
        set { self[CharacterPairsKey.self] = newValue }
    }
    public var findInteraction: Bool {
        get { self[FindInteractionKey.self] }
        set { self[FindInteractionKey.self] = newValue }
    }
    
    public var globalWidth: CGFloat {
        get { self[GlobalWidthKey.self] }
        set { self[GlobalWidthKey.self] = newValue }
    }
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

    /// Character pairs are used by the editor to automatically insert a trailing character when the user types the leading character.
    /// Common usages of this includes the " character to surround strings and { } to surround a scope.
    public func characterPairs (_ value: [CharacterPair]) -> some View {
        environment(\.characterPairs, value)
    }
    
    /// Controls whether the built-in find-interaction UI is shown on the TextViewUI, defaults to true.
    /// If you set this to false, you can not request the find UI from it.
    public func findInteraction (_ enable: Bool) -> some View {
        environment(\.findInteraction, enable)
    }
}

/// Create an instance of this variable to trigger various actions on the TextView externally
/// you pass a binding to this value, and then call methods of this to trigger certain actions.
public class TextViewCommands {
    public init () {
    }
    
    public var keyboardAnchor: UIView?
    
    /// The textview that provides the backing services
    public weak var textView: TextView?
    
    /// Requests that the TextView navigates to the specified line
    public func requestGoto(line: Int) {
        guard let textView else { return }
        if textView.goToLine(line) {
            // For some reason goToLine does not always update the cursor position,
            // not really a problem, because textView.goToLine already does this
            // same thing for another workaround related to the caret position
            textView.resignFirstResponder()
            textView.becomeFirstResponder()
        }
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
    
    /// The current selection range of the text view as a UITextRange.
    public var selectedTextRange: UITextRange? {
        get {
            textView?.selectedTextRange
        }
        set {
            textView?.selectedTextRange = newValue
        }
    }
}

protocol PTextViewDelegate: AnyObject {
    func updateKeyboardLocation (_ textView: PTextView, _ location: CGFloat)
}

/// This is a subclass of TextView, which I use to implement the breakpoint features
class PTextView: TextView {
    // We put the breakpoint symbols here, under the line number text
    var underlayView: UIView
    var keyboardAnchor: KeyboardAnchorView
    
    // We put the tap handler here, over the view, on the gutter
    var overlayView: OverlayView
    weak var ptDelegate: PTextViewDelegate?
    
    var breakpointSpace: CGFloat {
        let f = theme.font
        return f.ascender + abs(f.descender) + f.leading
    }

    // This class exists just so that we can get nice information at debug time
    class BreakpointView: UIView {
    }
    
    // The view we are looking for is the TextInput.TextInputView.lineNumbersContainerView
    func getHostView () -> UIView? {
        subviews.dropFirst(4).first?.subviews.dropFirst(2).first
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
                    coordinator.gutterTap (container, line.lineNumber)
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
        if let host = getHostView () {
            if underlayView.superview == nil {
                underlayView.frame = host.frame
                host.addSubview(underlayView)
            }
            underlayView.frame = host.frame
        }
        bringSubviewToFront(overlayView)
        updateBreakpointView()
    }
    
    var breakpointViews: [Int:UIView] = [:]
    var breakpoints = Set<Int>()
    
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
