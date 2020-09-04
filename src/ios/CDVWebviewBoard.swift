import UIKit
import WebKit

@objc(CDVWebviewBoard ) class CDVWebviewBoard: CDVPlugin, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    var urlString:String!
    var functionCallbackId = ""
    var statusbarHeight:Int!
    var webview:WKWebView?
    
    struct Rect {
        var top: Int
        var left: Int
        var width: Int
        var height: Int
        
        init(data: [String: Any]) {
            top = data["top"] as! Int
            left = data["left"] as! Int
            let tempWidth = data["width"] as! Double
            let tempHeight = data["height"] as! Double
            width = Int(tempWidth)
            height = Int(tempHeight)
        }
    }
    
    @objc override func pluginInitialize() {
//        code for inspection
//        urlString = Bundle.main.path(forResource: "www/subview", ofType: "html")
        statusbarHeight = Int(UIApplication.shared.statusBarFrame.height)
    }
    
    @objc func initialize(_ command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc func checkInit(_ command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc func add(_ command: CDVInvokedUrlCommand) {

        guard
        let data = command.argument(at: 0) as? [String: Any],
        let urlTemp = data["url"] as? String,
        let rectData = data["rect"] as? [String : Any],
//            let rect = Rect(rect: data["rect"] as! [String : Int]),
        !isAdded() else {return}
//        set sizes
        let rect = Rect(data: rectData)
        
//        webview setup
        let userController = WKUserContentController()
        userController.add(self, name: "native")
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController
        webview = WKWebView(frame: CGRect(x: rect.left, y: rect.top + statusbarHeight, width: rect.width, height: rect.height), configuration: webConfiguration)
        self.webview!.uiDelegate = self
        self.webview!.navigationDelegate = self

//        set url
        urlString = urlTemp
//        let url = URL(fileURLWithPath: urlString, isDirectory: false)
        let url = URL(string: urlString)
        let urlRequest = URLRequest(url: url!)
        webview!.load(urlRequest)
        self.webView.addSubview(webview!)

        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc func show(_ command: CDVInvokedUrlCommand) {
        guard isAdded() else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "まだ初期化されていません")
            commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        let shouldShow = command.argument(at: 0) as! Bool
        webview!.isHidden = !shouldShow
    }
    
    @objc func load(_ command: CDVInvokedUrlCommand) {
        guard isAdded() else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "まだ初期化されていません")
            commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        
        let loadRequest = URLRequest(url: URL(string: urlString)!)
        webview!.load(loadRequest)
    }
    
    @objc func forward(_ command: CDVInvokedUrlCommand) {
        guard isAdded() else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "まだ初期化されていません")
            commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        webview!.goForward()
    }
    
    @objc func back(_ command: CDVInvokedUrlCommand) {
        guard isAdded() else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "まだ初期化されていません")
            commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
        webview!.goBack()
    }
    
    @objc func resize(_ command: CDVInvokedUrlCommand) {
        guard
        let rectData = command.argument(at: 0) as? [String: Any] else {return}
        let rect = Rect(data: rectData)
        webview!.frame = CGRect(x: rect.left, y: rect.top + statusbarHeight, width: rect.width, height: rect.height)
    }
        
    struct MessageEvent {
        var eventName: String?
        var data: String?
        
        init(message: WKScriptMessage) {
            guard let body = message.body as? NSDictionary else {
                return
            }
            self.eventName = body["eventName"] as? String
            self.data = body["data"] as? String
        }
    }

    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "native":
            let body = MessageEvent(message: message)

            
            let data = [
                "eventName": body.eventName!,
                "data": body.data!
            ]
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
            result?.keepCallback = true
            commandDelegate.send(result, callbackId: functionCallbackId)
        default:
            break
        }
    }
    
    private func isAdded() -> Bool {
        return webview != nil
    }
    
    @objc func setOnFunctionCallback(_ command: CDVInvokedUrlCommand) {
        functionCallbackId = command.callbackId
    }

}

extension CDVWebviewBoard {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        self.urlString = webView.url?.absoluteString
        decisionHandler(WKNavigationResponsePolicy.allow)
    }

}
