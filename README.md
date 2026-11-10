# Sport Venue Near Me

[![CI](https://github.com/victoravellog/sport-venue-near-me/actions/workflows/ci.yml/badge.svg)](https://github.com/victoravellog/sport-venue-near-me/actions/workflows/ci.yml)

A Hanami 3 + PostGIS application that answers "What sports venues are near me?" It serves a
server-rendered UI with an interactive map and a versioned JSON API. No authentication (anonymous use).

## Requirements

- Docker and Docker Compose (no local Ruby/Hanami installation needed)

## Quick Start

```bash
cp .env.example .env                                        # configure database credentials
docker compose up -d                                        # start web + PostGIS
docker compose run --rm web bundle exec hanami db prepare   # create + migrate (enables PostGIS)
docker compose run --rm web bundle exec hanami db seed      # load sample venues (idempotent)
```

Open [http://localhost:2300](http://localhost:2300) to see the map. Re-running `hanami db seed` does
not duplicate venues (upsert by `source` + `source_id`).

### JSON API

```bash
curl -s "http://localhost:2300/api/v1/venues/search?lat=53.96&lng=-1.08&buffer=500"
```

A liveness probe is available at [http://localhost:2300/up](http://localhost:2300/up).

## Development

### Running Tests

```bash
docker compose run --rm web bundle exec rspec
```

### Running the Linter

```bash
docker compose run --rm web bundle exec rubocop
```

### Console

```bash
docker compose run --rm web bundle exec hanami console
```

### Building Assets

```bash
docker compose run --rm web bundle exec hanami assets compile   # the `assets` service watches in dev
```

### Stopping the Environment

```bash
docker compose down          # stops containers, preserves data volume
docker compose down -v       # stops containers AND removes data volume
```

## Project Structure

Hanami 3 full-stack app organized by slices (actions, views/parts, operations, ROM repositories).

- **Database**: PostgreSQL 17 with PostGIS 3.5
- **Geospatial**: ROM + Sequel (PostGIS extension) + RGeo, SRID 4326; distance queries run in the DB
- **Testing**: RSpec with deterministic seed data (no factories)
- **Frontend**: Hanami views + Alpine.js (CSP build) with a Leaflet map

## License

This project is for portfolio demonstration purposes.
