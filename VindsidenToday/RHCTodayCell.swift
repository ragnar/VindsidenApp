//
//  RHCTodayCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.07.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit

extension UITableViewCell {

    func configureSelectedBackgroundView() -> Void
    {
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect.notificationCenterVibrancyEffect())
        vibrancyView.frame = self.contentView.bounds

        let view = UIView(frame: vibrancyView.bounds)
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        vibrancyView.contentView.addSubview(view)
        self.selectedBackgroundView = vibrancyView
    }
}

class RHCTodayCell: UITableViewCell
{
    @IBOutlet weak var arrowImageView: UIImageView?
    @IBOutlet weak var speedLabel: UILabel?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var updatedLabel: UILabel?

}
