// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

import UIKit
@_exported import Runestone

/// SwiftUI wrapper for RuneStone's TextView
///
public struct TextViewUI: UIViewRepresentable {
    @Environment(\.language) var language: TreeSitterLanguage?
    @Environment(\.lineHeightMultiplier) var lineHeightMultiplier: Double
    @Environment(\.showSpaces) var showSpaces: Bool
    @Environment(\.showTabs) var showTabs: Bool
    @Environment(\.showLineNumbers) var showLineNumbers: Bool
    @Environment(\.characterPairs) var characterPairs: [CharacterPair]
    @Environment(\.findInteraction) var findInteraction: Bool
    
    @Binding var text: String
    let commands: TextViewCommands
    
    let onChange: (_ textView: TextView) -> ()

    /// Creates a TextViewUI with the contents of the specified string, and it will invoke the onChange method when changes to it happen
    /// - Parameters:
    ///  - text: The text to edit
    ///  - onChange: callback that is invoked when the text changes and includes a handle to the TextView, so you can extract data as needed
    public init (text: Binding<String>, onChange: ((_ textView: TextView) ->())? = nil, commands: TextViewCommands) {
        self._text = text
        self.onChange = onChange ?? { x in }
        self.commands = commands
    }
    
    public func makeUIView(context: Context) -> TextView {
        print ("Created TextView")
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
        #if os(iOS)
            
            tv.inputAccessoryView = KeyboardToolsView(textView: tv)
        #endif
        
        return tv
    }
 
    public func makeCoordinator() -> TextViewCoordinator {
        return TextViewCoordinator(text: $text, onChange: onChange, commands: commands)
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
        coordinator.commands.textView = tv
    
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
        coordinator.findInteraction = findInteraction
        tv.isFindInteractionEnabled = findInteraction
        coordinator.commands.textView = tv
    }
    
