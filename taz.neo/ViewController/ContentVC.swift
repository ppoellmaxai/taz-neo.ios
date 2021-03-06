//
//  ContentVC.swift
//
//  Created by Norbert Thies on 25.09.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import NorthLib

// A ContentUrl provides a WebView URL for Articles and Sections
public class ContentUrl: WebViewUrl, DoesLog {

  public var content: Content
  public var path: String
  public lazy var url: URL = URL(fileURLWithPath: path + "/" + content.html.fileName)

  private var availableClosure: (()->())?
  private var loadClosure: (ContentUrl)->()
  private var _isAvailable = false
  public var isAvailable: Bool {
    get {
      guard !_isAvailable else { return true }
      for f in content.files {
        if !f.fileNameExists(inDir: path) { self.loadClosure(self); return false }
      }
      _isAvailable = true
      return true
    }
    set {
      _isAvailable = true
      if let closure = availableClosure { closure() }
    }
  }
  public func whenAvailable(closure: @escaping ()->()) { availableClosure = closure }

  public func waitingView() -> UIView? {
    let view = LoadingView()
    view.topText = content.title ?? ""
    view.bottomText = "wird geladen..."
    return view
  }
  
  public init(path: String, issue: Issue, content: Content, load: @escaping (ContentUrl)->()) {
    self.content = content
    self.path = path
    self.loadClosure = load
  }
  
} // ContentUrl

/// The ContentToolBar consists of a ToolBar and an encompassing view to position
/// the toolbar with enough distance to the bottom safe area
open class ContentToolbar: UIView {
  
  static let ToolbarHeight: CGFloat = 44
  private var toolbar = Toolbar()
  private var heightConstraint: NSLayoutConstraint?

  public var totalHeight: CGFloat {
    return ContentToolbar.ToolbarHeight + UIWindow.bottomInset
  }
  
  public override var backgroundColor: UIColor? {
    didSet { toolbar.backgroundColor = self.backgroundColor }
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(toolbar)
    pin(toolbar.top, to: self.top)
    pin(toolbar.left, to: self.left)
    pin(toolbar.right, to: self.right)
    toolbar.pinHeight(ContentToolbar.ToolbarHeight)
    toolbar.createBars(2)
    self.clipsToBounds = true
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public func pinTo(_ view: UIView) {
    view.addSubview(self)
    pin(self.left, to: view.left)
    pin(self.right, to: view.right)
    pin(self.bottom, to: view.bottom)
    heightConstraint = self.pinHeight(totalHeight)
  }
  
  public func hide(_ isHide: Bool = true) {
    if isHide {
      UIView.animate(withDuration: 0.5) { [weak self] in
        self?.heightConstraint?.isActive = false
        self?.heightConstraint = self?.pinHeight(0)
        self?.layoutIfNeeded()
      }
    }
    else {
      UIView.animate(withDuration: 0.5) { [weak self] in
        self?.heightConstraint?.isActive = false
        self?.heightConstraint = self?.pinHeight(self!.totalHeight)
        self?.layoutIfNeeded()
      }   
    }
  }
  
  public func addButton(_ button: ButtonControl, direction: Toolbar.Direction) {
    toolbar.addButton(button, direction: direction)
  }
  
  public func addArticleButton(_ button: ButtonControl, direction: Toolbar.Direction) {
    toolbar.addButton(button, direction: direction, at: 1)
  }
  
  public func addSectionButton(_ button: ButtonControl, direction: Toolbar.Direction) {
    toolbar.addButton(button, direction: direction, at: 0)
  }
  
  func setArticleBar() { toolbar.bar = 1 }
  func setSectionBar() { toolbar.bar = 0 }
  
  public func setButtonColor(_ color: UIColor) { toolbar.setButtonColor(color) }

}

/**
 A ContentVC is a view controller that displays an array of Articles or Sections 
 in a collection of WebViews
 */
open class ContentVC: WebViewCollectionVC, IssueInfo, UIStyleChangeDelegate {

  /// CSS Margins for Articles and Sections
  public static let TopMargin: CGFloat = 65
  public static let BottomMargin: CGFloat = 34

  public var feederContext: FeederContext  
  public var delegate: IssueInfo!
  public var contentTable: ContentTableVC?
  public var contents: [Content] = []
  public var feeder: Feeder { delegate.feeder }
  public var issue: Issue { delegate.issue }
  public var feed: Feed { issue.feed }
  public var dloader: Downloader { delegate.dloader }
  lazy var slider = ButtonSlider(slider: contentTable!, into: self)
  /// Whether to show all content images in a gallery
  public var showImageGallery = true
  public var toolBar = ContentToolbar()
  private var toolBarConstraint: NSLayoutConstraint?
  public var backButton = Button<LeftArrowView>()  
//  public var backButton = Button<ImageView>()
  private var backClosure: ((ContentVC)->())?
  public var homeButton = Button<ImageView>()
  private var homeClosure: ((ContentVC)->())?
  public var settingsButton = Button<ImageView>()
  private var settingsClosure: ((ContentVC)->())?
  public var shareButton = Button<ImageView>()
  private var shareClosure: ((ContentVC)->())?
  private var imageOverlay: Overlay?
  
