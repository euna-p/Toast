//
//  ViewController.swift
//  ToastTest
//
//  Created by LeemJH on 12/04/2019.
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
                                                         attributes: [.font: UIFont.systemFont(ofSize: 14.0),
                                                                      .foregroundColor: UIColor.white])
        attributedString.append(NSAttributedString(string: "RED ",   attributes: [.font: UIFont.systemFont(ofSize: 14.0),
                                                                                  .foregroundColor: UIColor.red]))
        attributedString.append(NSAttributedString(string: "GREEN ", attributes: [.font: UIFont.systemFont(ofSize: 14.0),
                                                                                  .foregroundColor: UIColor.green]))
        attributedString.append(NSAttributedString(string: "BLUE ",  attributes: [.font: UIFont.systemFont(ofSize: 14.0),
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
}

