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
    
    public static var defaultContext: Context       = .topWindow
    public static var defaultDuration: TimeInterval = Duration.medium.rawValue
    public static var defaultGravity: Gravity       = .bottom
    public static var defaultInsets: UIEdgeInsets   = .init(top: 24.0, left: 12.0, bottom: 16.0, right: 12.0)
    public static var defaultRectRound: CGFloat     = 6.0
    public static var defaultTextFont: UIFont       = .systemFont(ofSize: 14.0)
    public static var defaultTextColor: UIColor     = .white
    
    public private(set) var text: NSAttributedString = .init()
    public private(set) var duration: TimeInterval   = Toast.defaultDuration
    public private(set) var gravity: Gravity         = Toast.defaultGravity
    public private(set) var insets: UIEdgeInsets     = Toast.defaultInsets
    public private(set) var completeHandler: (()->Void)?
    
    private let uuid = UUID().uuidString
    private static var toastsQueue: [Toast] = []
    private let labelMessage = UILabel()
    private let viewToastBox = UIView()
    private var hideWorkItem: DispatchWorkItem?
    private var context: UIView?
    
    public init(text: NSAttributedString, duration: TimeInterval = Toast.defaultDuration, gravity: Gravity = Toast.defaultGravity) {
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
                                  attributes: [.font:            Toast.defaultTextFont,
                                               .foregroundColor: Toast.defaultTextColor])
    }
}

