#!/usr/bin/env bash
set -euo pipefail

echo "[init_vercel] Initializing Vercel project in $(pwd)"

# Check for Vercel CLI
if ! command -v vercel >/dev/null 2>&1; then
	echo "[init_vercel] Vercel CLI not found. Installing..."
	npm install -g vercel
fi

# Check if user is logged in
if ! vercel whoami >/dev/null 2>&1; then
	echo "[init_vercel] Not logged in to Vercel. Running 'vercel login'..."
	vercel login
fi

# Initialize Vercel project
echo "[init_vercel] Running 'vercel --prod' to initialize project..."
vercel --prod

echo "[init_vercel] Vercel project initialized successfully."
