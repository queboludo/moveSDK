//
//  MoveView.swift
//  MoveSDK
//
//  Created by Canozan Kusseven on 22.11.2017.
//  Copyright © 2017 Canozan Kusseven. All rights reserved.
//

import UIKit
import GoogleMobileAds
import GoogleInteractiveMediaAds
import Foundation


open class MoveSDKViewController: UIViewController, GADAppEventDelegate, GADBannerViewDelegate, GADInterstitialDelegate, IMAAdsLoaderDelegate, IMAAdsManagerDelegate, AVPictureInPictureControllerDelegate {
    

// --> START OF DEFINITION OF SDK VARIABLES <-- //
    
    // Google Ads SDK Setup Details
   
    open var mediumRectangleID = String()
    open var interstitialAdUnitID = String()
    open var customAdUnitID = String()
    
    open var bannerAdUnitID = String()
    open var SecondCustomAdUnit = String()
    open var ThirdCustomAdUnit = String()

    
    // Video Related Variables
    
    var contentVideoURL = String()
    var adTagUrlVideo = String()
    var contentPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoView : UIView?
    var activityIndicator = UIActivityIndicatorView()
    
 
    // IMA SDK Pip
    
    var pictureInPictureController: AVPictureInPictureController?
    var pictureInPictureProxy: IMAPictureInPictureProxy?
    
    // IMA SDK Playhead & Managers
    
    
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    
    
    // Display Ad Spots on Page
    
    var bannerView: DFPBannerView?
    var mediumRectangle: DFPBannerView?
    var customAd: DFPBannerView?
    var interstitial: DFPInterstitial?
    
    
    // Gesture Variables
    
    var gesture = MoveSDKGestures()
    var gestureCustomParams = Dictionary<String, Any>()
    var videoCustomParams = String()
    
    
    // Custom Params Supported
    
    var isCustomParamsSupported = Bool()
    
    
    
// --> END OF DEFINITION OF SDK VARIABLES <-- //
    
// --> SETUP MOVE SDK <-- //
    
    
    // Setup MoveSDK
    
    open func MoveSDKConfigure(bannerAdUnitID:String , interstitialAdUnitID:String,mediumRectangleID: String,customAdUnitID: String) {
        
        self.bannerAdUnitID = bannerAdUnitID   // 320x50 - 320x100
        self.interstitialAdUnitID = interstitialAdUnitID  // Interstatial
        self.mediumRectangleID = mediumRectangleID // 300x250 - 336x280
        self.customAdUnitID = customAdUnitID // Custom
        
        
    }
    
    
    // Support for Multiple Ad Units
    
    open func MultipleCustomAdsOnPage(supported: Bool, SecondCustomAdUnitID: String, ThirdCustomAdUnitID: String) {
        
        if supported{
            
            self.SecondCustomAdUnit = SecondCustomAdUnitID
            self.ThirdCustomAdUnit = ThirdCustomAdUnitID
            
        }
        
        
    }
    
    
    
    // Support for Video Ads with Custom AVPlayer
    
    open func VideoAdsSupported(supported:Bool, videoAdTag: String) {
        
        if supported {
            
            adTagUrlVideo = videoAdTag
            
        }
        
    }
    
    
    
    
    open func customParamsSupported(supported: Bool) {
        
        if supported {
            
            isCustomParamsSupported = true
            
           initializePopulate()
            
        } else {
            
            isCustomParamsSupported = false
            
        }
        
    }
    
    
    
    
    // Pass Paramteres from VC to Framework for Video Ads
    
    
    open func setupVideoAd(avPlayer:AVPlayer, avPlayerLayer:AVPlayerLayer,  contentVideoUrl: String, VideoViewArea : UIView ) {
        
        contentVideoURL = contentVideoUrl
        contentPlayer = avPlayer
        playerLayer = avPlayerLayer
        videoView = VideoViewArea
        
        setUpContentPlayer()
        setUpAdsLoader()
        setUpIMA()
        

        
    }
    
    
    
    // IMA SDK Functions
    
    
    