//MARK: - show
extension Toast {
    public func show() {
        guard let targetWindow = self.context ?? self.getContext(Toast.defaultContext) else { return }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapToastMessage))
        
        self.labelMessage.numberOfLines            = 0
        self.labelMessage.textAlignment            = .center
        self.labelMessage.attributedText           = self.text
        self.labelMessage.isUserInteractionEnabled = false
        
        self.viewToastBox.backgroundColor          = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.66)
        self.viewToastBox.layer.cornerRadius       = Toast.defaultRectRound
        self.viewToastBox.layer.masksToBounds      = true
        self.viewToastBox.layer.borderColor        = UIColor.clear.cgColor
        self.viewToastBox.layer.borderWidth        = 0.0
        self.viewToastBox.isUserInteractionEnabled = true
        
        self.viewToastBox.addGestureRecognizer(tapGestureRecognizer)
        
        if !Toast.toastsQueue.contains(where: { $0.uuid == self.uuid }) {
            Toast.toastsQueue.append(self)
        }
        
        if let firstToast = Toast.toastsQueue.first, firstToast.uuid == self.uuid {
            self.addToastView(target: targetWindow)
            
            self.viewToastBox.alpha     = 0.0
            self.viewToastBox.transform = CGAffineTransform(scaleX: 1.125, y: 1.125)
            UIView.animate(withDuration: 0.25, animations: {
                self.viewToastBox.alpha     = 1.0
                self.viewToastBox.transform = .identity
            }, completion: nil)
            
            self.hideWorkItem = DispatchWorkItem(block: {[weak self] in
                guard let self = self else { return }
                self.viewToastBox.alpha     = 1.0
                self.viewToastBox.transform = .identity
                self.hideAnimate(isDrown: false)
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + self.duration, execute: self.hideWorkItem!)
        }
    }
    
    private func addToastView(target targetWindow: UIView) {
        self.viewToastBox.removeFromSuperview()
        self.viewToastBox.addSubview(self.labelMessage)
        targetWindow.addSubview(self.viewToastBox)
        
        self.labelMessage.translatesAutoresizingMaskIntoConstraints = false
        self.viewToastBox
            .addConstraints([
                .init(item:   self.labelMessage, attribute: .top,      relatedBy: .equal,
                      toItem: self.viewToastBox, attribute: .top,      multiplier: 1.0,   constant:  4.0),
                .init(item:   self.labelMessage, attribute: .leading,  relatedBy: .equal,
                      toItem: self.viewToastBox, attribute: .leading,  multiplier: 1.0,   constant:  8.0),
                .init(item:   self.labelMessage, attribute: .trailing, relatedBy: .equal,
                      toItem: self.viewToastBox, attribute: .trailing, multiplier: 1.0,   constant: -8.0),
                .init(item:   self.labelMessage, attribute: .bottom,   relatedBy: .equal,
                      toItem: self.viewToastBox, attribute: .bottom,   multiplier: 1.0,   constant: -4.0)
                ])
        
        self.viewToastBox.translatesAutoresizingMaskIntoConstraints = false
        targetWindow
            .addConstraints([
                .init(item:     self.viewToastBox, attribute: .centerX,  relatedBy: .equal,
                      toItem:   targetWindow,      attribute: .centerX,  multiplier: 1.0,
                      constant: 0.0),
                .init(item:     self.viewToastBox, attribute: .leading,  relatedBy: .greaterThanOrEqual,
                      toItem:   targetWindow,      attribute: .leading,  multiplier: 1.0,
                      constant: self.insets.left),
                .init(item:     self.viewToastBox, attribute: .trailing, relatedBy: .lessThanOrEqual,
                      toItem:   targetWindow,      attribute: .trailing, multiplier: 1.0,
                      constant: -self.insets.right)
                ])
        
        switch self.gravity {
        case .top:
            targetWindow
                .addConstraints([
                    .init(item:     self.viewToastBox, attribute: .top,    relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .top,    multiplier: 1.0,
                          constant: self.getSafeAreaInsets().top + self.insets.top),
                    .init(item:     self.viewToastBox, attribute: .bottom, relatedBy: .lessThanOrEqual,
                          toItem:   targetWindow,      attribute: .bottom, multiplier: 1.0,
                          constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                    ])
        case .middle:
            targetWindow
                .addConstraints([
                    .init(item:     self.viewToastBox, attribute: .centerY, relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .centerY, multiplier: 1.0,
                          constant: 0.0),
                    .init(item:     self.viewToastBox, attribute: .top,     relatedBy: .greaterThanOrEqual,
                          toItem:   targetWindow,      attribute: .top,     multiplier: 1.0,
                          constant: self.getSafeAreaInsets().top + self.insets.top),
                    .init(item:     self.viewToastBox, attribute: .bottom,  relatedBy: .lessThanOrEqual,
                          toItem:   targetWindow,      attribute: .bottom,  multiplier: 1.0,
                          constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                    ])
        case .bottom:
            targetWindow
                .addConstraints([
                    .init(item:     self.viewToastBox, attribute: .top,    relatedBy: .greaterThanOrEqual,
                          toItem:   targetWindow,      attribute: .top,    multiplier: 1.0,
                          constant: self.getSafeAreaInsets().top + self.insets.top),
                    .init(item:     self.viewToastBox, attribute: .bottom, relatedBy: .equal,
                          toItem:   targetWindow,      attribute: .bottom, multiplier: 1.0,
                          constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                    ])
        }
        
        self.viewToastBox.layoutIfNeeded()
        targetWindow.superview?.bringSubviewToFront(targetWindow)
        self.viewToastBox.superview?.bringSubviewToFront(self.viewToastBox)
    }
}

//MARK: - dismiss
extension Toast {
    public static func dismiss() {
        guard let toast = Toast.toastsQueue.first else { return }
        
        toast.hideWorkItem?.cancel()
        UIView.animate(withDuration: 0.25, animations: {
            toast.viewToastBox.alpha = 0.0
        }, completion: {_ in
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
        UIView.animate(withDuration: 0.25, animations: {
            toast.viewToastBox.alpha = 0.0
        }, completion: {_ in
            toast.viewToastBox.removeFromSuperview()
        })
    }
}

//MARK: - GestureRecognizer
extension Toast {
    @objc private func didTapToastMessage(_ gesture: UITapGestureRecognizer) {
        self.hideWorkItem?.cancel()
        self.hideAnimate(isDrown: true)
    }
    
    private func hideAnimate(isDrown: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewToastBox.alpha = 0.0
            if isDrown {
                self.viewToastBox.transform       = CGAffineTransform(scaleX: 0.75, y: 0.75)
                self.viewToastBox.frame.origin.x -= 24.0
                self.viewToastBox.frame.origin.y += 160.0
                self.viewToastBox.transform       = CGAffineTransform(rotationAngle: .pi / -4.0)
                
            }
        }, completion: {_ in
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
        self.init(text: text, duration: duration.rawValue)
    }
    
    public convenience init(text: String, duration: TimeInterval, gravity: Gravity) {
        let attributedString = Toast.makeAttributedString(text: text)
        self.init(text: attributedString, duration: duration, gravity: gravity)
    }
    public convenience init(text: String, duration: Duration, gravity: Gravity) {
        self.init(text: text, duration: duration.rawValue, gravity: gravity)
    }
    
    public convenience init(text: String) {
        self.init(text:     text,
                  duration: Toast.defaultDuration,
                  gravity:  Toast.defaultGravity)
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

//MARK: - setInsets
extension Toast {
    @discardableResult
    public func setInsets(_ insets: UIEdgeInsets) -> Toast {
        self.insets = insets
        return self
    }
    
    @discardableResult
    public func setInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> Toast {
        self.insets = .init(top: top, left: left, bottom: bottom, right: right)
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
        guard let targetWindow = self.getContext(Toast.defaultContext) else { return }
        self.addToastView(target: targetWindow)
    }
}
