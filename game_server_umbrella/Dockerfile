FROM bitwalker/alpine-elixir-phoenix:latest

WORKDIR /app

COPY mix.exs .
COPY mix.lock .

RUN mkdir assets

COPY apps/game_server_web/assets/package.json assets
COPY apps/game_server_web/assets/package-lock.json assets

RUN mix deps.get && \
    cd assets && \
    npm install && \
    cd ..

CMD ["mix", "phx.server"]
