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
        print ("Creating textView")
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

public struct FindInteractionKey: EnvironmentKey {
    public static let defaultValue: Bool = true
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
        print ("Created Command \(id)")
        TextViewCommands.total+=1
    }
    
    fileprivate var textView: TextView? {
        didSet {
            print ("Setting textView on \(id)")
        }
    }
    
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
        print ("In \(id) requesting and have \(textView)")
        textView?.findInteraction?.presentFindNavigator(showingReplace: true)
    }
}

public final class KeyboardToolsView: UIInputView {

    private weak var textView: TextView?

    public init(textView: TextView) {
        self.textView = textView
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
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
    
    lazy var buttons = [KeyboardAccessoryButton(title: "Tab Left", icon: "arrow.left.to.line",
                                                additionalOptions: [KeyboardAccessoryButton(title: "Tab Right", icon: "arrow.right.to.line", isAdditionalOption: true, action: {
                                                self.textView?.shiftRight()
                                            }),
                                            KeyboardAccessoryButton(title: "Undo", icon: "arrow.uturn.backward", isAdditionalOption: true, action: {
                                                self.textView?.undoManager?.undo()
                                            }),
                                            KeyboardAccessoryButton(title: "Redo", icon: "arrow.uturn.forward", isAdditionalOption: true, action: {
                                                self.textView?.undoManager?.redo()
                                            }),
                                            KeyboardAccessoryButton(title: "Dismiss",icon: "keyboard.chevron.compact.down", isAdditionalOption: true, action: {
                                                    self.textView?.resignFirstResponder()
                                                })], action: {
                                                self.textView?.shiftLeft()
                                            })
                
                        
                       
    ]

    private func setupView() {
        let c = UIHostingController(rootView: KeyboardToolsUI(buttons: buttons))
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
//        undoButton.isEnabled = undoManager?.canUndo ?? false
//        redoButton.isEnabled = undoManager?.canRedo ?? false
    }
}

struct KeyboardToolsUI: View {
    @State var showextraOptions: Bool = false
    let buttons: [KeyboardAccessoryButton]
    var body: some View {
        HStack {
            ForEach(buttons) { button in
                KeyboardToolsButton(buttonModel: button)
                
                
            }
            
        
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}


struct KeyboardToolsButton: View {
    @State var showextraOptions: Bool = false
    let buttonModel: KeyboardAccessoryButton
    @State var location: CGPoint?
    var isSelected: Bool = false
    
    var body: some View {
        Image(systemName: buttonModel.icon)
        .frame(width: 125, height: 35)
        .background(isSelected ? Color(uiColor: .systemGray2) : Color(uiColor: .systemGray5))
        .cornerRadius(5)
        .overlay(alignment: .topTrailing, content: {
            if buttonModel.additionalOptions.count > 0 {
                Circle()
                    .foregroundColor(Color(uiColor: .systemGray))
                    .frame(width: 6, height: 6)
                    .padding(6)
            }
        })
        .onTapGesture {
            print("Touch")
            showextraOptions = false
        }
        .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            self.location = value.location
                        })
                        .onEnded({ _ in
                            showextraOptions = false
                        })
                        
                )
        .simultaneousGesture(LongPressGesture (minimumDuration: 0.6).onEnded ( { isEnded in
            showextraOptions = true
            }))
        
        .overlay(
            AdditionalOptionsGrid(buttons: buttonModel.additionalOptions, location: location)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(5)
                        .frame(width: CGFloat(buttonModel.additionalOptions.count  * 120 + 60), height: CGFloat((buttonModel.additionalOptions.count / 6) * 80 ))
                        .offset(x: 0, y: -20)
                        .opacity(showextraOptions ? 1 : 0)
            ,
            alignment: .top)
        .coordinateSpace(name: "Custom")
    }
}

struct AdditionalOptionsGrid: View {
    let size: CGFloat = 125
    let buttons: [KeyboardAccessoryButton]
    let location: CGPoint?
    @State var selected: KeyboardAccessoryButton? = nil
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size, maximum: size))], content: {
            ForEach(buttons) { button in
                GeometryReader { gr in
                    KeyboardToolsButton(buttonModel: button, isSelected: button.id == selected?.id)
                        .onChange(of: location) { oldValue, newValue in
                            guard let location else { return }
                            let targetFrame = gr.frame(in: .named("Custom"))
                            print("TargetFrame", targetFrame)
                            print("Location", location)
                            if targetFrame.contains(location) {
                                self.selected = button
                            }
                        }
                }
                .frame(height: 35)
            }
        })
    }
}

struct KeyboardAccessoryButton: Identifiable {
    var id: String {
        return title
    }
    let title: String
    let icon: String
    var isAdditionalOption: Bool = false
    var additionalOptions: [KeyboardAccessoryButton] = []
    let action: () ->()
}
