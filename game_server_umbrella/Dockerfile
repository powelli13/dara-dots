FROM bitwalker/alpine-elixir-phoenix:latest

WORKDIR /app

COPY . .

RUN mix deps.get

WORKDIR /app/apps/game_server_web/assets/node_modules

# Remove the phoenix* folders from node_modules
# these are copied over as symlinks which do not
# work correctly
RUN rm phoenix
RUN rm phoenix_html
RUN rm phoenix_live_view

RUN npm install
RUN npm rebuild node-sass

WORKDIR /app

CMD ["mix", "phx.server"]
