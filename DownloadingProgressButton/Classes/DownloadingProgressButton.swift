//
//  DownloadProgressButton.swift
//  DownloadProgressButton
//
//  Created by VAndrJ on 7/16/17.
//  Copyright © 2017 VAndrJ. All rights reserved.
//

import Foundation
import UIKit

public protocol DownloadingProgressButtonDelegate: class {
    func stateWasChanged(to newState: DownloadStates, sender: DownloadingProgressButton)
    func openClick(sender: DownloadingProgressButton)
    func cancelDownloading(sender: DownloadingProgressButton)
}

public enum DownloadStates {
    case none
    case pending
    case downloading
    case done
}

@IBDesignable
public class DownloadingProgressButton: UIControl {
    @IBInspectable var timeMultiplier: Double = 1
    @IBInspectable var lineWidth: CGFloat = 2
    @IBInspectable var progressLineWidth: CGFloat = 2
    
    @IBInspectable var mainColor: UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    @IBInspectable var downloadingColor: UIColor = UIColor.blue
    
    @IBInspectable var title: String = "GET"
    @IBInspectable var titleDone: String = "OPEN"
    @IBInspectable var titleColor: UIColor = UIColor.blue
    @IBInspectable var titleColorDone: UIColor = UIColor.blue
    @IBInspectable var titleFont: UIFont = UIFont.boldSystemFont(ofSize: 18)
    @IBInspectable var titleFontDone: UIFont = UIFont.boldSystemFont(ofSize: 18)
    
    @IBInspectable var detail: String = "Extra content"
    @IBInspectable var detailDone: String = ""
    @IBInspectable var detailColor: UIColor = UIColor.lightGray
    @IBInspectable var detailColorDone: UIColor = UIColor.lightGray
    @IBInspectable var detailFont: UIFont = UIFont.boldSystemFont(ofSize: 12)
    @IBInspectable var detailFontDone: UIFont = UIFont.boldSystemFont(ofSize: 12)
    
