//
//  YapPagingCollectionView.m
//  yap-iphone
//
//  Created by Trevor Stout on 4/16/13.
//  Copyright (c) 2013 Yap.tv, Inc. All rights reserved.
//

#import "YapPagingCollectionView.h"
#import "UIView+YapBouncyAnimations.h"

@implementation YapPagingCollectionView {
	UICollectionView *_cv;
	UICollectionViewFlowLayout *_flowLayout;
	
	NSInteger _numberOfItems;

	CGFloat _beginOffsetX;
	CGFloat _beginPagingOffsetX; // start of paging gesture rec
	BOOL _isAnimating;
	BOOL _isPaging;

	NSMutableSet *_hiddenImages;
	
	UIPanGestureRecognizer *_customGestureRecognizer;
	UITapGestureRecognizer *_customTapRecognizer;
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
		UICollectionViewCell *cell = (UICollectionViewCell *) [_cv cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
		return [cell convertRect:cell.bounds toView:view];
	}
	return CGRectZero;
}

- (void)setItemSize:(CGSize)itemSize
{
	_itemSize = itemSize;
	_flowLayout.itemSize = _itemSize;
	[_cv reloadData];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
	_contentInset = contentInset;
	_flowLayout.sectionInset = _contentInset;
	[_cv reloadData];
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
	if (_scrollEnabled) {
		if (!_customGestureRecognizer) {
			// enable custom paging
			_customGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
			[_customGestureRecognizer addTarget:self action:@selector(handleHorizontalPan:)];
			_customGestureRecognizer.delegate = self;
			[_cv addGestureRecognizer:_customGestureRecognizer];
		}
	} else {
		[_cv removeGestureRecognizer:_customGestureRecognizer];
		_customGestureRecognizer = nil;
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
        _flowLayout.sectionInset = (UIEdgeInsets) { .top = 16.0, .bottom = 16.0, .left = 16.0, .right = 16.0 };

        _flowLayout.minimumLineSpacing = 16.0;
        _flowLayout.itemSize = (CGSize) { .width = 192.0, .height = 64.0 };
    
		// create collection view
		CGRect rect = (CGRect) {
			.origin.x = -frame.size.width,
			.size.width = 3 * frame.size.width,
			.size.height = frame.size.height
		};
        
		_cv = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:_flowLayout];
		_cv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		_cv.contentInset = (UIEdgeInsets) { .left = self.bounds.size.width, .right = self.bounds.size.width };
		_cv.delegate = self;
		_cv.dataSource = self;
		_cv.userInteractionEnabled = YES;
		
		// bouncing and scrolling handled by custom gesture recognizer
		_cv.bounces = NO;
		_cv.alwaysBounceVertical = NO;
		_cv.alwaysBounceHorizontal = NO;
		_cv.allowsSelection = NO; // needed?
		_cv.scrollEnabled = NO;
		_cv.backgroundColor = [UIColor clearColor]; //[UIColor colorWithWhite:0.92 alpha:1.0];
		
		// add subview
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
	
	CGFloat duration = 1.0;
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
		}];
		
//		OWBounceInterpolation *spring = [[OWBounceInterpolation alloc] init];
//		spring.tension = 200.0f;
//		spring.friction = 20.0f;
//		
//		CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.origin.x"];
//		bounceAnimation.duration = duration;
//		spring.fromValue = [[_cv.layer valueForKeyPath:@"bounds.origin.x"] floatValue];
//		spring.toValue = bounds.origin.x;
//		bounceAnimation.values = [spring arrayOfInterpolatedValues];
//		bounceAnimation.calculationMode = kCAAnimationLinear;
//		bounceAnimation.fillMode = kCAFillModeBoth;
//		bounceAnimation.removedOnCompletion = YES;
		
//		[_cv.layer addAnimation:bounceAnimation forKey:@"bounds.origin.x"];

		CAKeyframeAnimation *animation = [_cv bouncyAnimationForKeyPath:@"bounds.origin.x"
															  fromValue:[_cv.layer valueForKeyPath:@"bounds.origin.x"]
																toValue:@(bounds.origin.x)
															   duration:duration];
		[_cv.layer addAnimation:animation forKey:@"bounds.origin.x"];
		
		
		[CATransaction commit];
		_cv.contentOffset = bounds.origin;
		
	} else {
		[_cv setContentOffset:bounds.origin animated:NO];
		
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
		
		_isPaging = YES;
		//			if ([_delegate respondsToSelector:@selector(pagingTableViewWillBeginPanning:)])
		//				[_delegate pagingTableViewWillBeginPanning:self];
		_beginOffsetX = [inPanRecognizer locationInView:self].x;
		_page = (_cv.contentOffset.x + _cv.contentInset.left) / _pageWidth;
		_beginPagingOffsetX = _page * _pageWidth - _cv.contentInset.left;
		[self removeAllAnimations];
		
	} else if (inPanRecognizer.state == UIGestureRecognizerStateChanged) {
		
		offsetX = [inPanRecognizer locationInView:self].x - _beginOffsetX;
		
		CGFloat drag = 1.0;
		if ((_page == 0 && offsetX > 0.0) || (_page == maxPage && offsetX < 0.0)) {
			drag = 0.5;
		}
		
		//NSLog(@"offsetX:%f isPaging:%d page:%d drag:%f", offsetX, _isPaging, _page, drag);
				
		_cv.contentOffset = (CGPoint) { .x = _beginPagingOffsetX - drag * offsetX };
			
//			if ([_delegate respondsToSelector:@selector(pagingTableViewDidPan:)])
//				[_delegate pagingTableViewDidPan:self];
		
	} else if (inPanRecognizer.state == UIGestureRecognizerStateEnded || inPanRecognizer.state == UIGestureRecognizerStateCancelled) {
		
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
		
		_isPaging = NO;
	}
}

- (void)handleTap:(UITapGestureRecognizer *)inTapRecognizer;
{
	CGFloat offsetX = [inTapRecognizer locationInView:_cv].x;
	NSUInteger index = (offsetX - _flowLayout.sectionInset.left / 2.0) / (_flowLayout.itemSize.width + _flowLayout.minimumLineSpacing);
	//NSLog(@"TAP %d", index);
	
	if ([_delegate respondsToSelector:@selector(horizontalImageCollection:didTapImageAtIndex:)]) {
		[_delegate horizontalImageCollection:self didTapImageAtIndex:index];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if ([_delegate respondsToSelector:@selector(horizontalImageCollectionViewDidScroll:)])
		[_delegate horizontalImageCollectionViewDidScroll:self];
	
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
