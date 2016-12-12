//
//  ViewController.swift
//  TPushTester
//
//  Created by uwei on 5/24/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Cocoa
import Security

let developerPushHost  = "gateway.sandbox.push.apple.com"
let distributePushHost = "gateway.push.apple.com"
let pushPort           = 2195
let deviceTokenLength  = 64

enum PushCertificateFileType:String {
    case PEM
    case P12
    case CER
}

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var apnsServerButton: NSButton!
    @IBOutlet weak var xgServerButton: NSButton!
    @IBOutlet weak var pushTokenTextField: NSTextField!

    @IBOutlet weak var pushMessageTextField: NSTextField!
    
    @IBOutlet weak var pushCertificatePathField: NSTextField!
    
    @IBOutlet weak var certificatePasswordTextField: NSTextField!
    
    @IBOutlet weak var certificateTitleLabel: NSTextField!
    @IBOutlet weak var certificatePasswordLabel: NSTextField!
    @IBOutlet weak var chooseCertificateButton: NSButton!
    @IBOutlet weak var developerHostButton: NSButton!
    @IBOutlet weak var distributionHostButton: NSButton!
    @IBOutlet weak var acccessIDLabel: NSTextField!
    @IBOutlet weak var accessIDTextField: NSTextField!
    @IBOutlet weak var secretKeyLabel: NSTextField!
    @IBOutlet weak var secretKeyTextFiled: NSTextField!
    @IBOutlet weak var managerQQLabel: NSTextField!
    @IBOutlet weak var managerQQTextField: NSTextField!
    @IBOutlet weak var xgTestCheckButton: NSButton!
    
    
    
    private var socket:otSocket = nil
    private var context:SSLContext!
    private var keychain:SecKeychain?
    private var certificate:SecCertificateRef?
    private var identity:SecIdentity?
    private var pushDeviceToken:String!