  private var settingsBottomSheet: BottomSheet!
  private var textSettingsVC = TextSettingsVC()
  
  public var header = HeaderView()
  public var isLargeHeader = false
  
  private static var _tazApiCss: File? = nil
  public var tazApiCss: File {
    if ContentVC._tazApiCss == nil 
    { ContentVC._tazApiCss = File(dir: feeder.resourcesDir.path, fname: "tazApi.css") }
    return ContentVC._tazApiCss!
  }
  private static var _tazApiJs: File? = nil
  public var tazApiJs: File {
    if ContentVC._tazApiJs == nil 
    { ContentVC._tazApiJs = File(dir: feeder.resourcesDir.path, fname: "tazApi.js") }
    return ContentVC._tazApiJs!
  }
  
  public func resetIssueList() { delegate.resetIssueList() }  

  /// Write tazApi.css to resource directory
  public func writeTazApiCss(topMargin: CGFloat = TopMargin, bottomMargin: CGFloat = BottomMargin, callback: (()->())? = nil) {
    let dfl = Defaults.singleton
    let textSize = Int(dfl["articleTextSize"]!)!
    let colorMode = dfl["colorMode"]
    let textAlign = dfl["textAlign"]
    var colorModeImport: String = ""
    if colorMode == "dark" { colorModeImport = "@import \"themeNight.css\";" }
    let cssContent = """
      \(colorModeImport)
      @import "scroll.css";
      html, body { 
        font-size: \((CGFloat(textSize)*18)/100)px; 
      }
      body {
        padding-top: \(topMargin+UIWindow.topInset/2)px;
        padding-bottom: \(bottomMargin+UIWindow.bottomInset/2)px;
      } 
      p {
        text-align: \(textAlign!);
      }
    """
    File.open(path: tazApiCss.path, mode: "w") { f in f.writeline(cssContent)
      callback?()
    }
  }
  
  /// Setup JS bridge
  private func setupBridge() {
    self.bridge = JSBridgeObject(name: "tazApi")
    self.bridge?.addfunc("openImage") { jscall in
      if let args = jscall.args, args.count > 0,
         let img = args[0] as? String {
        let current = self.contents[self.index!]
        let imgVC = ContentImageVC(content: current, delegate: self,
                                   imageTapped: img)
        imgVC.showImageGallery = self.showImageGallery
        self.imageOverlay = Overlay(overlay:imgVC , into: self)
        self.imageOverlay!.maxAlpha = 0.9
        self.imageOverlay!.open(animated: true, fromBottom: true)
        // Inform Application to re-evaluate Orientation for current ViewController
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification,
                                        object: nil)
        self.imageOverlay!.onClose {
          // reset orientation to portrait
          UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
          self.imageOverlay = nil
        }
        imgVC.toClose {
          self.imageOverlay!.close(animated: true, toBottom: true)
        }
      }
      return NSNull()
    }
  }
  
  /// Write tazApi.js to resource directory
  public func writeTazApiJs() {
    setupBridge()
    let apiJs = """
      var tazApi = new NativeBridge("tazApi");
      tazApi.openUrl = function (url) { window.location.href = url };
      tazApi.openImage = function (url) { tazApi.call("openImage", undefined, url) };
    """
    tazApiJs.string = JSBridgeObject.js + apiJs
  }
  
  /// Define the closure to call when the back button is tapped
  public func onBack(closure: @escaping (ContentVC)->()) 
    { backClosure = closure }
  
  /// Define the closure to call when the home button is tapped
  public func onSettings(closure: @escaping (ContentVC)->())
    { settingsClosure = closure }
  
  /// Define the closure to call when the home button is tapped
  public func onHome(closure: @escaping (ContentVC)->()) 
    { homeClosure = closure }
  
  public func onShare(closure: @escaping (ContentVC)->()) 
  { shareClosure = closure; toolBar.setArticleBar() }
  
  
  func setupSettingsBottomSheet() {
    settingsBottomSheet = BottomSheet(slider: textSettingsVC, into: self)
    
    if UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 > 0 {
      settingsBottomSheet.coverage = 235
    }
    else {
      settingsBottomSheet.coverage = 200
    }
    
    onSettings{ [weak self] _ in
      guard let self = self else { return }
      self.debug("*** Action: <Settings> pressed")
      if self.settingsBottomSheet.isOpen {
          self.settingsBottomSheet.close()
      }
      else {
        self.settingsBottomSheet.open()
      }
      
      self.textSettingsVC.updateButtonValuesOnOpen()
    }
  }
  
