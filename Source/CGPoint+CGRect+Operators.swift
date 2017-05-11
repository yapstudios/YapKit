//
//  CGPoint + CGRect + Operators.swift
//
//  Created by Ollie Wagner on 12/21/15.
//  Copyright © 2015 Yap Studios. All rights reserved.
//

import UIKit

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
  return CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
  return CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
}

public func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}

public func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs.width + rhs, height: lhs.height + rhs)
}

public func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs.width - rhs, height: lhs.height - rhs)
}

public func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
}

public func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}

extension CGSize {

  func invertHeight() -> CGSize {
    var size = self
    size.height *= -1.0
    return size
  }

  func invertWidth() -> CGSize {
    var size = self
    size.width *= -1.0
    return size
  }
  
}
