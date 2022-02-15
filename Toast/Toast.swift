//
//  Toast.swift
//
//  Created by Lonelie on 08/04/2019.
//  Copyright © 2019 Lonelie. All rights reserved.
//

import UIKit

public class Toast {
    public enum Duration: TimeInterval {
        case short  = 1.0
        case medium = 3.0
        case long   = 5.0
    }
    
    public enum Gravity {
        case top, middle, bottom
    }
    
    public enum Context {
        case topWindow, keyWindow
    }
    
    public struct ViewStyle {
        public typealias AnimationBlock = (UIView)->Void
        public var font: UIFont
        public var fontColor: UIColor
        public var backgroundColor: UIColor
        public var minimumSize: CGSize
        public var cornerRadius: (CGFloat, UIRectCorner)
        public var paddingToScreen: UIEdgeInsets?
        public var showAnimation: (TimeInterval, AnimationBlock?, AnimationBlock?)
        public var hideAnimation: (TimeInterval, AnimationBlock?, AnimationBlock?)
        public var duration: TimeInterval
        public var gravity: Gravity
        public var contentInsets: UIEdgeInsets
        public var isTapToDismiss: Bool
        public static let `default`: Self = .init(font:            .systemFont(ofSize: 16.0),
                                                  fontColor:       .white,
                                                  backgroundColor: UIColor.black.withAlphaComponent(0.66),
                                                  minimumSize:     .zero,
                                                  cornerRadius:    (16.0, [.allCorners]),
                                                  paddingToScreen: nil,
                                                  showAnimation:   (0.25, { $0.alpha = 0.0 }, { $0.alpha = 1.0 }),
                                                  hideAnimation:   (0.25, {_ in }, { $0.alpha = 0.0 }),
                                                  duration:        Duration.medium.rawValue,
                                                  gravity:         .bottom,
                                                  contentInsets:   .init(top: 8.0, left: 12.0, bottom: 8.0, right: 12.0),
                                                  isTapToDismiss:  true)
    }
    
    public static var context: Context = .topWindow
    public static var defaultStyle: ViewStyle = .default
    
    public private(set) var text: NSAttributedString
    public private(set) var duration: TimeInterval
    public private(set) var gravity: Gravity
    public private(set) var completeHandler: (()->Void)?
    
    private let uuid = UUID().uuidString
    private static var toastsQueue: [Toast] = []
    private let viewToastBox = UIView()
    private let labelMessage = UILabel()
    private var hideWorkItem: DispatchWorkItem?
    private var context: UIView?
    
    public init(text: NSAttributedString, duration: TimeInterval = Toast.defaultStyle.duration, gravity: Gravity = Toast.defaultStyle.gravity) {
        self.text     = text
        self.duration = duration
        self.gravity  = gravity
        
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(self.didChangedKeyboardState),
                         name:     UIResponder.keyboardWillShowNotification,
                         object:   nil)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(self.didChangedKeyboardState),
                         name:     UIResponder.keyboardWillHideNotification,
                         object:   nil)
    }
    
    deinit {
        NotificationCenter
            .default
            .removeObserver(self,
                            name:   UIResponder.keyboardWillShowNotification,
                            object: nil)
        NotificationCenter
            .default
            .removeObserver(self,
                            name:   UIResponder.keyboardWillHideNotification,
                            object: nil)
    }
}

//MARK: - makeAttributedString
extension Toast {
    private static func makeAttributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string:     String(format: "%@", text),
                                  attributes: [.font:            Toast.defaultStyle.font,
                                               .foregroundColor: Toast.defaultStyle.fontColor])
    }
}

