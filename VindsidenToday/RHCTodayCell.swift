//
//  RHCTodayCell.swift
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 10.07.14.
//  Copyright (c) 2014 RHC. All rights reserved.
//

import UIKit

class RHCTodayCell: UITableViewCell {

    @IBOutlet var arrowImageView: UIImageView?
    @IBOutlet var speedLabel: UILabel?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var updatedLabel: UILabel?



    func configureSelectedBackgroundView() -> Void
    {
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect.notificationCenterVibrancyEffect())
        vibrancyView.frame = self.contentView.bounds

        let view = UIView(frame: vibrancyView.bounds)
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        vibrancyView.contentView.addSubview(view)
        self.selectedBackgroundView = vibrancyView
    }
}
