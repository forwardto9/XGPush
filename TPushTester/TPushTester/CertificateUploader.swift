//
//  CertificateUploader.swift
//  TPushTester
//
//  Created by uwei on 12/12/2016.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Foundation

open class CertificaterUploader:NSObject {
    class func upload(_ path:String, accessID:String, xgPushEnviromentIntValue:UInt, xgPushManagerQQ:String, xgServerState:Int, completionHandler:@escaping (_ result:Bool, _ host:String?, _ info:String?) -> Void) -> Void {
        var xgHost:String = ""
        if xgServerState == 1 {
            xgHost = "testopenapi.xg.qq.com"
            
        } else {
            xgHost = "openapi.xg.qq.com"
        }
        completionHandler(true, xgHost, "OK")
        
        return
        
        
        
        let certificateData = (try? Data.init(contentsOf: URL(fileURLWithPath: path as String)))?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        let ts = String(time(nil))
        let type = String(xgPushEnviromentIntValue)
        var sign  = "!#dataeye*&@!23ne5=^82"
        let source = "dataeye" // defualt, juhe, cmstop,etc.
        var paramsWithOutCertificate = ["app_id":accessID, "type":type, "qq":xgPushManagerQQ, "source":source, "ts":ts]
        let p  = paramsWithOutCertificate.sorted {$0.0 < $1.0}
        for (k, v) in p {
            sign = sign + k + "=" + v
        }
        let sig = CertificaterUploader.md5(sign)
        
        paramsWithOutCertificate["sig"] = sig
        paramsWithOutCertificate["certfile"] = certificateData!
        let xgCertificateUploadURL = "http://api.xg.qq.com/certfile/update_apns_cert_pub"
        let request = NSMutableURLRequest(url: URL(string: xgCertificateUploadURL)!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 30)
        request.httpMethod  = "POST"
        var parameterString = ""
        for (k, v) in paramsWithOutCertificate {
            parameterString = parameterString + k + "=" + v + "&"
        }
        
        parameterString = (parameterString as NSString).substring(to: parameterString.characters.count - 1)
        request.httpBody = parameterString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if data != nil {
                let returnData = try! JSONSerialization.jsonObject(with: data!, options:.mutableContainers) as! [String:Any]
                var uploadResultInfo = ""
                if (returnData["code"] as! NSNumber).intValue == 0 {
                    var xgHost:String!
                    if xgServerState == 1 {
                        xgHost = "testopenapi.xg.qq.com"
                        
                    } else {
                        xgHost = "openapi.xg.qq.com"
                    }
                    completionHandler(true, xgHost, "OK")
                } else {
                    uploadResultInfo = returnData["info"] as! String
                    completionHandler(false, nil, uploadResultInfo)
                }
            }
        }).resume()
    }



class func md5(_ string: String) -> String {
    var digest:[UInt8] = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    let data = (string as NSString).data(using: String.Encoding.utf8.rawValue)
    CC_MD5((data! as NSData).bytes, CC_LONG(data!.count), &digest)
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
}
}
