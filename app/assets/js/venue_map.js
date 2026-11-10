// Alpine component (CSP build) for the venue search map.
//
// The CSP-friendly Alpine build evaluates no strings as JS, so directives only reference
// registered components, properties, getters and methods — never inline expressions. Config
// is read from data-* attributes in init(). Leaflet is loaded globally (window.L) via <script>
// tags; its instances live in closure variables so Alpine's proxy never wraps them.
export default function venueMap() {
  let map = null;
  let userMarker = null;
  let venueMarkers = null;
  let drawnItems = null;
  let bufferLayer = null;
  let currentSearchShape = null;
  let currentLayerType = null;
  let searchTimeout = null;

  const cfg = {};
  const t = {};

  return {
    buffer: 500,
    currentLocation: null,
    lastSearchData: null,
    statusMessage: "",
    statusType: "loading",
    statusVisible: false,

    get bufferLabel() {
      return this.buffer >= 1000 ? `${(this.buffer / 1000).toFixed(1)} km` : `${this.buffer} m`;
    },

    get isError() {
      return this.statusType === "error";
    },

    get statusClass() {
      return this.statusType ? `map-status--${this.statusType}` : "";
    },

    init() {
      const d = this.$el.dataset;
      cfg.defaultLat = parseFloat(d.defaultLat);
      cfg.defaultLng = parseFloat(d.defaultLng);
      cfg.apiUrl = d.apiUrl;
      this.buffer = parseInt(d.buffer, 10);
      t.searching = d.tSearching;
      t.noVenues = d.tNoVenues;
      t.venuesFound = d.tVenuesFound;
      t.youAreHere = d.tYouAreHere;
      t.requestingLocation = d.tRequestingLocation;
      t.fallback = d.tFallback;
      t.source = d.tSource;
      t.updatedToday = d.tUpdatedToday;
      t.updatedDaysAgo = d.tUpdatedDaysAgo;

      this.initMap();
      this.initDrawControls();
      this.$watch("buffer", () => this.debouncedSearch());
      this.requestGeolocation();
    },

    destroy() {
      if (map) map.remove();
    },

    initMap() {
      map = L.map(this.$refs.container, { zoomControl: true })
        .setView([cfg.defaultLat, cfg.defaultLng], 13);

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19
      }).addTo(map);

      venueMarkers = L.layerGroup().addTo(map);
      drawnItems = new L.FeatureGroup().addTo(map);
    },

    initDrawControls() {
      const drawControl = new L.Control.Draw({
        position: "topright",
        draw: {
          marker: { icon: this.createSearchMarkerIcon() },
          polygon: {
            allowIntersection: false,
            showArea: true,
            shapeOptions: { color: "#3388ff", weight: 2, fillOpacity: 0.2 }
          },
          polyline: { shapeOptions: { color: "#3388ff", weight: 3 } },
          circle: false,
          circlemarker: false,
          rectangle: false
        },
        edit: { featureGroup: drawnItems, remove: true, edit: false }
      });

      map.addControl(drawControl);
      map.on(L.Draw.Event.CREATED, (event) => this.handleDrawCreated(event));
      map.on(L.Draw.Event.DELETED, () => this.handleDrawDeleted());
    },

    handleDrawCreated(event) {
      const layer = event.layer;
      const layerType = event.layerType;

      this.clearPreviousSearchShape();
      drawnItems.addLayer(layer);
      currentSearchShape = layer;
      currentLayerType = layerType;

      this.performSearch(this.extractSearchData(layer, layerType));
    },

    handleDrawDeleted() {
      currentSearchShape = null;
      this.clearVenueMarkers();
    },

    clearPreviousSearchShape() {
      if (currentSearchShape) {
        drawnItems.removeLayer(currentSearchShape);
        currentSearchShape = null;
      }
      this.clearBufferVisualization();
      this.clearVenueMarkers();
    },

    clearBufferVisualization() {
      if (bufferLayer) {
        map.removeLayer(bufferLayer);
        bufferLayer = null;
      }
    },

    drawBufferFromGeoJSON(bufferGeometry) {
      this.clearBufferVisualization();
      if (!bufferGeometry) return;

      bufferLayer = L.geoJSON(bufferGeometry, {
        style: {
          color: "#3388ff",
          weight: 1,
          opacity: 0.5,
          fillColor: "#3388ff",
          fillOpacity: 0.1,
          dashArray: "5, 5"
        }
      }).addTo(map);
    },

    clearVenueMarkers() {
      venueMarkers.clearLayers();
    },

    extractSearchData(layer, layerType) {
      switch (layerType) {
        case "marker": {
          const latlng = layer.getLatLng();
          return { type: "point", lat: latlng.lat, lng: latlng.lng };
        }
        case "polygon":
          return { type: "polygon", polygon: JSON.stringify(layer.toGeoJSON().geometry) };
        case "polyline":
          return { type: "line", line: JSON.stringify(layer.toGeoJSON().geometry) };
        default:
          return null;
      }
    },

    performInitialSearch(lat, lng) {
      this.currentLocation = { lat, lng };
      this.performSearch({ type: "point", lat, lng });
    },

    async performSearch(searchData) {
      if (!searchData) return;

      this.showStatus(t.searching, "loading");

      try {
        let url = cfg.apiUrl;
        const buffer = this.buffer;

        if (searchData.type === "point") {
          url += `?lat=${searchData.lat}&lng=${searchData.lng}&buffer=${buffer}`;
        } else if (searchData.type === "polygon") {
          url += `?polygon=${encodeURIComponent(searchData.polygon)}&buffer=${buffer}`;
        } else if (searchData.type === "line") {
          url += `?line=${encodeURIComponent(searchData.line)}&buffer=${buffer}`;
        }

        const response = await fetch(url);
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || "Search failed");

        this.displaySearchResults(data);
      } catch (error) {
        this.lastSearchData = searchData;
        this.showError(error.message);
      }
    },

    retrySearch() {
      if (this.lastSearchData) this.performSearch(this.lastSearchData);
    },

    displaySearchResults(data) {
      this.clearVenueMarkers();

      if (data.meta && data.meta.buffer_geometry) {
        this.drawBufferFromGeoJSON(data.meta.buffer_geometry);
      }

      const venues = data.data || [];
      if (venues.length === 0) {
        this.showStatus(t.noVenues, "info");
        setTimeout(() => this.hideStatus(), 3000);
        return;
      }

      venues.forEach((venue) => {
        const marker = L.marker([venue.latitude, venue.longitude], { icon: this.createVenueMarkerIcon() });
        const distance = venue.distance_meters ? `${(venue.distance_meters / 1000).toFixed(1)} km` : "";
        const source = venue.source ? `<br><span class="source">${t.source}: ${venue.source}</span>` : "";
        const dataAge = this.formatDataAge(venue.fetched_at);

        marker.bindPopup(`
          <div class="venue-popup">
            <strong>${venue.name}</strong><br>
            <span class="sport-type">${venue.sport_type}</span>
            ${distance ? `<br><span class="distance">${distance}</span>` : ""}
            ${source}
            ${dataAge ? `<br><span class="data-age">${dataAge}</span>` : ""}
          </div>
        `);
        venueMarkers.addLayer(marker);
      });

      this.showStatus((t.venuesFound || "Found __COUNT__ venues").replace("__COUNT__", venues.length), "success");
      setTimeout(() => this.hideStatus(), 3000);
    },

    // Human-friendly data age from the venue's fetched_at (Principle V: visible freshness).
    formatDataAge(fetchedAt) {
      if (!fetchedAt) return "";
      const fetched = new Date(fetchedAt);
      if (isNaN(fetched.getTime())) return "";

      const days = Math.floor((Date.now() - fetched.getTime()) / 86400000);
      if (days <= 0) return t.updatedToday;
      return (t.updatedDaysAgo || "Updated __COUNT__ days ago").replace("__COUNT__", days);
    },

    createSearchMarkerIcon() {
      return L.divIcon({
        className: "search-marker",
        html: '<div class="search-marker-inner"></div>',
        iconSize: [24, 24],
        iconAnchor: [12, 12]
      });
    },

    createVenueMarkerIcon() {
      return L.divIcon({
        className: "venue-marker",
        html: '<div class="venue-marker-inner"></div>',
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      });
    },

    requestGeolocation() {
      if (!navigator.geolocation) {
        this.useDefaultLocation("Geolocation not supported by browser");
        return;
      }

      this.showStatus(t.requestingLocation, "loading");
      navigator.geolocation.getCurrentPosition(
        (position) => this.handleGeolocationSuccess(position),
        (error) => this.handleGeolocationError(error),
        { enableHighAccuracy: false, timeout: 10000, maximumAge: 300000 }
      );
    },

    handleGeolocationSuccess(position) {
      const { latitude, longitude } = position.coords;
      map.setView([latitude, longitude], 14);

      if (userMarker) {
        userMarker.setLatLng([latitude, longitude]);
      } else {
        userMarker = L.marker([latitude, longitude], { icon: this.createUserIcon() }).addTo(map);
        userMarker.bindPopup(t.youAreHere).openPopup();
      }

      this.hideStatus();
      this.performInitialSearch(latitude, longitude);
    },

    handleGeolocationError(error) {
      let message = "Location unavailable";
      switch (error.code) {
        case error.PERMISSION_DENIED:
          message = "Location permission denied";
          break;
        case error.POSITION_UNAVAILABLE:
          message = "Location information unavailable";
          break;
        case error.TIMEOUT:
          message = "Location request timed out";
          break;
      }
      this.useDefaultLocation(message);
    },

    useDefaultLocation(reason) {
      map.setView([cfg.defaultLat, cfg.defaultLng], 13);
      this.showStatus((t.fallback || "__REASON__. Showing York, UK.").replace("__REASON__", reason), "info");
      setTimeout(() => this.hideStatus(), 5000);
      this.performInitialSearch(cfg.defaultLat, cfg.defaultLng);
    },

    createUserIcon() {
      return L.divIcon({
        className: "user-location-marker",
        html: '<div class="pulse"></div>',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });
    },

    showStatus(message, type = "loading") {
      this.statusMessage = message;
      this.statusType = type;
      this.statusVisible = true;
    },

    hideStatus() {
      this.statusVisible = false;
    },

    showError(message) {
      this.showStatus(message, "error");
    },

    debouncedSearch() {
      if (searchTimeout) clearTimeout(searchTimeout);

      searchTimeout = setTimeout(() => {
        if (currentSearchShape) {
          const layerType = currentLayerType || this.detectLayerType(currentSearchShape);
          this.performSearch(this.extractSearchData(currentSearchShape, layerType));
        } else if (this.currentLocation) {
          this.performSearch({ type: "point", lat: this.currentLocation.lat, lng: this.currentLocation.lng });
        }
      }, 300);
    },

    detectLayerType(layer) {
      if (layer.getLatLng) return "marker";
      if (layer.toGeoJSON) {
        const geom = layer.toGeoJSON().geometry;
        if (geom.type === "Polygon") return "polygon";
        if (geom.type === "LineString") return "polyline";
      }
      return null;
    }
  };
}
