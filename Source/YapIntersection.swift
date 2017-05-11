//
//  YapIntersection.swift
//
//  Created by Ollie Wagner on 12/21/15.
//  Copyright © 2015 Yap Studios. All rights reserved.
//

import UIKit

public func findRectIntersection(_ origin: CGPoint, direction: CGPoint, rect: CGRect) -> CGPoint? {

    //Intersects Left Edge
    if let found = findLineIntersection((origin, origin + direction), line2: (CGPoint.zero, CGPoint(x: 0.0, y: 1.0))) {
        return found
    }

    //Intersects Top Edge
    if let found = findLineIntersection((origin, origin + direction), line2: (CGPoint.zero, CGPoint(x: 1.0, y: 0.0))) {
        return found
    }

    //Intersects Right Edge
    if let found = findLineIntersection((origin, origin + direction), line2: (CGPoint(x: 1.0, y: 0.0), CGPoint(x: 1.0, y: 1.0))) {
        return found
    }

    //Intersects Bottom Edge
    if let found = findLineIntersection((origin, origin + direction), line2: (CGPoint(x: 0.0, y: 1.0), CGPoint(x: 1.0, y: 1.0))) {
        return found
    }

    return nil
}

public func findLineIntersection(_ line: (CGPoint, CGPoint), line2: (CGPoint, CGPoint)) -> CGPoint? {
    let s1_x = line.1.x - line.0.x
    let s1_y = line.1.y - line.0.y

    let s2_x = line2.1.x - line2.0.x;
    let s2_y = line2.1.y - line2.0.y;

    let s = (-s1_y * (line.0.x - line2.0.x) + s1_x * (line.0.y - line2.0.y)) / (-s2_x * s1_y + s1_x * s2_y);
    let t = ( s2_x * (line.0.y - line2.0.y) - s2_y * (line.0.x - line2.0.x)) / (-s2_x * s1_y + s1_x * s2_y);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
        // Collision detected
        return CGPoint(x: line.0.x + (t * s1_x), y: line.0.y + (t * s1_y))
    }
    
    return nil // No collision
}

