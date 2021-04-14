# syntax=docker/dockerfile:1.0-experimental
FROM bitwalker/alpine-elixir-phoenix:latest

#To build and run:
#docker build . --tag {image name} --build-arg key={key value}
#docker run --name {container name} -p {port mapping e.g. 80:4000} {image name, from above}
WORKDIR /app

ARG key
ENV MIX_ENV prod
ENV SECRET_KEY_BASE key

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
