//
//  simd_quatd_extension.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 6/26/25.
//

import CoreMotion
import Foundation
import simd

extension simd_quatd {
    func toCMQuaternion() -> CMQuaternion {
        return CMQuaternion(x: imag.x, y: imag.y, z: imag.z, w: real)
    }
}
