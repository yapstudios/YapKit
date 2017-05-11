//
//  YapNavigationBar.swift
//
//  Created by Trevor Stout on 10/01/13.
//  Copyright (c) 2016 Yap Studios LLC. All rights reserved.
//

import Foundation

let YapNavigationBarHeight = CGFloat(40.0)

/// A UINavigationBar with a custom height
public class YapNavigationBar: UINavigationBar {
	
	let verticalAdjustment = (44.0 - YapNavigationBarHeight) / 2.0
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		sharedInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		sharedInit()
	}
	
	func sharedInit() {
		self.setTitleVerticalPositionAdjustment(verticalAdjustment, for: .default)
	}
	
	// NOTE: this is a reported issue that this never gets called on the latest iOS; use custom bar items instead to center vertically
	override public func pushItem(_ item: UINavigationItem, animated: Bool) {
		item.backBarButtonItem?.setTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: verticalAdjustment), for: .default)
		item.backBarButtonItem?.setBackButtonBackgroundVerticalPositionAdjustment(verticalAdjustment, for: .default)
		item.rightBarButtonItem?.setBackButtonBackgroundVerticalPositionAdjustment(verticalAdjustment, for: .default)
		super.pushItem(item, animated: animated)
	}
	
	override public func sizeThatFits(_ size: CGSize) -> CGSize {

		var size = super.sizeThatFits(size)
		size.height = YapNavigationBarHeight
		return size
	}
	
	func verticalAlignView(_ view: UIView) {
		var position = view.layer.position
		position.y = self.layer.position.y
		view.layer.position = position
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		
		if let titleView = self.topItem?.titleView {
			verticalAlignView(titleView)
		}
		if let leftCustomView = self.topItem?.leftBarButtonItem?.customView {
			verticalAlignView(leftCustomView)
		}
		if let rightCustomView = self.topItem?.rightBarButtonItem?.customView {
			verticalAlignView(rightCustomView)
		}
	}
}
