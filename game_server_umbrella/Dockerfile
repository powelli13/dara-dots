FROM elixir:1.10.4 as releaser

WORKDIR /app

# Install Hex and Rebar
RUN mix do local.hex --force, local.rebar --force

COPY config/ /app/config/
COPY mix.exs /app/
COPY mix.* /app/

COPY apps/game_server/mix.exs /app/apps/game_server
COPY apps/game_server_web/mix.exs /app/apps/game_server_web

ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile

COPY . /app/

WORKDIR /app/apps/game_server_web

RUN MIX_ENV=prod mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

WORKDIR /app
RUN MIX_ENV=prod mix release