//MARK: - show
extension Toast {
    public func show() {
        guard let targetWindow = self.context ?? self.getContext(Toast.context) else { return }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapToastMessage))
        
        self.labelMessage.numberOfLines            = 0
        self.labelMessage.textAlignment            = .center
        self.labelMessage.attributedText           = self.text
        self.labelMessage.isUserInteractionEnabled = false
        
        self.viewToastBox.backgroundColor          = Toast.defaultStyle.backgroundColor
        self.viewToastBox.isUserInteractionEnabled = true
        
        self.viewToastBox.addGestureRecognizer(tapGestureRecognizer)
        
        if !Toast.toastsQueue.contains(where: { $0.uuid == self.uuid }) {
            Toast.toastsQueue.append(self)
        }
        
        if let firstToast = Toast.toastsQueue.first, firstToast.uuid == self.uuid {
            self.addToastView(target: targetWindow)
            
            Toast.defaultStyle.showAnimation.1?(self.viewToastBox)
            UIView.animate(withDuration: Toast.defaultStyle.showAnimation.0,
                           animations:   { Toast.defaultStyle.showAnimation.2?(self.viewToastBox) },
                           completion:   nil)
            
            self.hideWorkItem = DispatchWorkItem(block: {[weak self] in
                guard let self = self else { return }
                self.hideAnimate()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + self.duration, execute: self.hideWorkItem!)
        }
    }
    
    private func addToastView(target targetWindow: UIView) {
        self.viewToastBox.removeFromSuperview()
        self.viewToastBox.addSubview(self.labelMessage)
        targetWindow.addSubview(self.viewToastBox)
        
        self.labelMessage.translatesAutoresizingMaskIntoConstraints = false
        if let padding = Toast.defaultStyle.paddingToScreen {
            self.viewToastBox
                .addConstraints([
                    .init(item:     self.labelMessage, attribute: .leading,  relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .leading,  multiplier: 1.0,
                          constant: self.getSafeAreaInsets().left - padding.left + Toast.defaultStyle.contentInsets.left),
                    .init(item:     self.labelMessage, attribute: .trailing, relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .trailing, multiplier: 1.0,
                          constant: -(self.getSafeAreaInsets().right - padding.right + Toast.defaultStyle.contentInsets.right))
                ])
            switch self.gravity {
            case .top:
                self.viewToastBox
                    .addConstraints([
                        .init(item:     self.labelMessage, attribute: .top,      relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .top,      multiplier: 1.0,
                              constant: self.getSafeAreaInsets().top - padding.top + Toast.defaultStyle.contentInsets.top),
                        .init(item:     self.labelMessage, attribute: .bottom,   relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .bottom,   multiplier: 1.0,
                              constant: -Toast.defaultStyle.contentInsets.bottom)
                    ])
            case .middle:
                self.viewToastBox
                    .addConstraints([
                        .init(item:     self.labelMessage, attribute: .top,      relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .top,      multiplier: 1.0,
                              constant: Toast.defaultStyle.contentInsets.top),
                        .init(item:     self.labelMessage, attribute: .bottom,   relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .bottom,   multiplier: 1.0,
                              constant: -Toast.defaultStyle.contentInsets.bottom)
                    ])
            case .bottom:
                self.viewToastBox
                    .addConstraints([
                        .init(item:     self.labelMessage, attribute: .top,      relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .top,      multiplier: 1.0,
                              constant: Toast.defaultStyle.contentInsets.top),
                        .init(item:     self.labelMessage, attribute: .bottom,   relatedBy: .equal,
                              toItem:   self.viewToastBox, attribute: .bottom,   multiplier: 1.0,
                              constant: -(self.getSafeAreaInsets().bottom - padding.bottom + Toast.defaultStyle.contentInsets.bottom))
                    ])
            }
        } else {
            self.viewToastBox
                .addConstraints([
                    .init(item:     self.labelMessage, attribute: .top,      relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .top,      multiplier: 1.0,
                          constant: Toast.defaultStyle.contentInsets.top),
                    .init(item:     self.labelMessage, attribute: .leading,  relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .leading,  multiplier: 1.0,
                          constant: Toast.defaultStyle.contentInsets.left),
                    .init(item:     self.labelMessage, attribute: .trailing, relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .trailing, multiplier: 1.0,
                          constant: -Toast.defaultStyle.contentInsets.right),
                    .init(item:     self.labelMessage, attribute: .bottom,   relatedBy: .equal,
                          toItem:   self.viewToastBox, attribute: .bottom,   multiplier: 1.0,
                          constant: -Toast.defaultStyle.contentInsets.bottom)
                ])
        }
        
        self.viewToastBox.translatesAutoresizingMaskIntoConstraints = false
        if let padding = Toast.defaultStyle.paddingToScreen {
            targetWindow
                .addConstraints([
                    .init(item:     self.viewToastBox, attribute: .leading,  relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .leading,  multiplier: 1.0,
                          constant: padding.left),
                    .init(item:     self.viewToastBox, attribute: .trailing, relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .trailing, multiplier: 1.0,
                          constant: -padding.right)
                ])
            switch self.gravity {
            case .top:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .top,  relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .top,  multiplier: 1.0,
                              constant: padding.top)
                    ])
            case .middle:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .centerY,  relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .centerY,  multiplier: 1.0,
                              constant: 0.0)
                    ])
            case .bottom:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .bottom,  relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .bottom,  multiplier: 1.0,
                              constant: -padding.bottom)
                    ])
            }
        } else {
            targetWindow
                .addConstraints([
                    .init(item:     self.viewToastBox, attribute: .centerX,  relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .centerX,  multiplier: 1.0,
                          constant: 0.0),
                    .init(item:     self.viewToastBox, attribute: .leading,  relatedBy: .greaterThanOrEqual,
                          toItem:   targetWindow,      attribute: .leading,  multiplier: 1.0,
                          constant: 12.0),
                    .init(item:     self.viewToastBox, attribute: .trailing, relatedBy: .lessThanOrEqual,
                          toItem:   targetWindow,      attribute: .trailing, multiplier: 1.0,
                          constant: -12.0)
                    ])
            switch self.gravity {
            case .top:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .top,    relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .top,    multiplier: 1.0,
                              constant: self.getSafeAreaInsets().top + 12.0),
                        .init(item:     self.viewToastBox, attribute: .bottom, relatedBy: .lessThanOrEqual,
                              toItem:   targetWindow,      attribute: .bottom, multiplier: 1.0,
                              constant: -(self.getSafeAreaInsets().bottom + 12.0))
                        ])
            case .middle:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .centerY, relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .centerY, multiplier: 1.0,
                              constant: 0.0),
                        .init(item:     self.viewToastBox, attribute: .top,     relatedBy: .greaterThanOrEqual,
                              toItem:   targetWindow,      attribute: .top,     multiplier: 1.0,
                              constant: self.getSafeAreaInsets().top + 12.0),
                        .init(item:     self.viewToastBox, attribute: .bottom,  relatedBy: .lessThanOrEqual,
                              toItem:   targetWindow,      attribute: .bottom,  multiplier: 1.0,
                              constant: -(self.getSafeAreaInsets().bottom + 12.0))
                        ])
            case .bottom:
                targetWindow
                    .addConstraints([
                        .init(item:     self.viewToastBox, attribute: .top,    relatedBy: .greaterThanOrEqual,
                              toItem:   targetWindow,      attribute: .top,    multiplier: 1.0,
                              constant: self.getSafeAreaInsets().top + 12.0),
                        .init(item:     self.viewToastBox, attribute: .bottom, relatedBy: .equal,
                              toItem:   targetWindow,      attribute: .bottom, multiplier: 1.0,
                              constant: -(self.getSafeAreaInsets().bottom + 12.0))
                        ])
            }
        }
        
        self.viewToastBox
            .addConstraints([
                .init(item: self.viewToastBox, attribute: .width,  relatedBy: .greaterThanOrEqual,
                      toItem: nil,             attribute: .width,  multiplier: 1.0,
                      constant: Toast.defaultStyle.minimumSize.width),
                .init(item: self.viewToastBox, attribute: .height, relatedBy: .greaterThanOrEqual,
                      toItem: nil,             attribute: .height, multiplier: 1.0,
                      constant: Toast.defaultStyle.minimumSize.height)
            ])
        
        self.labelMessage.layoutIfNeeded()
        self.viewToastBox.layoutIfNeeded()
        targetWindow.layoutIfNeeded()
        targetWindow.superview?.bringSubviewToFront(targetWindow)
        targetWindow.bringSubviewToFront(self.viewToastBox)
        
        self.applyRound()
    }
    
    private func applyRound() {
        let path        = UIBezierPath(roundedRect:       self.viewToastBox.bounds,
                                       byRoundingCorners: Toast.defaultStyle.cornerRadius.1,
                                       cornerRadii:       CGSize(width:  Toast.defaultStyle.cornerRadius.0,
                                                                 height: Toast.defaultStyle.cornerRadius.0))
        let maskLayer   = CAShapeLayer()
        maskLayer.path  = path.cgPath
        self.viewToastBox.layer.mask = maskLayer
    }
}

