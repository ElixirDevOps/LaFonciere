FROM hexpm/elixir:1.17.3-erlang-27.1.2-debian-bookworm-20241016-slim

WORKDIR /app
COPY . .
RUN mix compile

CMD ["mix", "serve"]
