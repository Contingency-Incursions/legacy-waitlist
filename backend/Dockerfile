# Setup database
FROM ubuntu as db-setup
ARG DEBIAN_FRONTEND=noninteractive
ADD . /app/backend
WORKDIR /app/backend
RUN apt update
RUN apt install postgresql postgresql-contrib -f -y

ARG DATABASE_USERNAME=waitlist
ARG DATABASE_PASSWORD
ARG DATABASE_HOST=127.0.0.1
ARG DATABASE_NAME=waitlist

RUN PGPASSWORD="${DATABASE_PASSWORD}" psql --host="${DATABASE_HOST}" --user="${DATABASE_USERNAME}" "${DATABASE_NAME}" < sql/postgres.sql
RUN touch /yes-i-want-this-step


# Static data
FROM alpine AS sde-export
RUN apk add sqlite wget bzip2
RUN mkdir /data
WORKDIR /data
ADD shrink-sde.sh /data/
RUN sh shrink-sde.sh


# Base image: have some deps etc
FROM rust:1.72-alpine AS base
WORKDIR /app/backend
RUN apk add --no-cache musl-dev sqlite
RUN cargo install cargo-chef


# Plan the build: create a list of dependencies
FROM base AS planner
ADD . /app/backend
RUN cargo chef prepare --recipe-path /recipe.json


# Cache dependencies
FROM base AS cacher
ARG PROFILE=release
RUN apt install libssl-dev -f -y
COPY --from=planner /recipe.json /recipe.json
RUN cargo chef cook --profile ${PROFILE} --no-default-features --features=postgres --recipe-path /recipe.json


# Build the image
FROM base AS builder
COPY --from=db-setup /yes-i-want-this-step /yes-i-want-this-step
COPY --from=cacher /app/backend/target target
COPY --from=cacher $CARGO_HOME $CARGO_HOME
COPY --from=sde-export /data/sqlite-shrunk.sqlite sqlite-shrunk.sqlite
ADD . /app/backend
RUN apt install libssl-dev -f -y

RUN apk add --no-cache mariadb-client

ARG DATABASE_USERNAME=waitlist
ARG DATABASE_PASSWORD
ARG DATABASE_HOST=localhost
ARG DATABASE_NAME=waitlist

ARG DATABASE_URL=postgres://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:5432/${DATABASE_NAME}
ARG PROFILE=release

RUN cargo build --profile ${PROFILE} --no-default-features --features=postgres
RUN cp target/*/tdf_wl /backend


# Final image
FROM alpine
COPY --from=sde-export /data/sqlite-shrunk.sqlite /app/sqlite-shrunk.sqlite
COPY --from=builder /backend /app/backend

WORKDIR /app
COPY data data
ADD Rocket.toml .

ENTRYPOINT /app/backend
EXPOSE 5000
