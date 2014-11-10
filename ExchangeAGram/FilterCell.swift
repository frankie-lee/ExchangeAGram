//
//  FilterCell.swift
//  ExchangeAGram
//
//  Created by Frank Lee on 2014-11-04.
//  Copyright (c) 2014 franklee. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {
    var imageView: UIImageView!
    
    //we're overriding custom initializer for filtercell
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        contentView.addSubview(imageView)
    }

    //NSCoding compliant
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