//    private var pushPayload:String     = ""
    private var pushMessage:String     = ""
    private var pushCertificatePath    = ""
    private var pushCertificatePasswd  = ""
    private var pushHost               = ""
    // 1: distribution 2:developement
    private var apnsPushEnviromentIntValue:UInt = 2
    private var accessID:String!
    private var secretKey:String!
    
    // 2: distribution 1:developement
    private var xgPushEnviromentIntValue:UInt = 1
    private var xgPushManagerQQ:String!
    private var mouseTrackingArea:NSTrackingArea!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        certificatePasswordTextField.hidden = true
        certificatePasswordLabel.hidden     = true
        xgTestCheckButton.hidden            = true
        if developerHostButton.state == 1 {
            pushHost = developerPushHost
        }
        if distributionHostButton.state == 1 {
            pushHost = distributePushHost
        }
        
        xgPushButtonDisplay()
        
        mouseTrackingArea = NSTrackingArea(rect: chooseCertificateButton.frame, options:[.MouseEnteredAndExited, .ActiveAlways], owner: self, userInfo: ["key":"value"])
        self.view.addTrackingArea(mouseTrackingArea)
         pushDeviceToken = NSUserDefaults.standardUserDefaults().objectForKey(XGiOSToken) as? String
        if pushDeviceToken != nil {
            pushTokenTextField.stringValue = pushDeviceToken
        }
        accessID = NSUserDefaults.standardUserDefaults().objectForKey(XGAccessIDKey) as? String
        if accessID != nil {
            accessIDTextField.stringValue = accessID
        }
        secretKey = NSUserDefaults.standardUserDefaults().objectForKey(XGSecretKey) as? String
        if secretKey != nil {
            secretKeyTextFiled.stringValue = secretKey
        }
        xgPushManagerQQ = NSUserDefaults.standardUserDefaults().objectForKey(XGAccountQQKey) as? String
        if xgPushManagerQQ != nil {
            managerQQTextField.stringValue = xgPushManagerQQ
        }
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        pushTokenTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        disconnect()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        exit(0)
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func uploadCertificate(sender: NSButton) {
        let panel = NSOpenPanel()
        panel.message = ""
        panel.prompt = "OK"
        panel.canChooseDirectories = true
        panel.canChooseFiles       = true
        panel.canCreateDirectories = false
        var path:NSString = ""
        let result = panel.runModal()
        if result == NSFileHandlingPanelOKButton {
            path = (panel.URL?.path)!
            
            // 判断是否选了文件
            var isDirectory:ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(path as String, isDirectory: &isDirectory) {
                if Bool(isDirectory) {
                    return
                }
            }
            pushCertificatePathField.stringValue = path as String
            pushCertificatePath = path as String
            let type = PushCertificateFileType.init(rawValue: path.pathExtension.uppercaseString)!
            if apnsServerButton.state == NSOnState {
                    switch type {
                    case .PEM, .CER:
                        certificatePasswordTextField.hidden = true
                        certificatePasswordLabel.hidden     = true
                        break
                        
                    case .P12:
                        certificatePasswordTextField.hidden = false
                        certificatePasswordLabel.hidden     = false
                        break
                    }
            } else if xgServerButton.state == NSOnState {
                if type == .P12 {
                    certificatePasswordTextField.hidden = false
                    certificatePasswordLabel.hidden     = false
                } else if type == .PEM {
                } else {
                    showAlert("Invalid certificate!")
                    return
                }
            }
        }
        
    }

    @IBAction func pushMessage(sender: NSButton) {
        if pushDeviceToken.characters.count != deviceTokenLength {
            showAlert("Token string occurs error!")
            return;
        }
        
        var pushPayload:String = ""
        
        if pushMessage.characters.count == 0 {
            showAlert("Push message is empty!")
            return;
        } else {
            let pushMessageDate = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let messageDateString = dateFormatter.stringFromDate(pushMessageDate)
            let message = messageDateString + "\\n" + pushMessage
            pushPayload = "{\"aps\":{\"alert\":\"" + message + "\",\"badge\":1}}"
        }
        
        
        if apnsServerButton.state == NSOnState {
            if self.pushCertificatePath.isEmpty {
                self.showAlert("You never choose a certificate!")
                return
            }
            
            let fileExtension = (pushCertificatePath as NSString).pathExtension
            
            if let type = PushCertificateFileType.init(rawValue: fileExtension.uppercaseString)  {
                switch type {
                case .PEM:
                    let pusher = OCPush()
                    
                    // delete by uweiyuan@2016-12-12
//                    let result = pusher.pushMessageToDeviceToken(pushDeviceToken, payload: pushPayload, fromHost: (pushHost + ":" + String(pushPort)), withPEMFile: pushCertificatePath)
                    let result = pusher.pushMessageToDeviceToken(pushDeviceToken, payload: pushPayload, fromHost: pushHost, port: UInt(pushPort), withPEMFile: pushCertificatePath)
                    if result < -2 {
                        showAlert("Network connection problem!")
                    }
                    if result == -1 || result == -2 {
                        showAlert("Load certificate error!")
                    }
                    
                    if result == 0 {
                        showAlert("Certificate is OK\nPush one message!")
                    }
                    
                    if result == 2 {
                        showAlert("Current network can not connect to apple's push server!")
                    }
                    
                    break
                    
                case .P12:
                    let connectResult = connect()
                    if connectResult == noErr {
                        let pushResult =  OCPush.pushToDeviceToken(pushDeviceToken, payload: pushPayload, context: context)
                        if pushResult == noErr {
                            var enviromentString = ""
                            if developerHostButton.state == NSOnState {
                                enviromentString = "Developer"
                            } else if distributionHostButton.state == NSOnState {
                                enviromentString = "Distribution"
                            }
                            
                            self.convertP12ToPEM(pushCertificatePath, password: pushCertificatePasswd, pemEnviromentString:enviromentString)
                            showAlert("Certificate is OK,Push one message!\nCreate XG Push Certificate done!")
                        } else {
                            showAlert("APNS Error!")
                        }
                    } else {
                        showAlert("Can not connect to APNS")
                    }
                    
                    break
                    
                case .CER:
                    let connectResult = connect()
                    if connectResult == noErr {
                        OCPush.pushToDeviceToken(pushDeviceToken, payload: pushPayload, context: context)
                        showAlert("Certificate is OK,Push one message!")
                    }
                    break
                }
            }
        }
        
        if xgServerButton.state == NSOnState {
            if accessID.characters.count == 0 {
                showAlert("XG Push App acccess ID is incorrect")
                return
            }
            if secretKey.characters.count == 0 {
                showAlert("XG Push App secret key is incorrect")
                return
            }
            if accessID.characters.count == 0 {
                showAlert("XG Push App acccess ID is incorrect")
                return
            }
            
            let path = "" // 取消证书的制作
//            let certificateType = PushCertificateFileType.init(rawValue: (pushCertificatePath as NSString).pathExtension.uppercaseString)!
//            if certificateType == .P12 {
//                var enviromentString = ""
//                if developerHostButton.state == NSOnState {
//                    enviromentString = "Developer"
//                } else if distributionHostButton.state == NSOnState {
//                    enviromentString = "Distribution"
//                }
//                
//                if pushCertificatePasswd.isEmpty {
//                    pushCertificatePasswd = ""
//                }
//                self.convertP12ToPEM(pushCertificatePath, password: pushCertificatePasswd, pemEnviromentString:enviromentString)
//                path = (pushCertificatePath as NSString).stringByDeletingLastPathComponent + "/XG" + enviromentString + "PushCertificate.pem"
//            } else if certificateType == .PEM {
//                path = pushCertificatePath
//            } else {
//                showAlert("Invalid certificate! Please")
//                return
//            }
            
            CertificaterUploader.upload(path, accessID: accessID, xgPushEnviromentIntValue: xgPushEnviromentIntValue, xgPushManagerQQ: xgPushManagerQQ, xgServerState: self.xgTestCheckButton.state, completionHandler: { (result, host, info) in
                if result.boolValue {
                    OCPush.pushFromXGServerWithDeviceToken(self.pushDeviceToken, accessID: self.accessID, secretKey: self.secretKey, payload:pushPayload, enviroment:String(self.apnsPushEnviromentIntValue), server: host, completion: { (message, code) in
                        if code == 0 {
                            self.showAlert("XG Push a message done!")
                        } else {
                            if message.containsString("证书") {
                                self.showAlert("证书存在问题，请检查前端证书是否正确")
                            } else {
                                self.showAlert(message)
                            }
                            
                        }
                    })
                } else {
                    self.showAlert(info!)
                }
            })
        }
    }
    
    @IBAction func chooseHost(sender: NSButton) {
        if sender == developerHostButton {
            pushHost = developerPushHost
            apnsPushEnviromentIntValue = 2
            xgPushEnviromentIntValue   = 1
        }
        if sender == distributionHostButton {
            pushHost = distributePushHost
            apnsPushEnviromentIntValue = 1
            xgPushEnviromentIntValue   = 2
        }
        
    }
    
    @IBAction func chooseServer(sender: NSButton) {
        pushCertificatePathField.stringValue = ""
        certificatePasswordLabel.hidden      = true
        certificatePasswordTextField.hidden  = true
        
        xgPushButtonDisplay()
    }
    
    // MARK:Private
    func connect() -> OSStatus {

        var peer:PeerSpec = PeerSpec(ipAddr: 0, port: 0)
        var result:OSStatus = MakeServerConnection(pushHost, Int32(pushPort), 1, &socket, &peer)
         NSLog("MakeServerConnection(): %d", result);
        if result != noErr {
            return result
        }
        
        
        // Create new SSL context.
        context = SSLCreateContext(kCFAllocatorDefault, SSLProtocolSide.ClientSide, SSLConnectionType.StreamType);
        
        // Set callback functions for SSL context.
        result = SSLSetIOFuncs(context, SocketRead, SocketWrite);
        NSLog("SSLSetIOFuncs(): %d", result);
        
        // Set SSL context connection.
        result = SSLSetConnection(context, socket);
        NSLog("SSLSetConnection(): %d", result);
        
        
        // Set server domain name.
        result = SSLSetPeerDomainName(context, pushHost, 30);
        NSLog("SSLSetPeerDomainName(): %d", result)
        
        
        let fileExtension = (pushCertificatePath as NSString).pathExtension
        let type = PushCertificateFileType.init(rawValue: fileExtension.uppercaseString)
        if type == PushCertificateFileType.CER {
            // Open keychain.
            result = SecKeychainCopyDefault(&keychain);
            NSLog("SecKeychainOpen(): %d", result);
        }
        
        var certificates:CFArrayRef!
        if type == PushCertificateFileType.CER {
            let certificateData = NSData(contentsOfFile: pushCertificatePath);
            self.certificate = SecCertificateCreateWithData(kCFAllocatorDefault, certificateData!)
            if self.certificate == nil {
                return errSecCertificateCannotOperate
            }
            // Create identity.
            result = SecIdentityCreateWithCertificate(keychain, certificate!, &identity);
            NSLog("SecIdentityCreateWithCertificate(): %d", result);
            var id:UnsafePointer<Void> = UnsafePointer(Unmanaged.passUnretained(identity!).toOpaque())
            
            // Set client certificate.
            certificates = CFArrayCreate(nil, &id, 1, nil)
        }
        
        if type == PushCertificateFileType.P12 {
            // Set client certificate.
            let identity = OCPush.getSecIdentityRefFromFile(pushCertificatePath, password: pushCertificatePasswd, statusCode: &result)
            
            if result == noErr {
                certificates = identity.takeRetainedValue()
            } else {
                if result == errSecPkcs12VerifyFailure {
                    showAlert("Incorrect password for PKCS12!")
                }
                if result == errSecDecode {
                    showAlert("Can not parse certificate!")
                }
            }
        }

        if (certificates != nil) {
            result = SSLSetCertificate(context, certificates);
            NSLog("SSLSetCertificate(): %d", result);
            result = SSLHandshake(context);
            // Perform SSL handshake.
            while(result == errSSLWouldBlock) {
                result = SSLHandshake(context);
                NSLog("SSLHandshake(): %d", result);
            }
        }
        
        return result
    }
    
    
    func disconnect() -> Void {
        if(self.certificate == nil) {
            return
        }
        // Define result variable.
        let result:OSStatus = SSLClose(context)
        NSLog("SSLClose(): %d", result)
        
        // Close connection to server.
        OCPush.closeSocket(socket)
    }
    func showAlert(message:String) -> Void {
		dispatch_async(dispatch_get_main_queue()) {
	        let alert = NSAlert()
	        alert.messageText = message
	        alert.runModal()
		}
    }
    
    // MARK: NSTextFiledDelegate
    override func controlTextDidChange(obj: NSNotification) {
        let textField:NSTextField = obj.object as! NSTextField
        if textField == pushMessageTextField {
            pushMessage = textField.stringValue
        }
        if textField == pushTokenTextField {
            pushDeviceToken = textField.stringValue
            NSUserDefaults.standardUserDefaults().setObject(pushDeviceToken, forKey: XGiOSToken)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        if textField == certificatePasswordTextField {
            pushCertificatePasswd = textField.stringValue
        }
        
        if textField == accessIDTextField {
            accessID = textField.stringValue
            NSUserDefaults.standardUserDefaults().setObject(accessID, forKey: XGAccessIDKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        if textField == secretKeyTextFiled {
            secretKey = textField.stringValue
            NSUserDefaults.standardUserDefaults().setObject(secretKey, forKey: XGSecretKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        if textField == managerQQTextField {
            xgPushManagerQQ = textField.stringValue
            NSUserDefaults.standardUserDefaults().setObject(xgPushManagerQQ, forKey: XGAccountQQKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
    }
    
    
    
    func shell(input: String) -> (output: String, exitCode: Int32) {
        let arguments = input.characters.split { $0 == " " }.map(String.init)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = arguments
        task.environment = [
            "LC_ALL" : "en_US.UTF-8",
            "HOME" : NSHomeDirectory()
        ]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        
        return (output, task.terminationStatus)
    }
    

    func xgPushButtonDisplay() -> Void {
        let state = Bool.init(apnsServerButton.state)
        acccessIDLabel.hidden     = state
        accessIDTextField.hidden  = state
        secretKeyLabel.hidden     = state
        secretKeyTextFiled.hidden = state
        managerQQLabel.hidden     = state
        managerQQTextField.hidden = state
        xgTestCheckButton.hidden  = state
        certificateTitleLabel.hidden = !state
        pushCertificatePathField.hidden = !state
        chooseCertificateButton.hidden  = !state
    }
    
    func md5(string: String) -> String {
        var digest:[UInt8] = [UInt8](count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        CC_MD5(data!.bytes, CC_LONG(data!.length), &digest)
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
    
    
    override func mouseEntered(theEvent: NSEvent) {
        print("area rect = \(NSEvent.mouseLocation())")
        if pushCertificatePath.characters.count == 0 {
            pushCertificatePathField.placeholderString = "Upload your push certificate"
        }
        
    }
    override func mouseExited(theEvent: NSEvent) {
        pushCertificatePathField.placeholderString = nil
    }
    
    func convertP12ToPEM(filePath:String, password:String, pemEnviromentString:String) -> Void {
        let pemOutPath = (filePath as NSString).stringByDeletingLastPathComponent
        var shellString = "openssl pkcs12 -in " + filePath + " -out " + pemOutPath + "/XG" + pemEnviromentString + "PushCertificate.pem -nodes "
        if !password.isEmpty {
            shellString = shellString + "-passin pass:" + password
        }
        shell(shellString)
    }
}

