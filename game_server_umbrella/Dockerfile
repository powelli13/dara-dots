FROM bitwalker/alpine-elixir-phoenix:latest

WORKDIR /app

#COPY mix.exs .
#COPY mix.lock .

COPY . .

#RUN mkdir assets

#COPY apps/game_server_web/assets/package.json assets
#COPY apps/game_server_web/assets/package-lock.json assets

CMD mix deps.get && \
    #cd assets && \
    #npm install && \
    #cd .. && \
    mix phx.server

# below worked in the simple example app
# the phoenix and phoenix_html directories in node_modules
# were symlinks which didn't copy over well into the image
# deleting them before running npm install resolved this issue

#RUN mix deps.get

#WORKDIR /app/assets/node_modules

#RUN rm phoenix
#RUN rm phoenix_html

#RUN npm install
#RUN npm rebuild node-sass

#WORKDIR /app

#CMD ["mix", "phx.server"]