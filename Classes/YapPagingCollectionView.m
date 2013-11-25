//
//  YapPagingCollectionView.m
//  yap-iphone
//
//  Created by Trevor Stout on 4/16/13.
//  Copyright (c) 2013 Yap.tv, Inc. All rights reserved.
//

#import "YapPagingCollectionView.h"
#import "UIView+YapBouncyAnimations.h"

#define SLOW_MO 0.5

@implementation YapPagingCollectionView {
	UICollectionView *_cv;
	UICollectionViewFlowLayout *_flowLayout;
	
	NSInteger _numberOfItems;

	CGFloat _beginOffsetX;
	CGFloat _beginPagingOffsetX; // start of paging gesture rec
	BOOL _isPaging;

	NSMutableSet *_hiddenImages;
	
	UIPanGestureRecognizer *_customGestureRecognizer;
	UITapGestureRecognizer *_customTapRecognizer;
	
	BOOL _isAnimating;
}

- (UICollectionView *)collectionView
{
	return _cv;
}

- (void)setImageHidden:(BOOL)hidden atIndex:(NSInteger)index;
{
	if (hidden) {
		[_hiddenImages addObject:[NSNumber numberWithInteger:index]];
	} else {
		[_hiddenImages removeObject:[NSNumber numberWithInteger:index]];
	}
	
	// update visible state
	[_cv.visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		UICollectionViewCell * cell = obj;
		NSIndexPath *indexPath = [_cv indexPathForCell:cell];
		if ([_hiddenImages containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
			cell.contentView.alpha = 0.0;
		} else {
			cell.contentView.alpha = 1.0;
		}
	}];
}

- (BOOL)isImageHiddenAtIndex:(NSInteger)index {
    return [_hiddenImages containsObject:[NSNumber numberWithInteger:index]];
}

- (NSIndexPath *)indexPathForCell:(UICollectionViewCell *)cell
{
    return [_cv indexPathForCell:cell];
}

- (NSArray *)visibleCells
{
    return [_cv visibleCells];
}

- (void)setAllImagesVisible
{
	if (![_hiddenImages count]) return; // nothing to do
	
	[_hiddenImages removeAllObjects];
	[_cv.visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		UICollectionViewCell * cell = obj;
		cell.contentView.alpha = 1.0;
	}];
}

