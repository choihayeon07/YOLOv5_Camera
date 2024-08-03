//
//  VideoCapture.swift
//  YOLOv5_Camera
//
//  Created by 최하연 on 8/3/24.
//

import UIKit
import AVFoundation

public protocol VideoCaptureDelegate: class {
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime)
}

public class VideoCapture : NSObject{
    
    public weak var delegate: VideoCaptureDelegate?
    //필요한 인스턴스 변수를 정의한다.
    let captureSession = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "session queue")
        
    public var fps = 15
    
    var lastTimestamp = CMTime()
    
    override init() {
        super.init()
        
    }
    
    func initCamera() -> Bool{
        // 여러 구성 처리를 일괄 작업한다는 신호를 보낸다. 변경사항은 commitConfiguration 메서드르 호출해야 반영된다.
        captureSession.beginConfiguration()
        //원하는 품질을 고른다.
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else{
            print("ERROR : no video device available")
            return false
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else{
            print("ERROR : could not create AVCaptureDeviceInput")
            return false
        }
        if captureSession.canAddInput(videoInput){
            captureSession.addInput(videoInput)
        }
        
        //프레임의 도착지
        let videoOutput = AVCaptureVideoDataOutput()
        let settings:[String:Any] = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA) //풀컬러
        ]
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true // 디스패치 큐가 사용중일 때 도착한 프레임은 모두 폐기된다.
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue) // 디스패치 큐로 유입된 프레임을 전달하는 델리게이트를 구현한다.
        if captureSession.canAddOutput(videoOutput){
            captureSession.addOutput(videoOutput) // 출력의 구성요청의 일부로 세션에 추가한다.
        }
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 0 // 기본 방향 (0도 회전)
        }
        captureSession.commitConfiguration() // 구성을 커밋하여 변경사항을 반영한다.
        
        return true
    }
    
    public func asyncStartCapturing(completion: (() -> Void)? = nil){
        sessionQueue.async {
            if !self.captureSession.isRunning{
                //startRunning을 호출하면 카메라(입력)으로 부터 델리게이트(출력)까지 데이터 흐름이 시작된다.
                self.captureSession.startRunning()
            }
            if let completion = completion{
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    public func asyncStopCapturing(completion: (() -> Void)? = nil){
        if self.captureSession.isRunning{
            self.captureSession.stopRunning()
        }
        if let completion = completion{
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

extension VideoCapture : AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //output은 AVCaptureVideoDataOutput 형식이고 프레임 관련 출력이다.
        //sample buffer는 CMSampleBuffer 형식이고 프레임의 데이터 접근을 위해 사용된다
        guard let delegate = self.delegate else { return } //delegate가 할당되지 않았을 경우를 방지한다.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)//최신 프레임과 관련된 시간을 얻는다.
        
        let elapsedTime = timestamp - lastTimestamp
        if elapsedTime >= CMTimeMake(value: 1,timescale: Int32(fps)){
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)//충분한 시간이 지난 뒤 샘플의 이미지 버퍼에 대한 참조를 얻어 델리게이트에 전달한다
            
            delegate.onFrameCaptured(videoCapture: self, pixelBuffer: imageBuffer, timestamp: timestamp)
        }
    }
}
