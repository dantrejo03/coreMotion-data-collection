//
//  CMQuaternionExtension.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 6/26/25.
//

import CoreMotion
import simd

extension CMQuaternion {
    
    func tosimd() -> simd_quatd {
        return simd_quatd(ix: x, iy: y, iz: z, r: w)
    }
    
    var asArray: [Double] {
        return [w, x, y, z]
    }

}
