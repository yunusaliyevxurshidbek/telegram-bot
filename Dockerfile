# Stage 1 — Build
FROM gcr.io/dart-lang/sdk:3.9.2 AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/birthday_bot.dart -o /app/bin/server

# Stage 2 — Runtime
FROM gcr.io/distroless/base-debian12

COPY --from=build /app/bin/server /app/bin/server
CMD ["/app/bin/server"]
