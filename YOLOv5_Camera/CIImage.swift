//
//  CIImage.swift
//  YOLOv5_Camera
//
//  Created by 최하연 on 8/3/24.
//

import UIKit

extension CIImage{
    
    func resize(size: CGSize) -> CIImage {
        fatalError("Not implemented")
    }
    
    func toPixelBuffer(context:CIContext,
                       size insize:CGSize? = nil,
                       gray:Bool=true) -> CVPixelBuffer?{
        fatalError("Not implemented")
    }
}
