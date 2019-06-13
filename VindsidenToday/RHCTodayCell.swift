//
//  RHCTodayCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.07.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit

extension UITableViewCell {

    func configureSelectedBackgroundView() -> Void {
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect.widgetEffect(forVibrancyStyle: .fill))
        vibrancyView.frame = self.contentView.bounds

        let view = UIView(frame: vibrancyView.bounds)
//        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        vibrancyView.contentView.addSubview(view)
        self.selectedBackgroundView = vibrancyView
    }
}

class RHCTodayCell: UITableViewCell {
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!


    func clearCell() {
        self.arrowImageView.image = nil
        self.speedLabel.text = " "
        self.nameLabel.text = " "
        self.updatedLabel.text = " "
        self.unitLabel.text = " "

        self.speedLabel.textColor = .label
        self.nameLabel.textColor = .label
        self.updatedLabel.textColor = .secondaryLabel
        self.unitLabel.textColor = .secondaryLabel
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        clearCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clearCell()
    }
}
