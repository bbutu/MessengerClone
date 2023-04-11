//
//  ReusableButton.swift
//  MessengerClone
//
//  Created by Beka Buturishvili on 11.04.23.
//

import UIKit

class ReusableButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .link
        self.setTitleColor(.white, for: .normal)
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

}
