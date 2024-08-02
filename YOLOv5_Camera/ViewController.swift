//
//  ViewController.swift
//  YOLOv5_Camera
//
//  Created by 최하연 on 8/3/24.
//

import UIKit
import CoreVideo
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: CapturePreviewView!
    @IBOutlet weak var classifiedLabel: UILabel!
    
    let videoCapture : VideoCapture = VideoCapture()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            if self.videoCapture.initCamera(){
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).session =
                    self.videoCapture.captureSession
                
                (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity =
                    AVLayerVideoGravity.resizeAspectFill
                
                self.videoCapture.asyncStartCapturing()
            }else{
                fatalError("Fail to init Video Capture")
            }
            
            
        }
    
}

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture,
                         pixelBuffer:CVPixelBuffer?,
                         timestamp:CMTime){
        
    }
}
