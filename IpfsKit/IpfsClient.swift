import PromiseKit
import SwiftIpfsApi
import SwiftMultihash
import SwiftBase58
import SwiftHex

public class IpfsClient {
    
    var ipfsApi:IpfsApi?
    
    init?(ipfsHost: String) {
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

