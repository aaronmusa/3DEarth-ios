//
//  ViewController.swift
//  3DEarth
//
//  Created by Aaron Musa on 6/12/23.
//

import UIKit
@_spi(Experimental) import MapboxMaps

class ViewController: UIViewController {
    
    @IBOutlet private(set) var resetCameraButton: UIButton! {
        didSet {
            resetCameraButton.isHidden = true
        }
    }
    
    private var mapView: MapView!
    
    private let pinnedCoordinates: [CLLocationCoordinate2D] = [
        .init(latitude: 35.36093601891445, longitude: 138.72395921727045)
    ]
    
    private lazy var defaultCameraState: CameraState = {
        .init(
            center: pinnedCoordinates.first ?? .init(latitude: 0, longitude: 0),
            padding: .zero,
            zoom: 0,
            bearing: .zero,
            pitch: 0
        )
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
    }
    
    @IBAction func didTapResetCamera() {
        if let location = mapView.location.latestLocation {
            setCamera(to: location.coordinate, duration: 1.5)
        }
    }
}

// MARK: - Methods
extension ViewController {
    func setupMap() {
        let resourceOptions = ResourceOptions(accessToken: AppSecret.defaultAccessToken)
        let mapOptions = MapInitOptions(
            resourceOptions: resourceOptions,
            cameraOptions: .init(
                cameraState: defaultCameraState
            ),
            styleURI: .outdoors
        )
        mapView = MapView(frame: view.bounds, mapInitOptions: mapOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(mapView)
        view.bringSubviewToFront(resetCameraButton)
        
        mapView.location.delegate = self
        mapView.location.options.puckType = .puck2D()
        
        try? mapView.mapboxMap.setMapProjection(.globe())
        
        setMapEvents()
    }
    
    func setMapEvents() {
        mapView.mapboxMap.onNext(.mapLoaded, handler: { [weak self] _ in
            guard let self = self else { return }

            self.requestLocationPermission()
        })
    }
    
    func setInitialCameraPosition(with locationManager: LocationManager) {
        let coordinates = locationManager.latestLocation?.coordinate ?? defaultCameraState.center
        resetCameraButton.isHidden = false
        setAnnotations()
        setCamera(to: coordinates)
    }
    
    func requestLocationPermission() {
        guard let latestLocation = mapView.location.latestLocation else {
            mapView.location.requestTemporaryFullAccuracyPermissions(withPurposeKey: "CustomKey")
            return
        }
        
        resetCameraButton.isHidden = false
        setAnnotations()
        setCamera(to: latestLocation.coordinate)
    }
    
    func setCamera(
        to coordinates: CLLocationCoordinate2D,
        zoomLevel: CGFloat = 7,
        duration: TimeInterval = 3.0,
        animated: Bool = true
    ) {
        defaultCameraState.center = coordinates
        defaultCameraState.zoom = zoomLevel
        mapView.camera.ease(to: .init(cameraState: defaultCameraState), duration: duration)
    }
    
    func setAnnotations() {
        let annotations = pinnedCoordinates.map { coordinate -> PointAnnotation in
            var pointAnnotation = PointAnnotation(coordinate: coordinate)
            pointAnnotation.image = .init(image: .init(named: "red_pin")!, name: "red_pin")
            pointAnnotation.iconAnchor = .bottom
            return pointAnnotation
        }
        
        let manager = mapView.annotations.makePointAnnotationManager()
        manager.annotations = annotations
    }
}


extension ViewController: LocationPermissionsDelegate {
    func locationManager(_ locationManager: LocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            guard let self = self else { return }
            self.setInitialCameraPosition(with: locationManager)
        })
    }
}

