FROM elixir:1.10.4 as releaser
ARG secret_key_base

WORKDIR /app

# Install Hex and Rebar
RUN apt-get update && \
    apt-get install -y nodejs && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install hex phx_new 1.5.3 --force && \
    curl -L https://npmjs.org/install.sh | sh


#CMD ["mix", "phx.server"]

ENV SECRET_KEY_BASE=${secret_key_base}
ENV MIX_ENV=prod

COPY . .
RUN mix do deps.get --only $MIX_ENV, deps.compile

WORKDIR /app/apps/game_server_web

RUN MIX_ENV=prod mix compile

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
USER node
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

WORKDIR /app
RUN MIX_ENV=prod mix release