- (CGRect)rectForImageAtIndex:(NSUInteger)index inView:(UIView *)view
{
	if (index < _numberOfItems) {
		UICollectionViewLayoutAttributes *layoutAttributes = [_flowLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
		CGRect rect = [_cv convertRect:layoutAttributes.frame toView:view];
		return rect;
	}
	return CGRectZero;
}

- (void)setItemSize:(CGSize)itemSize
{
	_itemSize = itemSize;
	_flowLayout.itemSize = _itemSize;
	[_cv reloadData];
}

- (UIEdgeInsets)contentInset
{
	return _cv.contentInset;
}

- (CGPoint)contentOffset
{
	return _cv.contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
	_cv.contentOffset = contentOffset;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
	CGFloat duration = SLOW_MO;
	CGRect bounds = _cv.layer.bounds;
	bounds.origin.x = contentOffset.x;
	//bounds.origin.x = fmax(0.0, fmin(bounds.origin.x, _cv.contentSize.width - _cv.bounds.size.width));
	
	[_cv.layer removeAllAnimations];
	
	if (animated) {
		// bounce back
		[CATransaction begin];
		[CATransaction setAnimationDuration:duration];
		[CATransaction setCompletionBlock:^{
			_isAnimating = NO;
		}];
		
		CAKeyframeAnimation *animation = [_cv bouncyAnimationForKeyPath:@"bounds.origin.x"
															  fromValue:[_cv.layer valueForKeyPath:@"bounds.origin.x"]
																toValue:@(bounds.origin.x)
															   duration:duration];
		[_cv.layer addAnimation:animation forKey:@"bounds.origin.x"];
		
		
		[CATransaction commit];
		_cv.contentOffset = bounds.origin;
		_isAnimating = YES;
		
	} else {
		[_cv setContentOffset:bounds.origin animated:NO];
	}
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing
{
	_interitemSpacing = interitemSpacing;
	_flowLayout.minimumLineSpacing = interitemSpacing; // since this is horizontal, uses line spacing to separate items
	[_cv reloadData];
}

- (NSUInteger)maxPage
{
	return ceilf((_cv.contentSize.width - _interitemSpacing) / _pageWidth) - 1;
}

- (NSUInteger)pageForItemAtIndex:(NSUInteger)index
{
	NSUInteger itemsPerPage = _numberOfItems > 0 ? ceilf(_numberOfItems / (self.maxPage + 1.0)) : 0.0;
	NSUInteger pageForItem = floorf(index / itemsPerPage);
	return pageForItem;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
	_scrollEnabled = scrollEnabled;
	if (!_pagingEnabled) {
		_cv.scrollEnabled = scrollEnabled;
	}
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
	_pagingEnabled = pagingEnabled;
	if (_pagingEnabled) {
		if (!_customGestureRecognizer) {
			// enable custom paging
			_customGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
			[_customGestureRecognizer addTarget:self action:@selector(handleHorizontalPan:)];
			_customGestureRecognizer.delegate = self;
			_customGestureRecognizer.delaysTouchesBegan = YES;
			[_cv addGestureRecognizer:_customGestureRecognizer];
		}
		
		// bouncing and scrolling handled by custom gesture recognizer
		_cv.bounces = NO;
		_cv.alwaysBounceVertical = NO;
		_cv.alwaysBounceHorizontal = NO;
		_cv.scrollEnabled = NO;
	} else {
		[_cv removeGestureRecognizer:_customGestureRecognizer];
		_customGestureRecognizer = nil;
		
		// standard scroll view scrolling
		_cv.bounces = YES;
		_cv.alwaysBounceVertical = NO;
		_cv.alwaysBounceHorizontal = YES;
		_cv.scrollEnabled = _scrollEnabled;
	}
}

- (void)reloadData
{
	[_hiddenImages removeAllObjects];
	[_cv reloadData];
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
{
	[_cv registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath*)indexPath
{
    return [_cv dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
		// create flow layout
		_flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.sectionInset = (UIEdgeInsets) { .top = 0.0, .bottom = 0.0, .left = 0.0, .right = 0.0 };

        _flowLayout.minimumLineSpacing = 16.0;
        _flowLayout.itemSize = (CGSize) { .width = 192.0, .height = 64.0 };
    
		// create collection view
		CGRect rect = (CGRect) {
			.origin.x = -2 * frame.size.width,
			.size.width = 4 * frame.size.width,
			.size.height = frame.size.height
		};
        
		_cv = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:_flowLayout];
		_cv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		_cv.contentInset = (UIEdgeInsets) { .left = 2 * self.bounds.size.width, .right = self.bounds.size.width };
		_cv.delegate = self;
		_cv.dataSource = self;
		_cv.userInteractionEnabled = YES;
		
		self.pagingEnabled = NO; // default off
		_cv.allowsSelection = NO; // needed?
		_cv.backgroundColor = [UIColor clearColor]; //[UIColor colorWithWhite:0.92 alpha:1.0];
		self.backgroundColor = [UIColor clearColor];
		[self addSubview:_cv];

		// enable custom paging
		self.scrollEnabled = YES; // default
		
		_customTapRecognizer = [[UITapGestureRecognizer alloc] init];
		[_customTapRecognizer addTarget:self action:@selector(handleTap:)];
		_customTapRecognizer.delegate = self;
		[_cv addGestureRecognizer:_customTapRecognizer];

		_pageWidth = self.bounds.size.width; // default
		
		_hiddenImages = [NSMutableSet set];
		
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
	_numberOfItems = [_dataSource numberOfItemsInHorizontalImageCollection:self];
    return _numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
	UICollectionViewCell *cell = [_dataSource collectionView:self itemAtIndexPath:indexPath];
	return cell;
}

#pragma mark gesture recognizer

- (void)removeAllAnimations
{
	[_cv.layer removeAllAnimations];	
}

- (void)setPage:(NSUInteger)page animated:(BOOL)animated
{
	_page = page;
	
	CGFloat duration = SLOW_MO;
	CGRect bounds = _cv.layer.bounds;
	bounds.origin.x = page * _pageWidth - _cv.contentInset.left;
	//bounds.origin.x = fmax(0.0, fmin(bounds.origin.x, _cv.contentSize.width - _cv.bounds.size.width));

	[_cv.layer removeAllAnimations];

	if (animated) {
		// bounce back
		[CATransaction begin];
		[CATransaction setAnimationDuration:duration];
		[CATransaction setCompletionBlock:^{
			//[_cv setContentOffset:bounds.origin animated:NO];
			if ([_delegate respondsToSelector:@selector(horizontalImageCollectionView:didPageToPage:)])
				[_delegate horizontalImageCollectionView:self didPageToPage:page];
			_isPaging = NO;
			_isAnimating = NO;
		}];
		
		CAKeyframeAnimation *animation = [_cv bouncyAnimationForKeyPath:@"bounds.origin.x"
															  fromValue:[_cv.layer valueForKeyPath:@"bounds.origin.x"]
																toValue:@(bounds.origin.x)
															   duration:duration];
		[_cv.layer addAnimation:animation forKey:@"bounds.origin.x"];
		
		
		[CATransaction commit];
		_cv.contentOffset = bounds.origin;
		_isAnimating = YES;
		
	} else {
		[_cv setContentOffset:bounds.origin animated:NO];
		_isPaging = NO;
	}
	
}

- (void)handleHorizontalPan:(UIPanGestureRecognizer *)inPanRecognizer;
{
	CGFloat offsetX = 0.0;
	CGFloat pagingThreshold = _pageWidth / 2.0;
	CGFloat velocityThreshold = 100.0;
	
	NSUInteger maxPage = [self maxPage];
	
	// TODO: handle left/right edge
	
	if (inPanRecognizer.state == UIGestureRecognizerStateBegan) {
		
		_isPaging = NO; // hold until 10px threshold is hit
				
		_beginOffsetX = [inPanRecognizer locationInView:self].x;
		_page = (_cv.contentOffset.x + _cv.contentInset.left) / _pageWidth;
		_beginPagingOffsetX = _page * _pageWidth - _cv.contentInset.left;
		
	} else if (inPanRecognizer.state == UIGestureRecognizerStateChanged) {
		
		offsetX = [inPanRecognizer locationInView:self].x - _beginOffsetX;
		
		if (!_isPaging && (fabs(offsetX) > 5.0)) {
			if ([_delegate respondsToSelector:@selector(pagingCollectionViewPagingEnabled:)]) {
				_isPaging = [_delegate pagingCollectionViewPagingEnabled:self];
			} else {
				_isPaging = YES;
			}
			
			if (_isPaging) {
				[self removeAllAnimations];
				if ([_delegate respondsToSelector:@selector(pagingCollectionViewWillBeginPanning:)])
					[_delegate pagingCollectionViewWillBeginPanning:self];
				
			}
		}
		
		if (_isPaging) {
			CGFloat drag = 1.0;
			if ((_page == 0 && offsetX > 0.0) || (_page == maxPage && offsetX < 0.0)) {
				drag = 0.5;
			}
		
			//NSLog(@"offsetX:%f isPaging:%d page:%d drag:%f", offsetX, _isPaging, _page, drag);
			
			_cv.contentOffset = (CGPoint) { .x = _beginPagingOffsetX - drag * offsetX };
			
		}
		
	} else if (inPanRecognizer.state == UIGestureRecognizerStateEnded || inPanRecognizer.state == UIGestureRecognizerStateCancelled) {
		if (_isPaging) {
			NSUInteger newPage = _page;
			CGPoint velocity = [inPanRecognizer velocityInView:self];
			
			offsetX = [inPanRecognizer locationInView:self].x - _beginOffsetX;
			
			if ((newPage > 0) && (velocity.x > velocityThreshold)) {
				//NSLog(@"VELOCITY L: %f", velocity.x);
				newPage--;
			} else if ((newPage < maxPage) && (velocity.x < -velocityThreshold)) {
				//NSLog(@"VELOCITY R: %f", velocity.x);
				newPage++;
			} else if (newPage > 0 && offsetX > pagingThreshold) {
				newPage--;
			} else if (newPage < maxPage && offsetX < -pagingThreshold) {
				newPage++;
			}
			
			// notify delegate about to page
			if ([_delegate respondsToSelector:@selector(horizontalImageCollectionViewDidEndPanning:willPageToPage:)])
				[_delegate horizontalImageCollectionViewDidEndPanning:self willPageToPage:newPage];
			
			[self setPage:newPage animated:YES];
		}
	}
}

- (void)handleTap:(UITapGestureRecognizer *)inTapRecognizer;
{
	CGFloat offsetX = [inTapRecognizer locationInView:_cv].x;
	NSUInteger index = (offsetX - _flowLayout.sectionInset.left / 2.0) / (_flowLayout.itemSize.width + _flowLayout.minimumLineSpacing);
	//NSLog(@"TAP %d", index);
	
	if (!_isPaging && !_cv.dragging && !_cv.decelerating) {
		if ([_delegate respondsToSelector:@selector(horizontalImageCollection:didTapImageAtIndex:)]) {
			[_delegate horizontalImageCollection:self didTapImageAtIndex:index];
		}
	}
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (_isAnimating) {
		// enable horizontal scrolling while animating; remove bounds animation
		[_cv.layer removeAnimationForKey:@"bounds.origin.x"];
	}
	if ([_delegate respondsToSelector:@selector(pagingCollectionViewDidScroll:)])
		[_delegate pagingCollectionViewDidScroll:self];
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if ([_delegate respondsToSelector:@selector(pagingCollectionViewDidEndDecelerating:)])
		[_delegate pagingCollectionViewDidEndDecelerating:self];
	
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	if (gestureRecognizer == _customGestureRecognizer || gestureRecognizer == _customTapRecognizer)
		return YES;
	else
		return NO;
}

- (void)dealloc
{
	_delegate = nil;
	_dataSource = nil;
}

@end
