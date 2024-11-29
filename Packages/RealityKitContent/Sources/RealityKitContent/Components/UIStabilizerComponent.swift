struct UIStabilizerComponent: Component {
    var offset: SIMD3<Float>  // Offset from parent's center
    var worldUp: SIMD3<Float> = [0, 1, 0]  // Keep UI oriented up
}