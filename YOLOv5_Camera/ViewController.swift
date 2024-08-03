//
//  ViewController.swift
//  YOLOv5_Camera
//
//  Created by 최하연 on 8/3/24.
//


import UIKit
import CoreVideo
import AVFoundation
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var previewView: CapturePreviewView!
    @IBOutlet weak var classifiedLabel: UILabel!
    
    let videoCapture: VideoCapture = VideoCapture()
    let context = CIContext()
    var model: YOLOv5? // YOLOv5 모델을 옵셔널로 선언

    // iouThreshold 및 confidenceThreshold 설정
    let iouThreshold: Double = 0.5
    let confidenceThreshold: Double = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.videoCapture.delegate = self
        
        // YOLOv5 모델을 초기화합니다.
        do {
            self.model = try YOLOv5(configuration: MLModelConfiguration())
        } catch {
            print("Failed to load YOLOv5 model: \(error)")
            return
        }
        
        if self.videoCapture.initCamera() {
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.videoCapture.asyncStartCapturing()
        } else {
            fatalError("Fail to init Video Capture")
        }
    }
}

extension ViewController: VideoCaptureDelegate {
    
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        guard let pixelBuffer = pixelBuffer else { return }
        
        // 모델에 맞는 입력 이미지로 준비
        let ciImage = CIImage(cvImageBuffer: pixelBuffer).resize(size: CGSize(width: 640, height: 640))
        guard let scaledPixelBuffer = ciImage.toPixelBuffer(context: context) else {
            print("Failed to convert CIImage to CVPixelBuffer")
            return
        }
        
        // 모델이 초기화되지 않았으면 리턴
        guard let model = model else {
            DispatchQueue.main.async {
                self.classifiedLabel.text = "Model not loaded"
            }
            return
        }
        
        // 모델을 이용한 예측
        guard let prediction = try? model.prediction(image: scaledPixelBuffer, iouThreshold: iouThreshold, confidenceThreshold: confidenceThreshold) else {
            DispatchQueue.main.async {
                self.classifiedLabel.text = "Prediction Failed"
            }
            return
        }
        
        // 예측 결과를 처리하여 레이블 업데이트
        guard let classProbabilities = prediction.featureValue(for: "class_probabilities")?.multiArrayValue,
              let boxCoordinates = prediction.featureValue(for: "box_coordinates")?.multiArrayValue else {
            DispatchQueue.main.async {
                self.classifiedLabel.text = "Prediction Result Error"
            }
            return
        }

        // MLMultiArray를 Double 배열로 변환하는 함수
        func convertMultiArrayToDoubleArray(_ multiArray: MLMultiArray) -> [Double] {
            let count = multiArray.count
            var resultArray = [Double](repeating: 0.0, count: count)
            for index in 0..<count {
                resultArray[index] = multiArray[index].doubleValue
            }
            return resultArray
        }
        
        // 클래스 확률 및 박스 좌표 추출
        let classProbabilitiesArray = convertMultiArrayToDoubleArray(classProbabilities)
        let boxCoordinatesArray = convertMultiArrayToDoubleArray(boxCoordinates)
        
        var resultText = ""
        let numBoxes = boxCoordinatesArray.count / 4
        
        for index in 0..<numBoxes {
            let classProbIndex = index * 80 // Assuming 80 classes
            let maxClassProb = classProbabilitiesArray[classProbIndex..<classProbIndex+80].max() ?? 0.0
            if maxClassProb > confidenceThreshold {
                let x = boxCoordinatesArray[index * 4]
                let y = boxCoordinatesArray[index * 4 + 1]
                let width = boxCoordinatesArray[index * 4 + 2]
                let height = boxCoordinatesArray[index * 4 + 3]
                let classLabel = "Class \(classProbabilitiesArray[classProbIndex..<classProbIndex+80].firstIndex(of: maxClassProb) ?? 0)"
                resultText += "\(classLabel): \(maxClassProb)\n"
            }
        }
        
        DispatchQueue.main.async {
            self.classifiedLabel.text = resultText.isEmpty ? "Can't Detect" : resultText
        }
    }
}