//MARK: - dismiss
extension Toast {
    public static func dismiss() {
        guard let toast = Toast.toastsQueue.first else { return }
        
        toast.hideWorkItem?.cancel()
        Toast.defaultStyle.hideAnimation.1?(toast.viewToastBox)
        UIView.animate(withDuration: Toast.defaultStyle.hideAnimation.0,
                       animations: { Toast.defaultStyle.hideAnimation.2?(toast.viewToastBox) },
                       completion: {_ in
            toast.viewToastBox.removeFromSuperview()
            if Toast.toastsQueue.count > 0 {
                Toast.toastsQueue.remove(at: 0)
                Toast.toastsQueue.first?.show()
            }
        })
    }
    
    public static func dismissAll() {
        guard let toast = Toast.toastsQueue.first else { return }
        
        toast.hideWorkItem?.cancel()
        Toast.toastsQueue = []
        Toast.defaultStyle.hideAnimation.1?(toast.viewToastBox)
        UIView.animate(withDuration: Toast.defaultStyle.hideAnimation.0,
                       animations: { Toast.defaultStyle.hideAnimation.2?(toast.viewToastBox) },
                       completion: {_ in
            toast.viewToastBox.removeFromSuperview()
        })
    }
}

//MARK: - GestureRecognizer
extension Toast {
    @objc private func didTapToastMessage(_ gesture: UITapGestureRecognizer) {
        guard Toast.defaultStyle.isTapToDismiss else { return }
        self.hideWorkItem?.cancel()
        self.hideAnimate()
    }
    
