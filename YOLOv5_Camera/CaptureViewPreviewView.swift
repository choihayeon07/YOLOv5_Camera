//
//  CaptureViewPreviewView.swift
//  YOLOv5_Camera
//
//  Created by 최하연 on 8/3/24.
//

import AVFoundation
import UIKit

class CapturePreviewView : UIView{
    //뷰를 생성하는 초기에 호출되어 뷰를 인스턴스화 하고 그에 연결할 CALayer를 결정한다.
    override class var layerClass: AnyClass{
            return AVCaptureVideoPreviewLayer.self //동영상 프레임을 처리하기 위한 것이다
    }
    
}