    func setUpContentPlayer() {

        let contentUrl = URL(string: contentVideoURL)
        contentPlayer = AVPlayer(url: contentUrl!)
        playerLayer = AVPlayerLayer(player: contentPlayer)
        playerLayer!.frame = (videoView?.layer.bounds)!
        videoView?.layer.addSublayer(playerLayer!)
        
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidFinishPlaying(_:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: contentPlayer!.currentItem)
        
        
        // Pip Functions
        pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self);
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer!);
        if (pictureInPictureController != nil) {
            pictureInPictureController!.delegate = pictureInPictureProxy;
        }
        

    }
    
    
    
    
    func setUpAdsLoader() {
        
        if (adsLoader != nil) {
            adsLoader = nil
        }
        
        let settings = IMASettings()
        settings.enableBackgroundPlayback = true;
        adsLoader = IMAAdsLoader(settings: settings)
    }
    
    
    
    func createAdDisplayContainer() -> IMAAdDisplayContainer {

        return IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
    
    }
    
    
    func setUpIMA() {
        
        if (adsManager != nil) {
            adsManager!.destroy()
        }
        adsLoader.contentComplete()
        adsLoader.delegate = self

    }
    

    
    open func requestVideoAd() {

        
        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        

        
        let can = adTagUrlVideo + videoCustomParams
        
        let request = IMAAdsRequest(
            adTagUrl: can,
            adDisplayContainer: createAdDisplayContainer(),
            avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: contentPlayer),
            pictureInPictureProxy: pictureInPictureProxy,
            userContext: nil)
        

        print(can)
        
        adsLoader.requestAds(with: request)
        
        
        
    }
    

    @objc func contentDidFinishPlaying(_ notification: Notification) {
        if ((notification.object as? AVPlayerItem) == contentPlayer!.currentItem) {
            
            adsLoader.contentComplete()
            
        }
    }
    
 
    
    // IMA SDK Delegates
    
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {

        adsManager = adsLoadedData.adsManager
        adsManager!.delegate = self
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = self
        
        
        startactivityIndicator(activityIndicator: activityIndicator, viewArea: videoView!)

        
        adsManager!.initialize(with: adsRenderingSettings)
        
        
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {

        contentPlayer!.play()
        
    }
    

    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        
        switch (event.type) {
        case IMAAdEventType.LOADED:
            if (pictureInPictureController == nil ||
                !pictureInPictureController!.isPictureInPictureActive) {
                
                startactivityIndicator(activityIndicator: activityIndicator, viewArea: videoView!)
                
                adsManager.start()
            }
            break
        case IMAAdEventType.PAUSE:
            break
        case IMAAdEventType.STARTED:
            stopActivityIndicatior(activityIndicator: activityIndicator, viewArea: videoView!)
            break
        case IMAAdEventType.RESUME:
            break
        case IMAAdEventType.TAPPED:
            break
        case IMAAdEventType.COMPLETE:
            startactivityIndicator(activityIndicator: activityIndicator, viewArea: videoView!)
            break
        case IMAAdEventType.SKIPPED:
            startactivityIndicator(activityIndicator: activityIndicator, viewArea: videoView!)
        default:
            break
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        
        contentPlayer!.play()
        
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        
        contentPlayer!.pause()
        
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        
        contentPlayer!.play()

        stopActivityIndicatior(activityIndicator: activityIndicator, viewArea: videoView!)

        
    }
    
    
 
    // Enum Cases for display as spot selection
    
    
    public enum adSize {
        
        case small
        case large
        case multiple
        case auto
        
        
    }
    
    
    public enum adUnitNumber {
        
        case FirstCustomAdUnit
        case SecondCustomAdUnit
        case ThirdCustomAdUnit
        
        
    }
    
    
    
    open func loadBanner(size: adSize ){
        
        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        
        
            if size == adSize.small {
                self.bannerView = DFPBannerView(adSize: kGADAdSizeBanner)
            }
            else if size == adSize.large{
                self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
            }
            else if size == adSize.multiple {
                self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
                var adSizes = [NSValue]()
                adSizes.append(NSValueFromGADAdSize(kGADAdSizeLargeBanner))
                adSizes.append(NSValueFromGADAdSize(kGADAdSizeBanner))
                bannerView?.validAdSizes = adSizes
            }
            else if size == adSize.auto {
                let screenHeight: CGFloat = UIScreen.main.bounds.size.height
                if screenHeight <= 480.0 {
                    self.bannerView = DFPBannerView(adSize: kGADAdSizeBanner)
                }
                else if screenHeight > 480.0 {
                    self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
                }
            }
            
            
            bannerView?.delegate = self
            bannerView?.appEventDelegate = self
            bannerView?.adUnitID = bannerAdUnitID
            bannerView?.rootViewController = self
            
            let request = DFPRequest()
            request.customTargeting = gestureCustomParams
        
            bannerView?.load(request)
            
            let screenSize = UIScreen.main.bounds
            
            let x = screenSize.width
            let y = screenSize.height
            let h = CGFloat((bannerView?.frame.height)!)
            let w = CGFloat((bannerView?.frame.width)!)
            
            bannerView?.frame = CGRect(x: ((x - (bannerView?.frame.width)!) / 2), y: (y - (bannerView?.frame.height)!) , width: w, height: h)
            
            self.view.addSubview(bannerView!)
            
   
    }
    
    
    
    open func getBanner(size: adSize) -> DFPBannerView{

        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        
            
            if size == adSize.small {
                self.bannerView = DFPBannerView(adSize: kGADAdSizeBanner)
            }
            else if size == adSize.large{
                self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
            }
            else if size == adSize.multiple {
                self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
                var adSizes = [NSValue]()
                adSizes.append(NSValueFromGADAdSize(kGADAdSizeLargeBanner))
                adSizes.append(NSValueFromGADAdSize(kGADAdSizeBanner))
                bannerView?.validAdSizes = adSizes
            }
            else if size == adSize.auto {
                let screenHeight: CGFloat = UIScreen.main.bounds.size.height
                if screenHeight <= 480.0 {
                    self.bannerView = DFPBannerView(adSize: kGADAdSizeBanner)
                }
                else if screenHeight > 480.0 {
                    self.bannerView = DFPBannerView(adSize: kGADAdSizeLargeBanner)
                }
            }
            
            bannerView?.delegate = self
            bannerView?.appEventDelegate = self
            bannerView?.adUnitID = bannerAdUnitID
            bannerView?.rootViewController = self
            
            self.view!.addSubview(bannerView!)
            bannerView?.isHidden = false
            let request = DFPRequest()
            request.customTargeting = gestureCustomParams
        
            bannerView?.load(request)
        
        return bannerView!
    }
    
    
    
    
    open func getMediumRectangle(size: adSize) -> DFPBannerView{

        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        
        
            if size == adSize.small {
                self.mediumRectangle = DFPBannerView(adSize: kGADAdSizeMediumRectangle)
            }
            else if size == adSize.large{
                let customAdSize = GADAdSizeFromCGSize(CGSize(width: 336, height: 280))
                self.mediumRectangle = DFPBannerView(adSize: customAdSize)
            }
            else if size == adSize.multiple {
                self.mediumRectangle = DFPBannerView(adSize: kGADAdSizeMediumRectangle)
                var adSizes = [NSValue]()
                adSizes.append(NSValueFromGADAdSize(kGADAdSizeMediumRectangle))
                let customGADAdSize = GADAdSizeFromCGSize(CGSize(width: 336, height: 280))
                adSizes.append(NSValueFromGADAdSize(customGADAdSize))
                mediumRectangle?.validAdSizes = adSizes
            }
            else if size == adSize.auto {
                let screenWidth: CGFloat = UIScreen.main.bounds.size.width
                if screenWidth < 336.0 {
                    self.mediumRectangle = DFPBannerView(adSize: kGADAdSizeMediumRectangle)
                }
                else if screenWidth >= 336.0 {
                    let customAdSize = GADAdSizeFromCGSize(CGSize(width: 336, height: 280))
                    self.mediumRectangle = DFPBannerView(adSize: customAdSize)
                }
            }
            
            mediumRectangle?.delegate = self
            mediumRectangle?.appEventDelegate = self
            mediumRectangle?.adUnitID = mediumRectangleID
            mediumRectangle?.rootViewController = self
            mediumRectangle?.isHidden = false
            let request = DFPRequest()
            request.customTargeting = gestureCustomParams
        
        
            mediumRectangle?.load(request)

        return mediumRectangle!
    }
    
    
    
    open func getCustomAd(Width: Int, Height: Int, AdUnitNumber: adUnitNumber) -> DFPBannerView{

        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        
            let customAdSize = GADAdSizeFromCGSize(CGSize(width: Width, height: Height))
            
            customAd = DFPBannerView(adSize: customAdSize)
            
            customAd?.delegate = self
            customAd?.appEventDelegate = self
            
            
            
            if AdUnitNumber == adUnitNumber.FirstCustomAdUnit {
                
                customAd?.adUnitID = customAdUnitID
                
            } else if AdUnitNumber == adUnitNumber.SecondCustomAdUnit {
                
                customAd?.adUnitID = SecondCustomAdUnit
                
            } else if AdUnitNumber == adUnitNumber.ThirdCustomAdUnit {
                
                customAd?.adUnitID = ThirdCustomAdUnit
                
            }
            
            
            customAd?.rootViewController = self
            
            let request = DFPRequest()
            request.customTargeting = gestureCustomParams
        
            customAd?.load(request)

        
        return customAd!
    }
    
    
    
    
    
    open func createAndLoadInterstitial() {
        
        if isCustomParamsSupported {
            
            initializePopulate()
            
        }
        
        interstitial = DFPInterstitial(adUnitID: interstitialAdUnitID)
        let request = DFPRequest()
        
         request.customTargeting = gestureCustomParams
        
        interstitial?.delegate = self
        interstitial?.load(request)
    }
    

    
        // Display Ad View Delegates
    
    
    open func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        
        interstitial?.present(fromRootViewController: self)
        
        
    }
    
    
    open func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial?.delegate = nil
        interstitial = nil
    }
    
    
    


    
    open func adView(_ banner: GADBannerView, didReceiveAppEvent name: String, withInfo info: String?) {
        
        setupGesturesBanner(name:name, info: info!, bannerView: banner)
        
        
    }
    
    
    
    open func interstitial(_ interstitial: GADInterstitial, didReceiveAppEvent name: String, withInfo info: String?) {


        setupGesturesInterstitial(name: name, info: info!, bannerView: interstitial)
        
    }
    
    
    
    func setupGesturesBanner(name: String, info: String, bannerView: GADBannerView) {
        
        standartGestureFunctions(name:name, info: info)
        
       if name == "deviceInfo" {
            
            for view in bannerView.subviews {
                
                let webSubview = view as! UIWebView
                
                let information = String(format: "initDFPBanner( %@ );", gesture.getDeviceInformation())
                
                webSubview.stringByEvaluatingJavaScript(from: information)
                
            }
        }
    }
    

    
    
    func setupGesturesInterstitial(name: String, info: String, bannerView: GADInterstitial) {
        
        standartGestureFunctions(name:name, info: info)
        
        if name == "deviceInfo" {
            
            for view in self.view.subviews {
                
                if view is UIWebView {
                    
                    let webview = view as! UIWebView
                    
                    let information = String(format: "initDFPINT( %@ );", gesture.getDeviceInformation())
                    
                    webview.stringByEvaluatingJavaScript(from: information)
                    
                }
            }
            
        }
        
    }
    
    


    
    func standartGestureFunctions (name:String, info: String) {
        
        
        if name == "vibrate"{
            gesture.vibrate()
        }
        else if name == "brightness"{
            
            let brightness = Double(info)
            gesture.setBrightness(brighnessLevel: brightness!)
        }
        else if name == "flashOn"{
            gesture.turnOnFlash()
        }else if name == "flashOff"{
            self.gesture.turnOffFlash()
        }
            
        else if name == "createEvent"{
            let configData = try! JSONSerialization.jsonObject(with: (info.data(using: String.Encoding.utf8)!), options: []) as! [String:AnyObject]
            
            let title = configData["title"] as! String
            let notes = configData["notes"] as! String
            let startdate = configData["startDate"] as! String
            let enddate = configData["endDate"] as! String
            let startTime = configData["startTime"] as! String
            let endTime = configData["endTime"] as! String
            
            gesture.createEvent(title:title, notes: notes, startDate: startdate, startTime: startTime, endDate: enddate, endTime: endTime)
            
        }
        
        
    }
    
    
    
    
    open func populateGestureTargets() -> Dictionary<String,Any> {
        
        var enormeArray = Dictionary<String , Any>()
        
        let batteryInfo = gesture.getBatteryInformation()
        
        let earPhoneStatus = gesture.getEarPhoneStatus()
        let brightness = gesture.getBrightness()
        let availableDisk = gesture.getDiskAvailable()
        let volumeLevel = gesture.getVolumeLevel()
        
        enormeArray.updateValue(volumeLevel, forKey: "volumeLevel")
        enormeArray.updateValue(availableDisk, forKey: "availableDisk")
        enormeArray.updateValue(earPhoneStatus, forKey: "earPhoneStatus")
        enormeArray.updateValue(brightness, forKey: "screenBrightness")
        
                
        enormeArray.update(other: batteryInfo)
        
        
        let stringCustoms = (enormeArray.flatMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")
        
        
        videoCustomParams = "&cust_params=" + (stringCustoms.replacingOccurrences(of: "=", with: "%3D").replacingOccurrences(of: "&", with: "%26").replacingOccurrences(of: ",", with: "%2C").replacingOccurrences(of: " ", with: "%20"))

        
        return enormeArray
        
        
        
    }
    
    
    func initializePopulate() {
        
        
        gestureCustomParams = populateGestureTargets()
        
        
    }
    
    
    
    
    // Activity Indicator Parameteres
    

    func startactivityIndicator(activityIndicator: UIActivityIndicatorView, viewArea: UIView) {
        
        
        let areawidth = viewArea.frame.width
        let areaHeight = viewArea.frame.height
        
        activityIndicator.frame = CGRect(x: ((areawidth / 2) - 25), y: ((areaHeight / 2 ) - 25), width: 50, height: 50)
        
        activityIndicator.layer.masksToBounds = true
        activityIndicator.layer.cornerRadius = 25
        activityIndicator.backgroundColor = UIColor.black

        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        
    
        viewArea.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
    }
    
    
    
    func stopActivityIndicatior(activityIndicator: UIActivityIndicatorView, viewArea: UIView ) {
        
        activityIndicator.stopAnimating()
        viewArea.willRemoveSubview(activityIndicator)
        
    }
    
    



}



extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}