    private func hideAnimate() {
        Toast.defaultStyle.hideAnimation.1?(self.viewToastBox)
        UIView.animate(withDuration: Toast.defaultStyle.hideAnimation.0,
                       animations: { Toast.defaultStyle.hideAnimation.2?(self.viewToastBox) },
                       completion: {_ in
            self.viewToastBox.removeFromSuperview()
            if Toast.toastsQueue.count > 0 {
                Toast.toastsQueue.remove(at: 0)
                Toast.toastsQueue.first?.show()
            }
            self.completeHandler?()
        })
    }
}

//MARK: - initializers
extension Toast {
    public convenience init(text: NSAttributedString, duration: Duration, gravity: Gravity) {
        self.init(text: text, duration: duration.rawValue, gravity: Toast.defaultStyle.gravity)
    }
    
    public convenience init(text: String, duration: TimeInterval, gravity: Gravity) {
        let attributedString = Toast.makeAttributedString(text: text)
        self.init(text: attributedString, duration: duration, gravity: gravity)
    }
    public convenience init(text: String, duration: Duration, gravity: Gravity) {
        self.init(text: text, duration: duration.rawValue, gravity: gravity)
    }
    
    public convenience init(text: String) {
        self.init(text: text, duration: Toast.defaultStyle.duration, gravity: Toast.defaultStyle.gravity)
    }
}

//MARK: - makeText
extension Toast {
    @discardableResult
    public static func makeText(_ context: UIView, _ text: String) -> Toast {
        let attributedString = Toast.makeAttributedString(text: text)
        let instance = Toast(text: attributedString)
        instance.context = context
        return instance
    }
    @discardableResult
    public static func makeText(_ context: UIView, _ text: NSAttributedString) -> Toast {
        let instance = Toast(text: text)
        instance.context = context
        return instance
    }
    public static func makeText(_ context: Context, _ text: String) -> Toast {
        let attributedString = Toast.makeAttributedString(text: text)
        let instance = Toast(text: attributedString)
        instance.context = instance.getContext(context)
        return instance
    }
    @discardableResult
    public static func makeText(_ context: Context, _ text: NSAttributedString) -> Toast {
        let instance = Toast(text: text)
        instance.context = instance.getContext(context)
        return instance
    }
    
    @discardableResult
    public static func makeText(_ text: String) -> Toast {
        let attributedString = Toast.makeAttributedString(text: text)
        let instance = Toast(text: attributedString)
        instance.context = nil
        return instance
    }
    @discardableResult
    public static func makeText(_ text: NSAttributedString) -> Toast {
        let instance = Toast(text: text)
        instance.context = nil
        return instance
    }
}

//MARK: - setDuration
extension Toast {
    @discardableResult
    public func setDuration(_ duration: Duration) -> Toast {
        self.setDuration(duration.rawValue)
        return self
    }
    @discardableResult
    public func setDuration(_ duration: TimeInterval) -> Toast {
        self.duration = duration
        return self
    }
}

//MARK: - setGravity
extension Toast {
    @discardableResult
    public func setGravity(_ gravity: Gravity) -> Toast {
        self.gravity = gravity
        return self
    }
}

//MARK: - setCompleteHandler
extension Toast {
    @discardableResult
    public func setCompleteHandler(_ closure: (()->Void)?) -> Toast {
        self.completeHandler = closure
        return self
    }
}

//MARK: - functions
extension Toast {
    private func getSafeAreaInsets() -> UIEdgeInsets {
        guard #available(iOS 11.0, *),
              let window = UIApplication.shared.keyWindow
        else { return .zero }
        return window.safeAreaInsets
    }
    
    private func getContext(_ context: Context) -> UIView? {
        switch context {
        case .topWindow:
            return UIApplication.shared.windows
                .filter({ !$0.isHidden })
                .filter({ $0.alpha > 0.0 })
                .last
        case .keyWindow:
            return UIApplication.shared.keyWindow
        }
    }
    
    @objc
    private func didChangedKeyboardState(_ notification: NSNotification) {
        guard let targetWindow = self.getContext(Toast.context) else { return }
        self.addToastView(target: targetWindow)
    }
}
