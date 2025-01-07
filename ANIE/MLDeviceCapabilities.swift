import CoreML

struct MLDeviceCapabilities {
    static var hasANE: Bool {
        if #available(iOS 14.0, macOS 11.0, *) {
            // Check if neural engine is supported in the current compute units
            let supportedUnits = MLComputeUnits.all
            return supportedUnits.rawValue & MLComputeUnits.cpuAndNeuralEngine.rawValue != 0
        }
        return false
    }
    
    static func getOptimalComputeUnits() -> MLComputeUnits {
        if hasANE {
            return .all
        }
        return .cpuAndGPU
    }
    
    // Add debug method
    static func debugComputeInfo() {
        print("ANE Available: \(hasANE)")
        print("Optimal Compute Units: \(getOptimalComputeUnits())")
        
        if #available(iOS 14.0, macOS 11.0, *) {
            print("Supported Units: \(MLComputeUnits.all)")
        }
    }
} 