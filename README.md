# POE2 Build AI

A Rails + Python application for analyzing **Path of Exile 2** league changes and helping with build planning.

The long-term goal is to build an assistant that can:

- ingest new **league announcements** and **patch notes**
- detect what got **buffed**, **nerfed**, **reworked**, **added**, or **removed**
- map those changes to known **build archetypes**
- help diagnose a struggling character
- recommend better **passive pathing**, **uniques**, and **rare item priorities**

This project is **not** intended to automate gameplay or act as a bot. It is a planning and analysis tool.

---

## Table of Contents

- [Overview](#overview)
- [Goals of the App](#goals-of-the-app)
- [Tech Stack](#tech-stack)
- [Project Layout](#project-layout)
- [Current MVP Scope](#current-mvp-scope)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Database and Core Models](#database-and-core-models)
- [Example API Endpoints](#example-api-endpoints)
- [Development Workflow](#development-workflow)
- [Debugging / Issues We Ran Into](#debugging--issues-we-ran-into)
- [Recommended Next Steps](#recommended-next-steps)
- [Long-Term Vision](#long-term-vision)
- [Notes](#notes)

---

## Overview

POE2 Build AI is meant to become a **build analysis assistant** for Path of Exile 2.

Instead of trying to train a giant game-specific model from scratch, the app is structured around:

- **official patch-note ingestion**
- **structured build archetype data**
- **character snapshot diagnosis**
- **rule-based and model-assisted recommendations**

The first versions focus on building a reliable foundation:

- store patch documents
- store balance changes
- store build archetypes
- diagnose characters
- expose simple recommendation APIs

---

## Goals of the App

This app is meant to answer questions like:

- What builds got buffed or nerfed this league?
- Which league starters look stronger after the latest patch notes?
- Why does my build feel weak right now?
- What should I upgrade next?
- Should I replace this unique with a rare?
- What stats should I prioritize on my next gear upgrade?

The app is built around a few core ideas:

### 1. Patch ingestion

- store official patch notes and announcements
- extract meaningful balance changes from raw text

### 2. Build knowledge

- maintain a structured database of build archetypes
- track offense/defense tags, scaling methods, and common failure modes

### 3. Character diagnosis

- accept a snapshot of a build
- identify likely issues
- suggest next upgrades and fixes

### 4. Recommendation engine

- combine structured data, rules, and later ML/LLM support
- explain why a build is improving or getting worse

---

## Tech Stack

### Main app

- **Ruby on Rails 8**
- **PostgreSQL**
- **Redis**
- **Sidekiq**

### Supporting services

- **Python / FastAPI**
- **scikit-learn / XGBoost** for future scoring models

### Infra / dev environment

- **Docker Compose**

---

## Project Layout

```text
poe2_build_ai/
├── app/                  # Rails application
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   └── jobs/
│   ├── config/
│   ├── db/
│   └── Dockerfile
├── python_service/       # FastAPI scoring service
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── docker-compose.yml
├── .env
└── README.md
```

### Key parts

#### Rails app

Responsible for:

- API endpoints
- database models
- background jobs
- patch ingestion
- archetype storage
- character snapshots
- recommendation history

#### Python service

Responsible for:

- lightweight scoring endpoints
- future ranking or model-based recommendations

#### Postgres

Stores:

- patch documents
- patch changes
- build archetypes
- archetype impact mappings
- character snapshots
- recommendation runs

#### Redis / Sidekiq

Used for:

- background jobs
- patch fetching and parsing
- future async processing

---

## Current MVP Scope

The current app skeleton is designed to support:

- storing patch documents
- storing patch changes
- storing build archetypes
- diagnosing a build snapshot
- exposing basic JSON API endpoints

Planned next steps include:

- patch note ingestion jobs
- patch parsing
- change classification
- mapping changes to archetypes
- league starter summaries
- upgrade recommendation logic
- passive-tree-aware recommendations

---

## Quick Start

If you already have Docker Desktop running and just want the short version:

```bash
mkdir poe2_build_ai
cd poe2_build_ai
git init
mkdir -p python_service
```

Create the Rails app:

```bash
docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  ruby:3.3.1 \
  bash -lc 'gem install rails bundler && ruby -S rails new app -d postgresql'
```

Then create the project files described below, and run:

```bash
docker compose build
docker compose run --rm web bundle install
docker compose run --rm web bin/rails db:create
docker compose run --rm web bin/rails db:migrate
docker compose up
```

Health checks:

```bash
curl http://localhost:3000/up
curl http://localhost:8001/health
```

---

## Detailed Setup

### Prerequisites

You should have these installed on your Mac:

- Docker Desktop
- Git

Optional but useful:

- Homebrew
- Python 3
- curl

Verify Docker is running:

```bash
docker --version
docker compose version
```

---

### Initial Project Setup

From your terminal:

```bash
mkdir poe2_build_ai
cd poe2_build_ai
git init
```

---

### Create the Rails App

We initially scaffolded Rails inside Docker rather than installing Ruby/Rails directly on macOS.

```bash
docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  ruby:3.3.1 \
  bash -lc 'gem install rails bundler && ruby -S rails new app -d postgresql'
```

If `ruby -S rails` is needed, it is because the `rails` executable may not be on `PATH` inside the temporary container.

---

### Create the Python Service

```bash
mkdir -p python_service
```

Create `python_service/requirements.txt`:

```txt
fastapi
uvicorn
pydantic
scikit-learn
pandas
numpy
xgboost
```

Create `python_service/main.py`:

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class BuildScoreRequest(BaseModel):
    archetype: dict
    patch_impacts: list
    character_snapshot: dict | None = None

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/score_archetype")
def score_archetype(req: BuildScoreRequest):
    score = sum(item.get("impact_score", 0) for item in req.patch_impacts)
    return {
        "league_start_score": score,
        "confidence": 0.65
    }
```

Create `python_service/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /service

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
```

---

### Rails Dockerfile

Replace `app/Dockerfile` with:

```dockerfile
FROM ruby:3.3.1

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bash", "-lc", "bundle exec rails server -b 0.0.0.0 -p 3000"]
```

---

### Rails Gemfile

Replace `app/Gemfile` with:

```ruby
source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "propshaft"

gem "sidekiq"
gem "redis"
gem "httparty"
gem "oj"
gem "dotenv-rails"
gem "pgvector"
gem "ruby-openai"
```

`propshaft` is included because Rails 8 generated config may still assume asset-related configuration exists.

---

### docker-compose.yml

Create this in the project root:

```yaml
services:
  db:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: poe2_ai_development
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  python_service:
    build:
      context: ./python_service
    volumes:
      - ./python_service:/service
    ports:
      - "8001:8001"

  web:
    build:
      context: ./app
    command: bash -lc "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0 -p 3000"
    volumes:
      - ./app:/rails
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/poe2_ai_development
      REDIS_URL: redis://redis:6379/0
      PYTHON_SERVICE_URL: http://python_service:8001
      RAILS_ENV: development
    depends_on:
      - db
      - redis
      - python_service

  worker:
    build:
      context: ./app
    command: bash -lc "bundle exec sidekiq"
    volumes:
      - ./app:/rails
    environment:
      DATABASE_URL: postgres://postgres:password@db:5432/poe2_ai_development
      REDIS_URL: redis://redis:6379/0
      PYTHON_SERVICE_URL: http://python_service:8001
      RAILS_ENV: development
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
```

---

### Database config

Replace `app/config/database.yml` with:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
  url: <%= ENV["DATABASE_URL"] %>

development:
  <<: *default

test:
  <<: *default
  url: postgres://postgres:password@db:5432/poe2_ai_test
```

---

### Sidekiq config

Create `app/config/initializers/sidekiq.rb`:

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379/0") }
end
```

---

### Environment variables

Create `.env`:

```bash
OPENAI_API_KEY=replace_me
```

---

### Build and boot

Build the containers:

```bash
docker compose build
```

Install gems inside the web container:

```bash
docker compose run --rm web bundle install
```

Create the database:

```bash
docker compose run --rm web bin/rails db:create
```

Run migrations:

```bash
docker compose run --rm web bin/rails db:migrate
```

Start the app:

```bash
docker compose up
```

---

## Database and Core Models

Planned core models include:

- `PatchDocument`
- `PatchChange`
- `Archetype`
- `ArchetypeImpact`
- `CharacterSnapshot`
- `RecommendationRun`

These are intended to support:

- patch note storage
- parsed balance changes
- build archetypes
- build impact analysis
- build diagnosis
- recommendation tracking

### Example model generation commands

```bash
docker compose run --rm web bin/rails generate model PatchDocument \
  title:string source_url:string version:string document_type:string \
  published_at:datetime raw_text:text metadata:jsonb

docker compose run --rm web bin/rails generate model PatchChange \
  patch_document:references entity_name:string entity_type:string \
  change_type:string before_text:text after_text:text summary:text \
  tags:jsonb numeric_data:jsonb confidence:float

docker compose run --rm web bin/rails generate model Archetype \
  name:string class_name:string ascendancy_name:string primary_skill:string \
  offense_tags:jsonb defense_tags:jsonb core_mechanics:jsonb \
  leveling_notes:text failure_modes:text

docker compose run --rm web bin/rails generate model ArchetypeImpact \
  archetype:references patch_change:references impact_score:float \
  impact_kind:string reasoning:text

docker compose run --rm web bin/rails generate model CharacterSnapshot \
  name:string class_name:string ascendancy_name:string level:integer \
  skills:jsonb stats:jsonb defenses:jsonb gear:jsonb passives:jsonb \
  constraints:jsonb

docker compose run --rm web bin/rails generate model RecommendationRun \
  character_snapshot:references mode:string input_payload:jsonb output_payload:jsonb
```

### pgvector migration

Generate the migration:

```bash
docker compose run --rm web bin/rails generate migration EnablePgvector
```

Then edit the migration file to:

```ruby
class EnablePgvector < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"
  end
end
```

### JSONB defaults

When editing generated migrations, use defaults like:

```ruby
t.jsonb :metadata, default: {}
t.jsonb :tags, default: []
t.jsonb :numeric_data, default: {}
t.jsonb :offense_tags, default: []
t.jsonb :defense_tags, default: []
t.jsonb :core_mechanics, default: []
t.jsonb :skills, default: {}
t.jsonb :stats, default: {}
t.jsonb :defenses, default: {}
t.jsonb :gear, default: {}
t.jsonb :passives, default: {}
t.jsonb :constraints, default: {}
t.jsonb :input_payload, default: {}
t.jsonb :output_payload, default: {}
```

---

## Example API Endpoints

### Health check

```http
GET /up
```

### League starters

```http
GET /api/league_starters
```

### Diagnose build

```http
POST /api/diagnose_build
```

Example request:

```json
{
  "name": "My Ranger",
  "class_name": "Ranger",
  "ascendancy_name": "Deadeye",
  "level": 35,
  "defenses": {
    "life": 420,
    "fire_res": 48,
    "cold_res": 31,
    "lightning_res": 75
  },
  "gear": {
    "weapon": {
      "type": "Bow",
      "dps_score": 70
    }
  }
}
```

Example curl:

```bash
curl -X POST http://localhost:3000/api/diagnose_build \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Ranger",
    "class_name": "Ranger",
    "ascendancy_name": "Deadeye",
    "level": 35,
    "defenses": {
      "life": 420,
      "fire_res": 48,
      "cold_res": 31,
      "lightning_res": 75
    },
    "gear": {
      "weapon": {
        "type": "Bow",
        "dps_score": 70
      }
    }
  }'
```

---

## Development Workflow

Common commands:

```bash
docker compose up
docker compose down
docker compose logs -f web
docker compose logs -f worker
docker compose run --rm web bin/rails console
docker compose run --rm web bin/rails db:migrate
docker compose run --rm web bin/rails db:seed
docker compose restart web
```

Useful checks:

```bash
curl http://localhost:3000/up
curl http://localhost:8001/health
curl http://localhost:3000/api/league_starters
```

---

## Debugging / Issues We Ran Into

This section documents the actual problems hit during setup so future setup is faster.

### 1. `rails: command not found` during initial scaffold

Command:

```bash
docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  ruby:3.3.1 \
  bash -lc 'gem install rails bundler && rails new app -d postgresql'
```

Problem:

- Rails gem installed successfully
- but the `rails` executable was not on PATH inside the shell

Fix:

- use `ruby -S rails` instead

```bash
docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  ruby:3.3.1 \
  bash -lc 'gem install rails bundler && ruby -S rails new app -d postgresql'
```

---

### 2. `cannot load such file -- bootsnap/setup`

Problem:

- the Rails app scaffold was mostly created
- but some post-generation installer steps failed while loading `bootsnap/setup`

Cause:

- dependency/setup mismatch during scaffold completion

Fix:

- keep the generated app
- continue with Docker-first setup
- ensure `bootsnap` is present in the Gemfile
- run `bundle install` inside the container

---

### 3. `undefined method 'assets' for Rails::Application::Configuration`

Error looked like:

```ruby
NoMethodError: undefined method `assets' for an instance of Rails::Application::Configuration
```

Cause:

- Rails generated config still referenced asset configuration
- but the simplified Gemfile no longer had the matching asset pipeline support

Fix:

- add `propshaft` back to the Gemfile

```ruby
gem "propshaft"
```

---

### 4. `stale_when_importmap_changes` undefined in `ApplicationController`

Problematic controller:

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes
end
```

Cause:

- default scaffold code expected importmap-related helpers
- but the app was no longer using that setup

Fix:

- simplify the controller

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
end
```

If `allow_browser` ever becomes a problem too, the fallback is:

```ruby
class ApplicationController < ActionController::Base
end
```

---

## Recommended Next Steps

Once the app boots cleanly:

1. add the core models and migrations
2. seed a small set of build archetypes
3. add a `CharacterDoctor` service
4. add recommendation endpoints
5. add patch-note ingestion jobs
6. parse raw patch notes into structured changes
7. map those changes to build archetypes
8. generate league-start summaries

A good first milestone is getting these endpoints working:

- `GET /up`
- `GET /api/league_starters`
- `POST /api/diagnose_build`

---

## Long-Term Vision

The final version of this app should be able to:

- ingest official POE2 patch notes quickly
- classify changes automatically
- explain build meta shifts
- rank likely league starters
- help diagnose weak builds
- recommend item and passive path changes
- provide grounded reasoning instead of generic chatbot answers

The system should stay focused on being a **build planning and analysis assistant**, not an automation tool.

---

## Notes

- This project currently favors a **Docker-first workflow**
- The app is still in early scaffolding / MVP stage
- The current priority is getting a clean vertical slice working before adding more advanced AI or ML features
- If setup gets weird, favor **keeping the generated app and fixing config incrementally** instead of repeatedly recreating the project from scratch
