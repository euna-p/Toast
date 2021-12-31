//
//  ViewController.swift
//  ToastTest
//
//  Created by Lonelie on 12/04/2019.
//  Copyright © 2019 Lonelie. All rights reserved.
//

import UIKit

import Toast

class ViewController: UIViewController {
    @IBOutlet private weak var textfieldForKeyboard: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textfieldForKeyboard?.becomeFirstResponder()
    }
    
    @IBAction private func didTappedSimpleToast(_ sender: UIButton) {
        Toast(text: "It's a SIMPLE Toast message.").show()
    }
    
    @IBAction private func didTappedAttributedToast(_ sender: UIButton) {
        let attributedString = NSMutableAttributedString(string: "It's an Attributed Toast message.\n",
                                                         attributes: [.font: UIFont.systemFont(ofSize: 16.0),
                                                                      .foregroundColor: UIColor.white])
        attributedString.append(NSAttributedString(string: "RED ",
                                                   attributes: [.font: UIFont.systemFont(ofSize: 16.0),
                                                                .foregroundColor: UIColor.red]))
        attributedString.append(NSAttributedString(string: "GREEN ",
                                                   attributes: [.font: UIFont.systemFont(ofSize: 16.0),
                                                                .foregroundColor: UIColor.green]))
        attributedString.append(NSAttributedString(string: "BLUE ",
                                                   attributes: [.font: UIFont.systemFont(ofSize: 16.0),
                                                                .foregroundColor: UIColor.blue]))
        Toast(text: attributedString).show()
    }
    
    @IBAction private func didTappedTopToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Top Toast message.")
            .setGravity(.top)
            .show()
    }
    
    @IBAction private func didTappedMiddleToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Middle Toast message.")
            .setGravity(.middle)
            .show()
    }
    
    @IBAction private func didTappedBottomToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Bottom Toast message.")
            .setGravity(.bottom)
            .show()
    }
    
    @IBAction private func didTappedShortToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Short (1s) Toast message.")
            .setDuration(.short)
            .show()
    }
    
    @IBAction private func didTappedMediumToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Medium (3s) Toast message.")
            .setDuration(.medium)
            .show()
    }
    
    @IBAction private func didTappedLongToast(_ sender: UIButton) {
        Toast
            .makeText("It's a Long (5s) Toast message.")
            .setDuration(.long)
            .show()
    }
    
    @IBAction private func didTappedDefaultSizeToast(_ sender: UIButton) {
        Toast.defaultStyle.font = .systemFont(ofSize: 16.0)
        Toast
            .makeText("It's Default size Toast message.")
            .show()
    }
    
    @IBAction private func didTappedBigSizeToast(_ sender: UIButton) {
        Toast.defaultStyle.font = .systemFont(ofSize: 24.0)
        Toast
            .makeText("It's BIG SIZE Toast message.")
            .show()
    }
    
    @IBAction private func didTappedCompleteHandledToast(_ sender: UIButton) {
        Toast
            .makeText("It's will show alert in after dismiss to this toast.")
            .setCompleteHandler({[weak self] in
                let alert = UIAlertController(title: "TOAST", message: "COMPLETED!", preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .show()
    }
    
    @IBAction private func didTappedDefaultStyleToast(_ sender: UIButton) {
        Toast.defaultStyle = .default
    }
    
    @IBAction private func didTappedCustomStyleToast(_ sender: UIButton) {
        Toast.defaultStyle.font            = .systemFont(ofSize: 24.0)
        Toast.defaultStyle.fontColor       = .white
        Toast.defaultStyle.backgroundColor = .purple
        Toast.defaultStyle.minHeight       = 48.0
        Toast.defaultStyle.cornerRadius    = (16.0, [.allCorners])
        Toast.defaultStyle.paddingToScreen = .zero
        Toast.defaultStyle.contentInsets   = .init(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        Toast.defaultStyle.showAniation    = (0.5,
                                              { $0.frame.origin.y += $0.bounds.size.height },
                                              { $0.frame.origin.y -= $0.bounds.size.height })
        Toast.defaultStyle.hideAnimation   = (0.5,
                                              nil,
                                              { $0.frame.origin.y += $0.bounds.size.height })
        Toast.defaultStyle.isTapToDismiss  = false
    }
}

