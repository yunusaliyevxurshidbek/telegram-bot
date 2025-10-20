# ==========================
# 📦 Stage 1 — Build stage
# ==========================
FROM dart:3.9.2 AS build

# Loyihamizni ichiga kiramiz
WORKDIR /app

# pubspec fayllarini yuklab, dependency larni o‘rnatamiz
COPY pubspec.* ./
RUN dart pub get

# qolgan fayllarni ko‘chiramiz
COPY . .

# botni executable faylga kompilyatsiya qilamiz
RUN dart compile exe bin/birthday_bot.dart -o /app/bin/server

# ==========================
# 🚀 Stage 2 — Runtime stage
# ==========================
FROM scratch

# runtime fayllarni ko‘chiramiz
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# botni ishga tushiramiz
CMD ["/app/bin/server"]