    public weak var delegate: DownloadingProgressButtonDelegate?
    override public var isEnabled: Bool {
        didSet {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: { [weak self] in
                if let wSelf = self {
                    wSelf.layer.opacity = wSelf.isEnabled ? 1 : 0.4
                }
            })
        }
    }
    
    private var titleLabel: UILabel!
    private var detailLabel: UILabel!
    private var titleLabelDone: UILabel!
    private var detailLabelDone: UILabel!
    private var borderLine: CAShapeLayer!
    private var downloadingLine: CAShapeLayer!
    private var downloadingProgressLine: CAShapeLayer!
    private var prevValue: CGFloat = 0
    private var isInterrupted: Bool = false
    private enum TimitgKey: String {
        case easeOut
        case easeIn
        case linear
    }
    private let timingFunction =  [
        "easeOut": kCAMediaTimingFunctionEaseOut,
        "easeIn": kCAMediaTimingFunctionEaseIn,
        "linear": kCAMediaTimingFunctionLinear
    ]
    private enum AnimationStates: String {
        case none
        case borderToCircle
        case borderToCircleReverse
        case circleRotation
        case circleRotationReverse
        case downloading
        case downloadingReverse
        case rotateToEnd
        case done
    }
    private struct AnimationKeys {
        static let backgroundColorChange = "backgroundColorAnimation"
        static let borderStrokeEnd = "borderStrokeEndAnimation"
        static let downloadingLineStrokeEnd = "downloadingLineStrokeEndAnimation"
        static let circleTransformRotation = "transform.rotation"
        static let downloadindAnimation = "downloadindAnimation"
    }
    private enum AnimationKeyPath: String {
        case backgroundColor
        case strokeEnd
        case strokeStart
        case strokeColor
        case transformRotation = "transform.rotation"
    }
    private var animationState: AnimationStates = .none {
        willSet(newValue) {
            animationStateWillUpdate(to: newValue)
        }
    }
    private var downloadState: DownloadStates = .none {
        willSet(newValue) {
            if newValue != downloadState {
                downloadingStateWillUpdate(to: newValue)
            }
        }
    }
    
    private func animationStateWillUpdate(to newValue: AnimationStates) {
        switch newValue {
        case .borderToCircle:
            borderLine.path = pathForBorder().cgPath
            borderLine.strokeStart = 0
            borderLine.strokeEnd = 0
            borderLine.strokeColor = mainColor.cgColor
            downloadingLine.strokeStart = 0
            downloadingLine.strokeEnd = 0.85
            downloadingLine.strokeColor = mainColor.cgColor
        case .borderToCircleReverse:
            borderLine.strokeStart = 0
            borderLine.strokeEnd = 1
            borderLine.strokeColor = mainColor.cgColor
            downloadingLine.strokeStart = 0
            downloadingLine.strokeEnd = 0
            downloadingLine.strokeColor = mainColor.cgColor
        case .rotateToEnd:
            downloadingProgressLine.strokeStart = 0
            downloadingProgressLine.strokeEnd = 0
            downloadingLine.strokeStart = 0
            downloadingLine.strokeEnd = 1
        case .downloading:
            downloadingProgressLine.strokeColor = downloadingColor.cgColor
        case .downloadingReverse:
            downloadingProgressLine.strokeStart = 0
            downloadingProgressLine.strokeEnd = 0
            downloadingLine.strokeStart = 0
            downloadingLine.strokeEnd = 1
        case .done:
            borderLine.path = pathForBorder().reversing().cgPath
            borderLine.strokeStart = 0
            borderLine.strokeEnd = 1
            downloadingLine.strokeStart = 0
            downloadingLine.strokeEnd = 0
            downloadingProgressLine.strokeStart = 1
            downloadingProgressLine.strokeEnd = 1
        default:
            break
        }
    }
    
    private func downloadingStateWillUpdate(to state: DownloadStates) {
        switch state {
        case .none:
            hideTitleShowDetails(false)
        case .done:
            hideTitleShowDetails(true)
        default:
            break
        }
        delegate?.stateWasChanged(to: state, sender: self)
    }
    
    private func hideTitleShowDetails(_ isHidden: Bool) {
        titleLabel.isHidden = isHidden
        detailLabel.isHidden = isHidden
        titleLabelDone.isHidden = !isHidden
        detailLabelDone.isHidden = !isHidden
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = getRaduis()
        self.layer.backgroundColor = mainColor.cgColor
        addLines()
        addTitle()
        addDetail()
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !isInterrupted {
            switch downloadState {
            case .none: fallthrough
            case .done:
                animateBackgroundTo(fadeIn: true)
            default:
                break
            }
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if !isInterrupted {
            switch downloadState {
            case .done:
                animateBackgroundTo(fadeIn: false)
                delegate?.openClick(sender: self)
                break
            case .none:
                hideTitle(true)
                if animationState == .none {
                    animateBorderToCircle()
                } else {
                    fallthrough
                }
            default:
                if animationState != .done {
                    delegate?.cancelDownloading(sender: self)
                }
            }
        }
    }
    
    /**
     Informs the button to start animates
     
     Animates button to pending circle rotation and call stateWasChanged(to:sender:) delegate method
     */
    public func startProgrammatically() {
        guard downloadState == .none else {
            return
        }
        hideTitle(true)
        animateBackgroundTo(fadeIn: true)
        animateBorderToCircle()
    }
    
    /**
     Informs the button downloading process stareted
     
     Button end rotation animation and wait for download progress
     */
    public func downloadingStarted() {
        guard !isInterrupted, animationState == .circleRotation else {
            return
        }
        animateRotateToEnd()
    }
    
    /**
     Informs the button downloading process cancelled
     
     Button animates to initial state
     */
    public func downloadingCancelled() {
        isInterrupted = true
        prevValue = 0
        switch animationState {
        case .borderToCircle:
            reverseBorderToCircle()
        case .circleRotation: fallthrough
        case .rotateToEnd:
            reverseCircleRotation()
        case .downloading:
            reverseDownloading()
        default:
            break
        }
    }
    
    /**
     Informs the button downloading reset
     
     Button set to initial state
     */
    public func downloadingReset() {
        guard downloadState == .done else {
            return
        }
        downloadState = .none
        animationState = .none
    }
    
    /**
     Informs the button downloading set.
     
     Button set to downloaded state.
     */
    public func downloadingSet() {
        guard downloadState == .none else {
            return
        }
        downloadState = .done
        animationState = .done
    }
    
    /**
     Informs the button downloading progress was changed.
     
     When passed 1, button automatically ends animation downloads and set to downloaded state
     
     - Parameter to: downloading progress. Value between 0 and 1
     */
    public func downloadingProgressChanged(to newValue: CGFloat) {
        animateDownloading(value: max(0, min(1, newValue)))
    }
    
    /**
     Informs the button downloading progress was changed.
     
     When passed 100, button automatically ends animation downloads and set to downloaded state
     
     - Parameter to: downloading progress. Value between 0 and 100
     */
    @objc(downloadingProgressPercentsIntChangedTo:)
    public func downloadingProgressPercentsChanged(to newValue: Int) {
        downloadingProgressChanged(to: CGFloat(newValue) / 100)
    }
    
    /**
     Informs the button downloading progress was changed.
     
     When passed 100, button automatically ends animation downloads and set to downloaded state
     
     - Parameter to: downloading progress. Value between 0 and 100
     */
    @objc(downloadingProgressPercentsDoubleChangedTo:)
    public func downloadingProgressPercentsChanged(to newValue: Double) {
        downloadingProgressChanged(to: CGFloat(newValue) / 100)
    }
    
    /**
     Informs the button downloading progress was changed.
     
     When passed 100, button automatically ends animation downloads and set to downloaded state
     
     - Parameter to: downloading progress. Value between 0 and 100
     */
    @objc(downloadingProgressPercentsFloatChangedTo:)
    public func downloadingProgressPercentsChanged(to newValue: Float) {
        downloadingProgressChanged(to: CGFloat(newValue) / 100)
    }
    
    private func addLines() {
        downloadingProgressLine = CAShapeLayer()
        downloadingProgressLine.bounds = bounds
        downloadingProgressLine.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        downloadingProgressLine.fillColor = UIColor.clear.cgColor
        downloadingProgressLine.strokeColor = downloadingColor.cgColor
        downloadingProgressLine.lineWidth = progressLineWidth
        downloadingProgressLine.path = pathForCircle().cgPath
        downloadingProgressLine.strokeStart = 0
        downloadingProgressLine.strokeEnd = 0
        downloadingLine = CAShapeLayer()
        downloadingLine.bounds = bounds
        downloadingLine.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        downloadingLine.fillColor = UIColor.clear.cgColor
        downloadingLine.strokeColor = mainColor.cgColor
        downloadingLine.lineWidth = lineWidth
        downloadingLine.path = pathForCircle().cgPath
        downloadingLine.strokeStart = 0
        downloadingLine.strokeEnd = 0
        borderLine = CAShapeLayer()
        borderLine.bounds = bounds
        borderLine.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        borderLine.fillColor = UIColor.clear.cgColor
        borderLine.strokeColor = mainColor.cgColor
        borderLine.lineWidth = lineWidth
        borderLine.path = pathForBorder().cgPath
        self.layer.addSublayer(borderLine)
        self.layer.addSublayer(downloadingLine)
        self.layer.addSublayer(downloadingProgressLine)
    }
    
    private func addTitle() {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "|-0-[title]-0-|", options: [], metrics: [:], views: ["title": titleLabel]) + NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[title]-0-|", options: [], metrics: [:], views: ["title": titleLabel])
        NSLayoutConstraint.activate(constraints)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.text = title
        titleLabel.textColor = titleColor
        titleLabel.font = titleFont
        titleLabelDone = UILabel()
        titleLabelDone.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabelDone)
        let constraintsDone = NSLayoutConstraint.constraints(withVisualFormat: "|-0-[title]-0-|", options: [], metrics: [:], views: ["title": titleLabelDone]) + NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[title]-0-|", options: [], metrics: [:], views: ["title": titleLabelDone])
        NSLayoutConstraint.activate(constraintsDone)
        titleLabelDone.textAlignment = .center
        titleLabelDone.numberOfLines = 1
        titleLabelDone.text = titleDone
        titleLabelDone.textColor = titleColorDone
        titleLabelDone.font = titleFont
        titleLabelDone.isHidden = true
    }
    
    private func addDetail() {
        detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabel)
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(bounds.maxY / contentScaleFactor + 4)-[title]", options: [], metrics: [:], views: ["title": detailLabel]) + NSLayoutConstraint.constraints(withVisualFormat: "|-0-[title]-0-|", options: [], metrics: [:], views: ["title": detailLabel])
        NSLayoutConstraint.activate(constraints)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 1
        detailLabel.text = detail
        detailLabel.textColor = detailColor
        detailLabel.font = detailFont
        detailLabelDone = UILabel()
        detailLabelDone.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailLabelDone)
        let constraintsDone = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(bounds.maxY / contentScaleFactor + 4)-[title]", options: [], metrics: [:], views: ["title": detailLabelDone]) + NSLayoutConstraint.constraints(withVisualFormat: "|-0-[title]-0-|", options: [], metrics: [:], views: ["title": detailLabelDone])
        NSLayoutConstraint.activate(constraintsDone)
        detailLabelDone.textAlignment = .center
        detailLabelDone.numberOfLines = 1
        detailLabelDone.text = detailDone
        detailLabelDone.textColor = detailColorDone
        detailLabelDone.font = detailFontDone
        detailLabelDone.isHidden = true
    }
    
    private func endInterruption() {
        animationState = .none
        downloadState = .none
        animateBackgroundTo(fadeIn: false)
        hideTitle(false)
        isInterrupted = false
    }
    
    // MARK: - Animations
    
    private func animateDownloadingEnd() {
        guard !isInterrupted, downloadState == .downloading else {
            return
        }
        animationState = .done
        let animationDuration = 0.3 * timeMultiplier
        let strokeEndBorderAnimation = getAnimation(path: .strokeEnd, from: 0, to: 1, duration: animationDuration, timing: .easeIn)
        let strokeEndAnimation = getAnimation(path: .strokeStart, from: 0, to: 1, duration: animationDuration, timing: .easeOut)
        let lineColorAnimation = getAnimation(path: .strokeColor, from: downloadingColor.cgColor, to: mainColor.cgColor, duration: animationDuration, timing: .easeOut)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.hideTitle(false)
            self?.animateBackgroundTo(fadeIn: false)
            self?.downloadState = .done
        }
        borderLine.removeAllAnimations()
        downloadingLine.removeAllAnimations()
        borderLine.add(strokeEndBorderAnimation, forKey: AnimationKeys.borderStrokeEnd)
        downloadingProgressLine.add(strokeEndAnimation, forKey: AnimationKeys.downloadingLineStrokeEnd)
        downloadingProgressLine.add(lineColorAnimation, forKey: AnimationKeys.backgroundColorChange)
        CATransaction.commit()
    }
    
    private func animateDownloading(value: CGFloat) {
        guard downloadState == .downloading, !isInterrupted else {
            return
        }
        downloadingProgressLine.strokeEnd = value
        downloadingProgressLine.strokeStart = 0
        downloadingLine.strokeStart = value
        let animationDuration = 1.0
        let animationStart = prevValue == 0 ? 0 : downloadingProgressLine.presentation()!.strokeEnd
        let downloadingLineAnimation = getAnimation(path: .strokeStart, from: animationStart, to: value, duration: animationDuration, timing: .linear)
        let downloadingAnimation = getAnimation(path: .strokeEnd, from: animationStart, to: value, duration: animationDuration, timing: .linear)
        prevValue = value
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            if let wSelf = self, !wSelf.isInterrupted {
                if (value >= 1) {
                    wSelf.prevValue = 0
                    wSelf.animateDownloadingEnd()
                } else {
                    wSelf.prevValue = value
                }
            }
        }
        downloadingLine.removeAllAnimations()
        downloadingProgressLine.removeAllAnimations()
        downloadingProgressLine.add(downloadingAnimation, forKey: AnimationKeys.downloadindAnimation)
        downloadingLine.add(downloadingLineAnimation, forKey: AnimationKeys.downloadindAnimation)
        CATransaction.commit()
    }
    
    private func reverseDownloading() {
        animationState = .downloadingReverse
        let lineEnd = downloadingProgressLine.presentation()!.strokeEnd
        let animationDuration = 0.3 * timeMultiplier * Double(lineEnd)
        
        let downloadingAnimation = getAnimation(path: .strokeEnd, from: lineEnd, to: 0, duration: animationDuration, timing: .easeIn)
        
        let downloadingLineAnimation = getAnimation(path: .strokeStart, from: lineEnd, to: 0, duration: animationDuration, timing: .easeIn)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.reverseCircleRotation()
        }
        downloadingLine.removeAllAnimations()
        downloadingProgressLine.removeAllAnimations()
        downloadingProgressLine.add(downloadingAnimation, forKey: AnimationKeys.downloadindAnimation)
        downloadingLine.add(downloadingLineAnimation, forKey: AnimationKeys.downloadindAnimation)
        CATransaction.commit()
    }
    
    private func animateRotateToEnd() {
        guard !isInterrupted, animationState == .circleRotation else {
            return
        }
        animationState = .rotateToEnd
        let animationDuration = 0.1 * timeMultiplier
        let currentRotationAngle = atan2(downloadingLine.presentation()!.transform.m12, downloadingLine.presentation()!.transform.m11)
        let circleRotateAnimation = getAnimation(path: .transformRotation, from: currentRotationAngle, to: 0, duration: animationDuration, timing: .linear)
        let downloadingLineStrokeEndAnimation = getAnimation(path: .strokeEnd, from: 0.85, to: 1, duration: animationDuration, timing: .linear)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            if let wSelf = self, !wSelf.isInterrupted {
                wSelf.downloadState = .downloading
                wSelf.animationState = .downloading
            }
        }
        downloadingLine.removeAllAnimations()
        downloadingLine.add(downloadingLineStrokeEndAnimation, forKey: AnimationKeys.downloadingLineStrokeEnd)
        downloadingLine.add(circleRotateAnimation, forKey: AnimationKeys.circleTransformRotation)
        CATransaction.commit()
    }
    
    private func animateCircleRotation() {
        guard !isInterrupted, animationState == .borderToCircle else {
            return
        }
        animationState = .circleRotation
        downloadState = .pending
        let circleRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        circleRotateAnimation.fromValue = 0
        circleRotateAnimation.toValue = CGFloat.pi * 2
        circleRotateAnimation.duration = 1
        circleRotateAnimation.repeatCount = Float.greatestFiniteMagnitude
        CATransaction.begin()
        downloadingLine.removeAllAnimations()
        downloadingLine.add(circleRotateAnimation, forKey: AnimationKeys.circleTransformRotation)
        CATransaction.commit()
    }
    
    private func reverseCircleRotation() {
        animationState = .circleRotationReverse
        let currentRotationAngle = atan2(downloadingLine.presentation()!.transform.m12, downloadingLine.presentation()!.transform.m11)
        let circleRotateAnimation = getAnimation(path: .transformRotation, from: currentRotationAngle, to: 0, duration: 0.02 * timeMultiplier * (Double (currentRotationAngle / CGFloat.pi) + 1), timing: .linear)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.reverseBorderToCircle()
        }
        downloadingLine.removeAllAnimations()
        downloadingLine.add(circleRotateAnimation, forKey: AnimationKeys.circleTransformRotation)
        CATransaction.commit()
    }
    
    private func animateBorderToCircle() {
        guard !isInterrupted, animationState == .none else {
            return
        }
        animationState = .borderToCircle
        let animationDuration = 0.3 * timeMultiplier
        let downloadingLineStrokeEndAnimation = getAnimation(path: .strokeEnd, from: 0, to: 0.85, duration: animationDuration, timing: .easeIn)
        let borderStrokeEndAnimation = getAnimation(path: .strokeEnd, from: 1, to: 0, duration: animationDuration, timing: .easeOut)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            if let wSelf = self, !wSelf.isInterrupted {
                wSelf.animateCircleRotation()
            }
        }
        borderLine.removeAllAnimations()
        downloadingLine.removeAllAnimations()
        borderLine.add(borderStrokeEndAnimation, forKey: AnimationKeys.borderStrokeEnd)
        downloadingLine.add(downloadingLineStrokeEndAnimation, forKey: AnimationKeys.downloadingLineStrokeEnd)
        CATransaction.commit()
    }
    
    private func reverseBorderToCircle() {
        animationState = .borderToCircleReverse
        let animationDuration = 0.3 * timeMultiplier * Double(downloadingLine.presentation()!.strokeEnd)
        let downloadingLineStrokeEndAnimation = getAnimation(path: .strokeEnd, from: downloadingLine.presentation()!.strokeEnd, to: 0, duration: animationDuration, timing: .easeOut)
        let borderStrokeEndAnimation = getAnimation(path: .strokeEnd, from: borderLine.presentation()!.strokeEnd, to: 1, duration: animationDuration, timing: .easeIn)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.endInterruption()
        }
        downloadingLine.removeAllAnimations()
        borderLine.removeAllAnimations()
        borderLine.add(borderStrokeEndAnimation, forKey: AnimationKeys.borderStrokeEnd)
        downloadingLine.add(downloadingLineStrokeEndAnimation, forKey: AnimationKeys.downloadingLineStrokeEnd)
        CATransaction.commit()
    }
    
    private func hideTitle(_ isHidden: Bool) {
        UIView.transition(with: titleLabel, duration: 0.1 * timeMultiplier, options: [.transitionCrossDissolve, .curveEaseOut], animations: { [weak self] in
            if let wSelf = self {
                wSelf.titleLabel.isHidden = isHidden
                wSelf.detailLabel.isHidden = isHidden
            }}, completion: nil)
    }
    
    private func animateBackgroundTo(fadeIn: Bool) {
        layer.backgroundColor = fadeIn ? UIColor.white.cgColor : mainColor.cgColor
        let animationDuration = 0.1 * timeMultiplier
        let bgAnimation = getAnimation(path: .backgroundColor, from: layer.presentation()!.backgroundColor!, to: fadeIn ? UIColor.white.cgColor : mainColor.cgColor, duration: animationDuration, timing: .linear)
        layer.removeAllAnimations()
        layer.add(bgAnimation, forKey: AnimationKeys.backgroundColorChange)
    }
    
    private func getAnimation(path key: AnimationKeyPath, from fromValue: Any, to toValue: Any, duration: Double, timing: TimitgKey) -> CABasicAnimation {
        let basicAnimation = CABasicAnimation(keyPath: key.rawValue)
        basicAnimation.fromValue = fromValue
        basicAnimation.toValue = toValue
        basicAnimation.timingFunction = CAMediaTimingFunction(name: timingFunction[timing.rawValue]!)
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.duration = duration
        return basicAnimation
    }
    
    // MARK: - Path Helpers
    
    private enum Sides {
        case left
        case right
    }
    
    private func getCenter() -> CGPoint {
        guard let center = self.superview?.convert(self.center, to: self) else {
            return CGPoint.zero
        }
        return center
    }
    
    private func pathForCircle() -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.addArc(withCenter: getCenter(), radius: getRaduis(), startAngle: CGFloat.pi * 1.5, endAngle: CGFloat.pi * 3.5, clockwise: true)
        return path
    }
    
    private func pathForBorder() -> UIBezierPath {
        func getCenter(for side: Sides) -> CGPoint {
            var center = self.getCenter()
            switch side {
            case .left:
                center.x -= (self.bounds.maxX / 2 - (getRaduis() + lineWidth / 2))
            case .right:
                center.x += (self.bounds.maxX / 2 - (getRaduis() + lineWidth / 2))
            }
            return center
        }
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        let centerLeft = getCenter(for: .left)
        let centerRight = getCenter(for: .right)
        let radius = getRaduis()
        path.move(to: CGPoint(x: (centerLeft.x + centerRight.x)/2, y: centerLeft.y - radius))
        path.addLine(to: CGPoint(x: centerLeft.x, y: centerLeft.y - radius))
        path.addArc(withCenter: centerLeft, radius: radius, startAngle: CGFloat.pi * 1.5, endAngle: CGFloat.pi * 2.5, clockwise: false)
        path.addLine(to: CGPoint(x: centerRight.x, y: centerRight.y + radius))
        path.addArc(withCenter: centerRight, radius: radius, startAngle: CGFloat.pi * 2.5, endAngle: CGFloat.pi * 1.5, clockwise: false)
        path.addLine(to: CGPoint(x: (centerLeft.x + centerRight.x)/2, y: centerLeft.y - radius))
        path.close()
        return path
    }
    
    private func getRaduis() -> CGFloat {
        let minSize = min(self.bounds.maxY, self.bounds.maxX)
        return (minSize / 2)
    }
}
