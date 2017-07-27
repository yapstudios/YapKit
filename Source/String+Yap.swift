//
//  String+Yap.swift
//
//  Created by Emory Al-Imam 7/27/2017
//  Copyright © 2017 Yap Studios. All rights reserved.
//

public extension String {
	
	public func base64Encoded() -> String? {
		
		var base64EncodedString: String?
		if let data = self.data(using: .utf8) {
			base64EncodedString = data.base64EncodedString()
		}
		return base64EncodedString
	}
	
	public func base64Decoded() -> String? {
		
		var base64DecodedString: String?
		if let data = Data(base64Encoded: self) {
			base64DecodedString = String(data: data, encoding: .utf8)
		}
		return base64DecodedString
	}
}