  func setupToolbar() {
    backButton.onPress { [weak self] _ in 
      guard let self = self else { return }
      self.backClosure?(self)
    }
    homeButton.onPress { [weak self] _ in 
      guard let self = self else { return }
      self.homeClosure?(self)
    }
    shareButton.onPress { [weak self] _ in 
      guard let self = self else { return }
      self.shareClosure?(self)
    }
    settingsButton.onPress { [weak self] _ in
      guard let self = self else { return }
      self.settingsClosure?(self)
    }
    
    backButton.pinWidth(40)
    backButton.pinHeight(40)
    backButton.vinset = 0.43
    backButton.isBistable = false
    backButton.lineWidth = 0.06
    settingsButton.pinWidth(55)
    settingsButton.pinHeight(40)
    settingsButton.inset = 0.0
    settingsButton.buttonView.symbol = "textformat.size"
    settingsButton.buttonView.imageView.iosLower13?.pinWidth(44)
    homeButton.pinWidth(40)
    homeButton.pinHeight(40)
    homeButton.inset = 0.20
    homeButton.buttonView.name = "Home"
    shareButton.buttonView.symbol = "square.and.arrow.up"
    shareButton.pinWidth(55)
    shareButton.pinHeight(40)
    shareButton.inset = 0.24
    toolBar.addButton(backButton, direction: .left)
    toolBar.addButton(homeButton, direction: .right)
    toolBar.addArticleButton(shareButton, direction: .center)
    toolBar.addArticleButton(Toolbar.Spacer(), direction: .center)
    toolBar.addButton(settingsButton, direction: .center)
    toolBar.setButtonColor(Const.Colors.darkTintColor)
    toolBar.backgroundColor = Const.Colors.darkToolbar
    toolBar.pinTo(self.view)
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    writeTazApiCss()
    writeTazApiJs()
    setupSettingsBottomSheet()
    setupToolbar()
    header.installIn(view: self.view, isLarge: isLargeHeader, isMini: true)
    whenScrolled { [weak self] ratio in
      if (ratio < 0) { self?.toolBar.hide(); self?.header.hide(true) }
      else { self?.toolBar.hide(false); self?.header.hide(false) }
    }
    let img = UIImage.init(named: "logo")
    slider.image = img
    slider.buttonAlpha = 1.0
    slider.button.layer.shadowOpacity = 0.25
    slider.button.layer.shadowOffset = CGSize(width: 2, height: 2)
    slider.button.layer.shadowRadius = 4
    header.leftIndent = 8 + slider.visibleButtonWidth
    let path = feeder.issueDir(issue: issue).path
    let curls: [ContentUrl] = contents.map { cnt in
      ContentUrl(path: path, issue: issue, content: cnt) { [weak self] curl in
        guard let this = self else { return }
        this.dloader.downloadIssueData(issue: this.issue, files: curl.content.files) { err in
          if err == nil { curl.isAvailable = true }
        }
      }
    }
    displayUrls(urls: curls)
    registerForStyleUpdates(alsoForiOS13AndHigher: true)
  }
  
  public func applyStyles() {
    slider.button.layer.shadowColor = Const.SetColor.CTDate.color.cgColor
    settingsBottomSheet.color = Const.SetColor.ios(.secondarySystemBackground).color
    settingsBottomSheet.handleColor = Const.SetColor.ios(.opaqueSeparator).color
    self.collectionView.backgroundColor = Const.SetColor.CTBackground.color
    self.view.backgroundColor = Const.SetColor.CTBackground.color
    self.indicatorStyle = Defaults.darkMode ?  .white : .black
    writeTazApiCss{
      super.reloadAllWebViews()
    }
  }
  
  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return Defaults.darkMode ?  .lightContent : .default
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.collectionView.backgroundColor = Const.SetColor.CTBackground.color
    self.view.backgroundColor = Const.SetColor.CTBackground.color
  }
  
  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    slider.close()
    self.settingsBottomSheet.close()
    if let overlay = imageOverlay { overlay.close(animated: false) }
  }
  
  public func setup(contents: [Content], isLargeHeader: Bool) {
    self.contents = contents
    self.isLargeHeader = isLargeHeader
    self.contentTable!.feeder = feeder
    self.contentTable!.issue = issue
    self.contentTable!.image = feeder.momentImage(issue: issue)
    self.baseDir = feeder.baseDir.path
    onBack { [weak self] _ in
      self?.debug("*** Action: <Back> pressed")
      self?.navigationController?.popViewController(animated: true)
    }
    onHome { [weak self] _ in
      self?.debug("*** Action: <Home> pressed")
      self?.resetIssueList()
      self?.navigationController?.popToRootViewController(animated: true)
    }
  }
 
  public init(feederContext: FeederContext) {
    self.feederContext = feederContext
    self.contentTable = ContentTableVC.loadFromNib()
    super.init()
  }  
   
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
