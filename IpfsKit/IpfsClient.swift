/*****
 MIT License
 
 Copyright (c) 2017 ProVivus Health AB
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 *****/

import SwiftIpfsApi
import SwiftMultihash
import SwiftBase58
import SwiftHex
import PromiseKit

public class IpfsClient {
    
    var ipfsApi:IpfsApi?
    
    public init?(ipfsHost: String) {
        do {
            self.ipfsApi = try IpfsApi(host: ipfsHost, port: 5001)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func putBytes(bytes: [UInt8]) -> Promise<Multihash>
    {
        return Promise<Multihash> { fulfill, reject in
            do {
                try ipfsApi?.block.put(bytes, completionHandler: { (merkleNode) in
                    fulfill(merkleNode.hash!)
                })
            } catch {
                reject(error)
            }
        }
    }
    
    public func getFile(hash: String) -> Promise<Dictionary<String, Any>>
    {
        return Promise<Dictionary<String, Any>> { fulfill, reject in
            do {
                let multihash = try fromB58String(hash)
                try self.ipfsApi?.get(multihash, completionHandler: { (array) in
                    let str = String(bytes: array, encoding: .utf8)
                    let dict = str?.toDictionary()!
                    fulfill(dict!)
                })
            } catch {
                print("Failed get: \(hash), Error: " + error.localizedDescription)
            }
        }
    }
    
    public func putFile(fileURL: URL) -> Promise<Multihash>
    {
        return Promise<Multihash> { fulfill, reject in
            do {
                try ipfsApi?.add(fileURL.absoluteString, completionHandler: { (merkleNodes) in
                    fulfill(merkleNodes[0].hash!)
                })
            } catch {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }
        }
    }
    
    public func putObject(object: Data) -> Promise<Multihash>
    {
        return Promise<Multihash> { fulfill, reject in
            do {
                try ipfsApi?.block.put(Array(object), completionHandler: { (merkleNode) in
                    fulfill(merkleNode.hash!)
                })
            } catch {
                reject(error)
            }
        }
    }
}

extension String {
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

