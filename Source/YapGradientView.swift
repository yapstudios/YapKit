//
//  YapGradientView.swift
//
//  Created by Trevor Stout on 4/1/16.
//  Copyright © 2016 Yap Studios LLC. All rights reserved.
//

import Foundation

public enum YapGradientViewType {
	case linear
	case easeOut
}

public enum YapGradientViewDirection {
	case topToBottom
	case bottomToTop
	case leftToRight
	case rightToLeft
}

public class YapGradientView: UIView {
	
	fileprivate let gradient = CAGradientLayer()
	public var fromColor = UIColor.black
	public var toColor = UIColor.clear
	public var gradientType = YapGradientViewType.easeOut
	
	public var direction: YapGradientViewDirection = .topToBottom {
		didSet {
			CATransaction.begin()
			CATransaction.setDisableActions(true)
			switch direction {
			case .topToBottom, .bottomToTop:
				gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
				gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
			case .leftToRight, .rightToLeft:
				gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
				gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
			}
			switch direction {
			case .leftToRight, .topToBottom:
				if gradientType == .linear {
					gradient.colors = [
						fromColor.cgColor,
						toColor.cgColor,
					]
				} else {
					gradient.colors = [
						fromColor.withAlphaComponent(1.00).cgColor,
						fromColor.withAlphaComponent(0.55).cgColor,
						fromColor.withAlphaComponent(0.17).cgColor,
						fromColor.withAlphaComponent(0.02).cgColor,
						fromColor.withAlphaComponent(0.00).cgColor
					]
				}
			case .rightToLeft, .bottomToTop:
				if gradientType == .linear {
					gradient.colors = [
						toColor.cgColor,
						fromColor.cgColor,
					]
				} else {
					gradient.colors = [
						fromColor.withAlphaComponent(0.00).cgColor,
						fromColor.withAlphaComponent(0.02).cgColor,
						fromColor.withAlphaComponent(0.17).cgColor,
						fromColor.withAlphaComponent(0.55).cgColor,
						fromColor.withAlphaComponent(1.00).cgColor
					]
				}
			}
			CATransaction.commit()
			setNeedsDisplay()
		}
	}
	
	override public init(frame: CGRect) {
		
		super.init(frame: frame)
		sharedInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		
		super.init(coder: aDecoder)
		sharedInit()
	}
	
	func sharedInit() {
		
		isUserInteractionEnabled = false
		layer.addSublayer(gradient)
		direction = .topToBottom
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		gradient.bounds = layer.bounds
		gradient.anchorPoint = .zero
		gradient.position = .zero
		CATransaction.commit()
	}
}
