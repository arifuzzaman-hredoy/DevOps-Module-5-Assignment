# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY backend/ShopNest.sln ./backend/
COPY backend/ShopNest.Api/ShopNest.Api.csproj ./backend/ShopNest.Api/
COPY backend/ShopNest.Api.Tests/ShopNest.Api.Tests.csproj ./backend/ShopNest.Api.Tests/
RUN dotnet restore backend/ShopNest.Api/ShopNest.Api.csproj

COPY backend/ ./backend/
RUN dotnet publish backend/ShopNest.Api/ShopNest.Api.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/publish ./
COPY database/migrations ./migrations

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
USER $APP_UID
ENTRYPOINT ["dotnet", "ShopNest.Api.dll"]