    public class TextViewCoordinator: TextViewDelegate {
        var language: TreeSitterLanguage? = nil
        var lineHeightMultiplier: Double = 1.3
        var showTabs: Bool = false
        var showSpaces: Bool = false
        var showLineNumbers: Bool = true
        var findInteraction: Bool = true
        var text: Binding<String>
        let onChange: (_ textView: TextView)->()
        let commands: TextViewCommands
        init (text: Binding<String>, onChange: @escaping (_ textView: TextView)->(), commands: TextViewCommands) {
            self.text = text
            self.onChange = onChange
            self.commands = commands
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
            //print ("Range is: loc: \(range.location) len: \(range.length)")
            
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
    static var total = 0
    var id: Int
    public init () {
        id = TextViewCommands.total
        TextViewCommands.total+=1
    }
    
    /// The textview that provides the backing services
    public var textView: TextView?
    
    /// Requests that the TextView navigates to the specified line
    public func requestGoto(line: Int) {
        textView?.goToLine(line)
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

public final class KeyboardToolsView: UIInputView {

    private weak var textView: TextView?
    private let keyboardToolsObservable: KeyboardToolsObservable
    public init(textView: TextView) {
        self.textView = textView
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        let operationButtons = [KeyboardAccessoryButton(title: "lessthan", icon: "lessthan", action: {
            //TODO: Missing implementation
        }),
                                KeyboardAccessoryButton(title: "number", icon: "number", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "percent", icon: "percent", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "and", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "or", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "greaterthan", icon: "greaterthan", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "~", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "minus", icon: "minus", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "plus", icon: "plus", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "*", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "/", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
                                KeyboardAccessoryButton(title: "^", icon: "", action: {
                                    //TODO: Missing implementation
                                }),
        ]
        let buttons = [KeyboardAccessoryButton(title: "Tab Right", icon: "arrow.right.to.line",
                                                    additionalOptions: [KeyboardAccessoryButton(title: "Tab Left", icon: "arrow.left.to.line", action: {
                                                    textView.shiftLeft()
                                                })], action: {
                                                    textView.shiftRight()
                                                    
                                                })
                       ,KeyboardAccessoryButton(title: "Undo", icon: "arrow.uturn.backward", action: {
                                                    textView.undoManager?.undo()
                                                }),
                       KeyboardAccessoryButton(title: "Redo", icon: "arrow.uturn.forward", action: {
                           textView.undoManager?.redo()
                       }),
                       KeyboardAccessoryButton(title: "Reference", icon: "eye", action: {
                            //TODO: missing implementation for reference
                            
                       }),
                       KeyboardAccessoryButton(title: "Operations", icon: "plus.forwardslash.minus", additionalOptions: operationButtons,
                                               action: {
                            
                            return
                            
                            
                       }),
                       KeyboardAccessoryButton(title: "()", icon: "", additionalOptions: [KeyboardAccessoryButton(title: "{}", icon: "", action: { 
                                                                                            //TODO: Missing Implementation
                                                                                        }), KeyboardAccessoryButton(title: "[]", icon: "", action: {
                                                                                            //TODO: Missing Implementation
                                                                                        })],
                                               action: {
                                                //TODO: Missing Implementation
                       }),
                       KeyboardAccessoryButton(title: "\"\"", icon: "", additionalOptions: [KeyboardAccessoryButton(title: "--", icon: "", action: {
                                                                                            //TODO: Missing Implementation
                                                                                        })],
                                               action: {
                                                //TODO: Missing Implementation
                       }),
                       KeyboardAccessoryButton(title: "search", icon: "magnifyingglass",
                                               action: {
                                                //TODO: Missing Implementation
                       }),
                       
                       KeyboardAccessoryButton(title: "play", icon: "play",
                                               action: {
                                                //TODO: Missing Implementation
                       }),
                       KeyboardAccessoryButton(title: "Dismiss",icon: "keyboard.chevron.compact.down", action: {
                              textView.resignFirstResponder()
                        })

                       
//                       KeyboardAccessoryButton(title: "Tab Left1", icon: "arrow.left.to.line",
//                                               additionalOptions: [KeyboardAccessoryButton(title: "Tab Right", icon: "arrow.right.to.line", action: {
//                                               textView.shiftRight()
//                                           }),
//                                           KeyboardAccessoryButton(title: "Undo", icon: "arrow.uturn.backward", action: {
//                                               textView.undoManager?.undo()
//                                           }),
//                                           KeyboardAccessoryButton(title: "Redo", icon: "arrow.uturn.forward", action: {
//                                               textView.undoManager?.redo()
//                                           }),
//                                           KeyboardAccessoryButton(title: "Dismiss",icon: "keyboard.chevron.compact.down", action: {
//                                                   textView.resignFirstResponder()
//                                               })], action: {
//                                               textView.shiftLeft()
//                                           })
                    
                            
                           
        ]
        self.keyboardToolsObservable = KeyboardToolsObservable(buttons: buttons)
        super.init(frame: frame, inputViewStyle: .keyboard)
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerCheckpoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerDidUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerDidRedoChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupView() {
        let c = UIHostingController(rootView: KeyboardToolsUI(keyboardToolsObservable: keyboardToolsObservable))
        let view = c.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        updateUndoRedoButtonStates()
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

private extension KeyboardToolsView {
    @objc private func updateUndoRedoButtonStates() {
        let undoManager = textView?.undoManager
        self.keyboardToolsObservable.setUndo(isEnabled: undoManager?.canUndo ?? false)
        self.keyboardToolsObservable.setRedo(isEnabled: undoManager?.canRedo ?? false)
    }
}

@Observable
class KeyboardToolsObservable {
    var buttons: [KeyboardAccessoryButton] = []
    
    init(buttons: [KeyboardAccessoryButton]) {
        self.buttons = buttons
    }
    
    func setUndo(isEnabled: Bool) {
        if let undoIndex = self.buttons.firstIndex(where: { $0.title.lowercased() == "undo"}) {
            var undoButton = self.buttons[undoIndex]
            undoButton.isEnabled = isEnabled
            self.buttons[undoIndex] = undoButton
        }
    }
    
    func setRedo(isEnabled: Bool) {
        if let redoIndex = self.buttons.firstIndex(where: { $0.title.lowercased() == "redo"}) {
            var redoButton = self.buttons[redoIndex]
            redoButton.isEnabled = isEnabled
            self.buttons[redoIndex] = redoButton
        }
    }
}

struct KeyboardToolsUI: View {
    @State private var globalWidth: CGFloat = 0
    @State private var buttonWidth: CGFloat = 125.0
    var keyboardToolsObservable: KeyboardToolsObservable
    var body: some View {
        HStack {
            ForEach(keyboardToolsObservable.buttons) { button in
                KeyboardToolsButton(buttonModel: button, buttonWidth: buttonWidth)
            }
        }
        .environment(\.globalWidth, globalWidth)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            GeometryReader { geometry in
                Color.clear
                .onAppear {
                    // Calculate width of whole app view, derive button width from that value and button count
                    globalWidth = geometry.size.width
                    let buttonCount = keyboardToolsObservable.buttons.count
                    let totalSpacing = CGFloat((buttonCount * 16) + 16)
                    buttonWidth = min(125.0, (globalWidth - totalSpacing) / CGFloat(keyboardToolsObservable.buttons.count))
                }
                .onChange(of: geometry.size, { old, new in
                    // Update on change width of whole app view, derive button width from that value and button count
                    globalWidth = new.width
                    let buttonCount = keyboardToolsObservable.buttons.count
                    let totalSpacing = CGFloat((buttonCount * 16) + 16)
                    buttonWidth = min(125.0, (globalWidth - totalSpacing) / CGFloat(keyboardToolsObservable.buttons.count))
                })
            }
        }
    }
}


struct KeyboardToolsButton: View {
    @Environment(\.globalWidth) var globalWidth
    @State var showextraOptions: Bool = false
    @State var dragLocation: CGPoint?
    @State var selected: KeyboardAccessoryButton? = nil
    @State var frame: CGRect? = nil
    
    let buttonModel: KeyboardAccessoryButton
    var isSelected: Bool = false
    var buttonWidth: CGFloat = 125.0
    
    var additionalOptionsCount: Int {
        return buttonModel.additionalOptions.count
    }
    // just some value to set so that it doesn't try to fill whole width
    // changing this value will have effect on additional options grid layout
    let maxAdditionalOptionsCols = 4
    
    // calculates rows number for additional options grid
    var additionalOptionsRows: Int {
        return (additionalOptionsCount - 1) / maxAdditionalOptionsCols + 1
    }
    
    // calculates columns number for additional options grid
    var additionalOptionsCols: Int {
        return additionalOptionsCount > maxAdditionalOptionsCols ? maxAdditionalOptionsCols : additionalOptionsCount
    }
    
    // calculates whole grid height based on button height, row number and spacing
    var gridHeight: CGFloat {
        return CGFloat(additionalOptionsRows) * KeyboardToolsButton.buttonHeight + CGFloat(additionalOptionsRows + 1) *  AdditionalOptionsGrid.spacing
    }
    
    // calculates whole grid width based on button width, columns number and spacing
    var gridWidth: CGFloat {
        return CGFloat(additionalOptionsCols)  * buttonWidth + CGFloat(additionalOptionsCols + 1) *  AdditionalOptionsGrid.spacing
    }
    
    // calculates additional options grid offset based on source button position
    var xOffset: CGFloat {
        guard let frame else { return 0.0 }
        let additionalOptionsXMin = frame.minX - gridWidth / 2
        let additionalOptionsXMax = frame.maxX + gridWidth / 2
        
        if additionalOptionsXMin < 0 {
            return abs(frame.minX - gridWidth / 2) - buttonWidth / 2 + (16 - AdditionalOptionsGrid.spacing)
        } else if (additionalOptionsXMax > globalWidth) {
            return -(additionalOptionsXMax - globalWidth) + buttonWidth / 2 - (16 - AdditionalOptionsGrid.spacing)
        } else {
            return 0.0
        }
    }
    
    static var buttonHeight: CGFloat = 35.0
    
    var body: some View {
        GeometryReader { gr in
            Group {
                if !buttonModel.icon.isEmpty {
                    Image(systemName: buttonModel.icon)
                } else {
                    Text(buttonModel.title)
                }
            }
            .frame(width: buttonWidth,
                   height: KeyboardToolsButton.buttonHeight)
            .background(isSelected ? Color(uiColor: .systemGray2) : Color(uiColor: .systemGray5))
            .cornerRadius(5)
            .overlay(alignment: .topTrailing, content: {
                if additionalOptionsCount > 0 {
                    Circle()
                        .foregroundColor(Color(uiColor: .systemGray))
                        .frame(width: 6, height: 6)
                        .padding(6)
                }
            })
            .onChange(of: gr.size, { oldValue, newValue in
                self.frame = gr.frame(in: .global)
            })
            .onTapGesture {
                // main button action, gets called on tap
                self.buttonModel.action()
                showextraOptions = false
            }
            .ifCond(additionalOptionsCount > 0, transform: { view in
                view
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                self.dragLocation = value.location
                            })
                            .onEnded({ _ in
                                // this is selected additional button action
                                // gets triggerd when releasing finger upon drag selection
                                self.selected?.action()
                                showextraOptions = false
                                self.selected = nil
                            })
                        
                    )
                    .simultaneousGesture(LongPressGesture (minimumDuration: 0.6).onEnded ( { isEnded in
                        // shows extra options on button hold
                        showextraOptions = true
                    }))
                    .overlay(
                        AdditionalOptionsGrid(buttons: buttonModel.additionalOptions,
                                              location: dragLocation,
                                              buttonWidth: buttonWidth,
                                              selected: $selected)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(5)
                            .frame(width: gridWidth,
                                   height: gridHeight)
                            .offset(x: xOffset, y: -(gridHeight))
                            .opacity(showextraOptions ? 1 : 0)
                        ,
                        alignment: .top)
            })
            .coordinateSpace(name: "Custom")
            .opacity(buttonModel.isEnabled ? 1 : 0.4)
            .allowsHitTesting(buttonModel.isEnabled ? true : false)
        }
        .frame(width: buttonWidth)
    }
}

struct AdditionalOptionsGrid: View {
    let buttons: [KeyboardAccessoryButton]
    let location: CGPoint?
    static let spacing: CGFloat =  8
    let buttonWidth: CGFloat
    @Binding var selected: KeyboardAccessoryButton?
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: buttonWidth,
                                               maximum: buttonWidth),
                                     spacing: AdditionalOptionsGrid.spacing)],
                  spacing: AdditionalOptionsGrid.spacing, content: {
            ForEach(buttons) { button in
                GeometryReader { gr in
                    KeyboardToolsButton(buttonModel: button, isSelected: button.id == selected?.id, buttonWidth: buttonWidth)
                        .onChange(of: location) { oldValue, newValue in
                            guard let location else { return }
                            // checks weather drag gesture is over current button
                            let targetFrame = gr.frame(in: .named("Custom"))
                            if targetFrame.contains(location) {
                                self.selected = button
                            }
                        }
                }
                .frame(height: KeyboardToolsButton.buttonHeight)
            }
        })
        .padding(AdditionalOptionsGrid.spacing)
    }
}

struct KeyboardAccessoryButton: Identifiable {
    var id: String {
        return title
    }
    let title: String
    let icon: String
    var additionalOptions: [KeyboardAccessoryButton] = []
    let action: () ->()
    var isEnabled: Bool = true
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func ifCond<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
