//
//  AppModel+AssetLoading.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//

extension AppModel {
    // MARK: - Asset Loading
    
            var isLoadingAssets: Bool {
                if case .loading = assetLoadingManager.state {
                    return true
                }
                return false
            }
            
            var assetsLoaded: Bool {
                if case .completed = assetLoadingManager.state {
                    return true
                }
                return false
            }
            

            
            func startLoading() async {
                isLoading = true
                do {
                    // Start progress monitoring
                    Task {
                        while assetLoadingManager.loadingProgress() < 1.0 {
                            loadingProgress = assetLoadingManager.loadingProgress()
                            try? await Task.sleep(nanoseconds: 100_000_000)
                        }
                        loadingProgress = assetLoadingManager.loadingProgress()
                    }
                    
                    try await assetLoadingManager.loadAssets()
                    isLoading = false
                    await transitionToPhase(.intro)

                } catch {
                    print("Error loading assets: \(error)")
                    isLoading = false

                    // Handle error by setting gamePhase or presenting an error message
                    currentPhase = .error
                }
            }

}
