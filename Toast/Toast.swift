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
    
    public private(set) var text: NSAttributedString = .init()
    public private(set) var duration: TimeInterval   = Duration.medium.rawValue
    public private(set) var gravity: Gravity         = .bottom
    public private(set) var insets: UIEdgeInsets     = .init(top: 24.0, left: 12.0, bottom: 16.0, right: 12.0)
    public private(set) var completeHandler: (()->Void)?
    
    private let uuid = UUID().uuidString
    private static var toastsQueue: [Toast] = []
    private let labelMessage = UILabel()
    private let viewToastBox = UIView()
    private var hideWorkItem: DispatchWorkItem?
    
    public init(text: NSAttributedString, duration: TimeInterval, gravity: Gravity = .bottom) {
        self.text     = text
        self.duration = duration
        self.gravity  = gravity
    }
    
    private static func makeAttributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string: String(format: "%@", text),
                                  attributes: [.font: UIFont.systemFont(ofSize: 14.0),
                                               .foregroundColor: UIColor.white])
    }
        
    public func show() {
        guard let targetWindow = UIApplication.shared.windows.filter({ $0.bounds == UIScreen.main.bounds }).last else { return }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapToastMessage))
        
        self.labelMessage.numberOfLines            = 0
        self.labelMessage.textAlignment            = .center
        self.labelMessage.attributedText           = self.text
        self.labelMessage.isUserInteractionEnabled = false
        
        self.viewToastBox.backgroundColor          = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.66)
        self.viewToastBox.layer.cornerRadius       = 6.0
        self.viewToastBox.layer.masksToBounds      = true
        self.viewToastBox.layer.borderColor        = UIColor.clear.cgColor
        self.viewToastBox.layer.borderWidth        = 0.0
        self.viewToastBox.isUserInteractionEnabled = true
        
        self.viewToastBox.addGestureRecognizer(tapGestureRecognizer)
        
        if !Toast.toastsQueue.contains(where: { $0.uuid == self.uuid }) {
            Toast.toastsQueue.append(self)
        }
        
        if let firstToast = Toast.toastsQueue.first, firstToast.uuid == self.uuid {
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
                    .init(item:   self.viewToastBox, attribute: .centerX,  relatedBy: .equal,
                          toItem: targetWindow,      attribute: .centerX,  multiplier: 1.0,                constant:  0.0),
                    .init(item:   self.viewToastBox, attribute: .leading,  relatedBy: .greaterThanOrEqual,
                          toItem: targetWindow,      attribute: .leading,  multiplier: 1.0,                constant:  self.insets.left),
                    .init(item:   self.viewToastBox, attribute: .trailing, relatedBy: .lessThanOrEqual,
                          toItem: targetWindow,      attribute: .trailing, multiplier: 1.0,                constant: -self.insets.right)
                    ])
            
            switch self.gravity {
            case .top:
                targetWindow
                    .addConstraints([
                        .init(item:   self.viewToastBox, attribute: .top,    relatedBy: .equal,
                              toItem: targetWindow,      attribute: .top,    multiplier: 1.0,                constant:  self.getSafeAreaInsets().top + self.insets.top),
                        .init(item:   self.viewToastBox, attribute: .bottom, relatedBy: .lessThanOrEqual,
                              toItem: targetWindow,      attribute: .bottom, multiplier: 1.0,                constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                        ])
            case .middle:
                targetWindow
                    .addConstraints([
                        .init(item:   self.viewToastBox, attribute: .centerY, relatedBy: .equal,
                              toItem: targetWindow,      attribute: .centerY, multiplier: 1.0,                constant:  0.0),
                        .init(item:   self.viewToastBox, attribute: .top,     relatedBy: .greaterThanOrEqual,
                              toItem: targetWindow,      attribute: .top,     multiplier: 1.0,                constant:  self.getSafeAreaInsets().top + self.insets.top),
                        .init(item:   self.viewToastBox, attribute: .bottom,  relatedBy: .lessThanOrEqual,
                              toItem: targetWindow,      attribute: .bottom,  multiplier: 1.0,                constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                        ])
            case .bottom:
                targetWindow
                    .addConstraints([
                        .init(item:   self.viewToastBox, attribute: .top,    relatedBy: .greaterThanOrEqual,
                              toItem: targetWindow,      attribute: .top,    multiplier: 1.0,                constant:  self.getSafeAreaInsets().top + self.insets.top),
                        .init(item:   self.viewToastBox, attribute: .bottom, relatedBy: .equal,
                              toItem: targetWindow,      attribute: .bottom, multiplier: 1.0,                constant: -(self.getSafeAreaInsets().bottom + self.insets.bottom))
                        ])
            }
            
            self.viewToastBox.layoutIfNeeded()
            targetWindow.superview?.bringSubviewToFront(targetWindow)
            self.viewToastBox.superview?.bringSubviewToFront(self.viewToastBox)
            
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
            Toast.toastsQueue.remove(at: 0)
            self.viewToastBox.removeFromSuperview()
            if Toast.toastsQueue.count > 0 {
                Toast.toastsQueue.first?.show()
            }
            self.completeHandler?()
        })
    }
}

extension Toast {
    public convenience init(text: String, duration: Duration = .medium, gravity: Gravity = .bottom) {
        self.init(text: text, duration: duration.rawValue)
    }
    
    public convenience init(text: String, duration: TimeInterval, gravity: Gravity = .bottom) {
        let attributedString = Toast.makeAttributedString(text: text)
        self.init(text: attributedString, duration: duration, gravity: gravity)
    }
    
    public convenience init(text: NSAttributedString, duration: Duration = .medium, gravity: Gravity = .bottom) {
        self.init(text: text, duration: duration.rawValue)
    }
}

extension Toast {
    @discardableResult
    public static func makeText(_ text: String) -> Toast {
        let attributedString = Toast.makeAttributedString(text: text)
        return self.makeText(attributedString)
    }
    @discardableResult
    public static func makeText(_ text: NSAttributedString) -> Toast {
        return Toast(text: text)
    }
    
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
    
    @discardableResult
    public func setGravity(_ gravity: Gravity) -> Toast {
        self.gravity = gravity
        return self
    }
    
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
    
    @discardableResult
    public func setCompleteHandler(_ closure: (()->Void)?) -> Toast {
        self.completeHandler = closure
        return self
    }
}

extension Toast {
    private func getSafeAreaInsets() -> UIEdgeInsets {
        guard #available(iOS 11.0, *), let window = UIApplication.shared.keyWindow else { return .zero }
        return window.safeAreaInsets
    }
}
