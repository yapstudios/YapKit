//
//  YapLabel.swift
//
//  Created by Trevor Stout on 5/4/16.
//  Copyright © 2016 Yap Studios. All rights reserved.
//

import Foundation

public enum YapLabelVerticalTextAlignment {
	case top
	case middle
	case bottom
}

/// A UILabel with vertical alignment support. Currently only works with attributedText.
public class YapLabel: UILabel {
	
	public var verticalTextAlignment = YapLabelVerticalTextAlignment.middle {
		didSet {
			setNeedsDisplay()
		}
	}
	
	override public func drawText(in rect: CGRect) {
		
		// only attributed text is supported
		guard verticalTextAlignment != .middle, let attributedText = self.attributedText else {
			super.drawText(in: rect)
			return
		}

		let size = attributedText.boundingRect(with: bounds.size, options: .usesLineFragmentOrigin, context: nil)

		switch verticalTextAlignment {
		case .top:
			attributedText.draw(with: CGRect(x: 0, y: 0, width: bounds.width, height: size.height).integral, options: .usesLineFragmentOrigin, context: nil)
		case .middle:
			// This is the default behavior, so not applicable
			break
		case .bottom:
			attributedText.draw(with: CGRect(x: 0, y: bounds.height - size.height, width: bounds.width, height: size.height).integral, options: .usesLineFragmentOrigin, context: nil)
		}
	}
}
