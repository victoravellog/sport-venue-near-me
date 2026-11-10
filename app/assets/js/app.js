import "../css/app.css";
import "../css/map.css";

import Alpine from "@alpinejs/csp";
import venueMap from "./venue_map";

Alpine.data("venueMap", venueMap);
window.Alpine = Alpine;
Alpine.start();
