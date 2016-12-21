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
    
    
    
    fileprivate var socket:otSocket? = nil
    fileprivate var context:SSLContext!
    fileprivate var keychain:SecKeychain?
    fileprivate var certificate:SecCertificate?
    fileprivate var identity:SecIdentity?
    fileprivate var pushDeviceToken:String!
//    private var pushPayload:String     = ""
    fileprivate var pushMessage:String     = ""
    fileprivate var pushCertificatePath    = ""
    fileprivate var pushCertificatePasswd  = ""
    fileprivate var pushHost               = ""
    // 1: distribution 2:developement
    fileprivate var apnsPushEnviromentIntValue:UInt = 2
    fileprivate var accessID:String!
    fileprivate var secretKey:String!
    
    // 2: distribution 1:developement
    fileprivate var xgPushEnviromentIntValue:UInt = 1
    fileprivate var xgPushManagerQQ:String!
    fileprivate var mouseTrackingArea:NSTrackingArea!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        certificatePasswordTextField.isHidden = true
        certificatePasswordLabel.isHidden     = true
        xgTestCheckButton.isHidden            = true
        if developerHostButton.state == 1 {
            pushHost = developerPushHost
        }
        if distributionHostButton.state == 1 {
            pushHost = distributePushHost
        }
        
        xgPushButtonDisplay()
        
        mouseTrackingArea = NSTrackingArea(rect: chooseCertificateButton.frame, options:[.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: ["key":"value"])
        self.view.addTrackingArea(mouseTrackingArea)
         pushDeviceToken = UserDefaults.standard.object(forKey: XGiOSToken) as? String
        if pushDeviceToken != nil {
            pushTokenTextField.stringValue = pushDeviceToken
        }
        accessID = UserDefaults.standard.object(forKey: XGAccessIDKey) as? String
        if accessID != nil {
            accessIDTextField.stringValue = accessID
        }
        secretKey = UserDefaults.standard.object(forKey: XGSecretKey) as? String
        if secretKey != nil {
            secretKeyTextFiled.stringValue = secretKey
        }
        xgPushManagerQQ = UserDefaults.standard.object(forKey: XGAccountQQKey) as? String
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
    
    @IBAction func uploadCertificate(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.message = ""
        panel.prompt = "OK"
        panel.canChooseDirectories = true
        panel.canChooseFiles       = true
        panel.canCreateDirectories = false
        var path:NSString = ""
        let result = panel.runModal()
        if result == NSFileHandlingPanelOKButton {
            path = (panel.url?.path)! as NSString
            
            // 判断是否选了文件
            var isDirectory:ObjCBool = false
            if FileManager.default.fileExists(atPath: path as String, isDirectory: &isDirectory) {
                if isDirectory.boolValue == true {
                    return
                }
            }
            pushCertificatePathField.stringValue = path as String
            pushCertificatePath = path as String
            let type = PushCertificateFileType.init(rawValue: path.pathExtension.uppercased())!
            if apnsServerButton.state == NSOnState {
                    switch type {
                    case .PEM, .CER:
                        certificatePasswordTextField.isHidden = true
                        certificatePasswordLabel.isHidden     = true
                        break
                        
                    case .P12:
                        certificatePasswordTextField.isHidden = false
                        certificatePasswordLabel.isHidden     = false
                        break
                    }
            } else if xgServerButton.state == NSOnState {
                if type == .P12 {
                    certificatePasswordTextField.isHidden = false
                    certificatePasswordLabel.isHidden     = false
                } else if type == .PEM {
                } else {
                    showAlert("Invalid certificate!")
                    return
                }
            }
        }
        
    }

    @IBAction func pushMessage(_ sender: NSButton) {
        if pushDeviceToken.characters.count != deviceTokenLength {
            showAlert("Token string occurs error!")
            return;
        }
        
        var pushPayload:String = ""
        
        if pushMessage.characters.count == 0 {
            showAlert("Push message is empty!")
            return;
        } else {
            let pushMessageDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let messageDateString = dateFormatter.string(from: pushMessageDate)
            let message = messageDateString + "\\n" + pushMessage
            pushPayload = "{\"aps\":{\"alert\":\"" + message + "\",\"badge\":1}}"
        }
        
        
        if apnsServerButton.state == NSOnState {
            if self.pushCertificatePath.isEmpty {
                self.showAlert("You never choose a certificate!")
                return
            }
            
            let fileExtension = (pushCertificatePath as NSString).pathExtension
            
            if let type = PushCertificateFileType.init(rawValue: fileExtension.uppercased())  {
                switch type {
                case .PEM:
                    let pusher = OCPush()
                    
                    // delete by uweiyuan@2016-12-12
//                    let result = pusher.pushMessageToDeviceToken(pushDeviceToken, payload: pushPayload, fromHost: (pushHost + ":" + String(pushPort)), withPEMFile: pushCertificatePath)
                    let result = pusher.pushMessage(toDeviceToken: pushDeviceToken, payload: pushPayload, fromHost: pushHost, port: UInt(pushPort), withPEMFile: pushCertificatePath)
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
                        let pushResult =  OCPush.push(toDeviceToken: pushDeviceToken, payload: pushPayload, context: context)
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
                        OCPush.push(toDeviceToken: pushDeviceToken, payload: pushPayload, context: context)
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
                if result {
                    OCPush.pushFromXGServer(withDeviceToken: self.pushDeviceToken, accessID: self.accessID, secretKey: self.secretKey, payload:pushPayload, enviroment:String(self.apnsPushEnviromentIntValue), server: host, completion: { (message, code) in
                        if code == 0 {
                            self.showAlert("XG Push a message done!")
                        } else {
                            if message != nil {
                                if message!.contains("证书") == true {
                                    self.showAlert("证书存在问题，请检查前端证书是否正确")
                                } else {
                                    self.showAlert(message!)
                                }
                            }
                            
                            
                        }
                    })
                } else {
                    self.showAlert(info!)
                }
            })
        }
    }
    
    @IBAction func chooseHost(_ sender: NSButton) {
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
    
    @IBAction func chooseServer(_ sender: NSButton) {
        pushCertificatePathField.stringValue = ""
        certificatePasswordLabel.isHidden      = true
        certificatePasswordTextField.isHidden  = true
        
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
        context = SSLCreateContext(kCFAllocatorDefault, SSLProtocolSide.clientSide, SSLConnectionType.streamType);
        
        // Set callback functions for SSL context.
        let read:SSLReadFunc = { con, data, length in
            IOSocket.socketReadOC(con, data: data, length: length)
        }
        let write:SSLWriteFunc = { con, data, length in
            IOSocket.socketWriteOC(con, data: data, length: length)
        }
        result = SSLSetIOFuncs(context, read, write);
        NSLog("SSLSetIOFuncs(): %d", result);
        
        // Set SSL context connection.
        result = SSLSetConnection(context, socket);
        NSLog("SSLSetConnection(): %d", result);
        
        
        // Set server domain name.
        result = SSLSetPeerDomainName(context, pushHost, 30);
        NSLog("SSLSetPeerDomainName(): %d", result)
        
        
        let fileExtension = (pushCertificatePath as NSString).pathExtension
        let type = PushCertificateFileType.init(rawValue: fileExtension.uppercased())
        if type == PushCertificateFileType.CER {
            // Open keychain.
            result = SecKeychainCopyDefault(&keychain);
            NSLog("SecKeychainOpen(): %d", result);
        }
        
        var certificates:CFArray!
        
        if type == PushCertificateFileType.CER {
            let certificateData = try? Data(contentsOf: URL(fileURLWithPath: pushCertificatePath));
            self.certificate = SecCertificateCreateWithData(kCFAllocatorDefault, certificateData! as CFData)
            if self.certificate == nil {
                return errSecCertificateCannotOperate
            }
            // Create identity.
            result = SecIdentityCreateWithCertificate(keychain, certificate!, &identity);
            NSLog("SecIdentityCreateWithCertificate(): %d", result);
            
            let cerData = Unmanaged.passUnretained(identity!).toOpaque()
            let certificateDatas:CFMutableArray = CFArrayCreateMutable(kCFAllocatorDefault , 0, nil)
            CFArraySetValueAtIndex(certificateDatas, 0, cerData)
            certificates = certificateDatas as CFArray
            
//            var id:UnsafeRawPointer = UnsafePointer(Unmanaged.passUnretained(identity!).toOpaque())
            // Set client certificate.
//            certificates = CFArrayCreate(nil, &id, 1, nil)
        }
        
        if type == PushCertificateFileType.P12 {
            // Set client certificate.
            let identity = OCPush.getSecIdentityRef(fromFile: pushCertificatePath, password: pushCertificatePasswd, statusCode: &result)
            
            if result == noErr {
                certificates = identity?.takeRetainedValue()
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
    func showAlert(_ message:String) -> Void {
		DispatchQueue.main.async {
	        let alert = NSAlert()
	        alert.messageText = message
	        alert.runModal()
		}
    }
    
    // MARK: NSTextFiledDelegate
    override func controlTextDidChange(_ obj: Notification) {
        let textField:NSTextField = obj.object as! NSTextField
        if textField == pushMessageTextField {
            pushMessage = textField.stringValue
        }
        if textField == pushTokenTextField {
            pushDeviceToken = textField.stringValue
            UserDefaults.standard.set(pushDeviceToken, forKey: XGiOSToken)
            UserDefaults.standard.synchronize()
        }
        
        if textField == certificatePasswordTextField {
            pushCertificatePasswd = textField.stringValue
        }
        
        if textField == accessIDTextField {
            accessID = textField.stringValue
            UserDefaults.standard.set(accessID, forKey: XGAccessIDKey)
            UserDefaults.standard.synchronize()
        }
        if textField == secretKeyTextFiled {
            secretKey = textField.stringValue
            UserDefaults.standard.set(secretKey, forKey: XGSecretKey)
            UserDefaults.standard.synchronize()
        }
        if textField == managerQQTextField {
            xgPushManagerQQ = textField.stringValue
            UserDefaults.standard.set(xgPushManagerQQ, forKey: XGAccountQQKey)
            UserDefaults.standard.synchronize()
        }
        
    }
    
    
    
    func shell(_ input: String) -> (output: String, exitCode: Int32) {
        let arguments = input.characters.split { $0 == " " }.map(String.init)
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = arguments
        task.environment = [
            "LC_ALL" : "en_US.UTF-8",
            "HOME" : NSHomeDirectory()
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        
        return (output, task.terminationStatus)
    }
    

    func xgPushButtonDisplay() -> Void {
        let state = Bool.init(NSNumber(value:apnsServerButton.state))
        acccessIDLabel.isHidden     = state
        accessIDTextField.isHidden  = state
        secretKeyLabel.isHidden     = state
        secretKeyTextFiled.isHidden = state
        managerQQLabel.isHidden     = state
        managerQQTextField.isHidden = state
        xgTestCheckButton.isHidden  = state
        certificateTitleLabel.isHidden = !state
        pushCertificatePathField.isHidden = !state
        chooseCertificateButton.isHidden  = !state
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        print("area rect = \(NSEvent.mouseLocation())")
        if pushCertificatePath.characters.count == 0 {
            pushCertificatePathField.placeholderString = "Upload your push certificate"
        }
        
    }
    override func mouseExited(with theEvent: NSEvent) {
        pushCertificatePathField.placeholderString = nil
    }
    
    func convertP12ToPEM(_ filePath:String, password:String, pemEnviromentString:String) -> Void {
        let pemOutPath = (filePath as NSString).deletingLastPathComponent
        var shellString = "openssl pkcs12 -in " + filePath + " -out " + pemOutPath + "/XG" + pemEnviromentString + "PushCertificate.pem -nodes "
        if !password.isEmpty {
            shellString = shellString + "-passin pass:" + password
        }
        shell(shellString)
    }
}

