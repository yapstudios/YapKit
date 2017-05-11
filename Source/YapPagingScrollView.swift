//
//  YapPagingScrollView.swift
//
//  Created by Trevor Stout on 4/14/16.
//  Copyright (c) 2016 Yap Studios LLC. All rights reserved.
//

import Foundation

// A wrapper class to enable paging in a collection view at a multiple of item size, rather than page size
// To use, set the YapPagingScrollView bounds to the itemsize plus any minimum line spacing. 
// Set the contentView to your collection view. If there is a left content inset, apply a negative x offset to the content view frame (the collection view)
// The contentView (collection view) bounds should be the full width of the parent view.
public class YapPagingScrollView: UIScrollView {
	
	public var contentView: UIScrollView? {
		willSet(newContentView) {
			if let contentView = self.contentView {
				contentView.removeFromSuperview()
			}
		}
		didSet {
			if let contentView = self.contentView {
				self.addSubview(contentView)
				contentView.isScrollEnabled = false
			}
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
    #if os(iOS)
      // paging not enabled on tvOS target
      isPagingEnabled = true
    #endif
		showsHorizontalScrollIndicator = false
		clipsToBounds = false
		alwaysBounceHorizontal = true
	}

	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		if let contentView = self.contentView {
			if contentView.point(inside: point, with: event) {
				return true
			}
		}
		return super.point(inside: point, with: event)
	}
	
	override public func layoutSubviews() {
		super.layoutSubviews()
		
		guard let contentView = self.contentView else { return }
		
		var frame = contentView.frame
		frame.origin.x = contentOffset.x - contentView.contentInset.left
		contentView.frame = frame
		contentView.setContentOffset(CGPoint(x: contentOffset.x - contentView.contentInset.left, y: 0), animated: false)
		
		// update the content size to an exact page multiple
		var contentWidth = contentView.contentSize.width + contentView.contentInset.right
		let pages = floor(contentWidth / bounds.width)
		contentWidth = pages * self.bounds.width
		contentSize = CGSize(width: contentWidth, height: contentView.contentSize.height)
	}
}

