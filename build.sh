#!/bin/bash
# Build and deploy with specific domain configuration
# Usage: ./build.sh [domain] [base-path]
# Examples:
#   ./build.sh idrawio.cubecloud.io
#   ./build.sh example.com /drawio

set -e

DOMAIN="${1:-localhost:8231}"
# Default to http://localhost for local, https:// for others
if [[ "$DOMAIN" == "localhost"* ]]; then
    DRAWIO_URL="http://$DOMAIN"
else
    DRAWIO_URL="https://$DOMAIN"
fi

BASE_PATH="${2:-}"

echo "🚀 Building with configuration:"
echo "  Domain: $DOMAIN"
echo "  Draw.io URL: $DRAWIO_URL"
echo "  Base Path: ${BASE_PATH:-(root)}"
echo ""

# Create temporary env file
ENV_FILE=".env.build.tmp"
cat > "$ENV_FILE" << EOF
DRAWIO_BASE_URL=$DRAWIO_URL
NEXT_PUBLIC_BASE_PATH=$BASE_PATH
EOF

# Build and deploy
echo "📦 Starting docker-compose build..."
docker-compose --env-file "$ENV_FILE" up -d

echo ""
echo "✅ Build complete!"
echo ""
echo "Access at:"
if [[ "$DOMAIN" == "localhost"* ]]; then
    echo "  http://localhost:3201"
else
    echo "  https://$DOMAIN"
fi

# Cleanup
rm "$ENV_FILE"
