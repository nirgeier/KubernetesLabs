#!/usr/bin/env bash
# Build multi-platform Docker images locally (macOS friendly) and push them to a registry
# Usage examples:
#   ./scripts/build-multiarch.sh                 # build and push default image (nirgeier/escape-room-bash:latest + commit sha)
#   ./scripts/build-multiarch.sh --no-push      # build only (will require additional flags for local multi-arch outputs)
#   ./scripts/build-multiarch.sh -t myrepo/myimage:1.2.3 --platforms linux/amd64,linux/arm64

set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME=$(basename "$0")
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Defaults
DEFAULT_CONTEXT="."
DEFAULT_DOCKERFILE="Docker/Dockerfile"
DEFAULT_REGISTRY_TAG="nirgeier/escape-room-bash"
DEFAULT_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
PUSH=true
CACHE_FROM="type=gha"
CACHE_TO="type=gha,mode=max"

print_usage() {
  cat <<EOF
$SCRIPT_NAME - build multi-platform Docker images and optionally push

Usage: $SCRIPT_NAME [options]

Options:
  -h, --help            Show this help and exit
  -c, --context PATH    Build context directory (default: ${DEFAULT_CONTEXT})
  -f, --file PATH       Dockerfile path (default: ${DEFAULT_DOCKERFILE})
  -p, --platforms LIST  Comma-separated platforms (default: ${DEFAULT_PLATFORMS})
  -t, --tag TAGS        Comma-separated tags (default: latest + git sha)
  -r, --repo IMAGE      Image repository (default: ${DEFAULT_REGISTRY_TAG})
      --push/--no-push  Push images after building (default: --push)
  -n, --no-cache        Disable build cache-from/cache-to GHA caches

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME --no-push -t myuser/myimage:dev
  $SCRIPT_NAME -p linux/amd64,linux/arm64 -t myuser/myimage:1.0.0 --push

EOF
}

# parse args
CONTEXT="$DEFAULT_CONTEXT"
DOCKERFILE="$DEFAULT_DOCKERFILE"
PLATFORMS="$DEFAULT_PLATFORMS"
TAGS=""
REPO="$DEFAULT_REGISTRY_TAG"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    -c|--context)
      CONTEXT="$2"; shift 2
      ;;
    -f|--file)
      DOCKERFILE="$2"; shift 2
      ;;
    -p|--platforms)
      PLATFORMS="$2"; shift 2
      ;;
    -t|--tag|--tags)
      TAGS="$2"; shift 2
      ;;
    -r|--repo)
      REPO="$2"; shift 2
      ;;
    --push)
      PUSH=true; shift
      ;;
    --no-push)
      PUSH=false; shift
      ;;
    -n|--no-cache)
      CACHE_FROM=""; CACHE_TO=""; shift
      ;;
    *)
      echo "Unknown argument: $1" >&2; print_usage; exit 2
      ;;
  esac
done

# Determine tags default: latest + git short sha if available
if [[ -z "$TAGS" ]]; then
  TAGS="latest"
  if command -v git >/dev/null 2>&1 && [[ -d "$PROJECT_ROOT/.git" ]]; then
    GIT_SHA=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || true)
    if [[ -n "$GIT_SHA" ]]; then
      TAGS+=",$REPO:$GIT_SHA"
    fi
  fi
fi

# Normalize tags so each is a fully-qualified tag under $REPO unless user provided fully-qualified
# If a tag already contains '/', assume it's a full image name; otherwise prefix repo
normalized_tags=()
IFS=',' read -r -a user_tags <<< "$TAGS"
for t in "${user_tags[@]}"; do
  if [[ "$t" == *"/"* || "$t" == *":"* ]]; then
    normalized_tags+=("$t")
  else
    normalized_tags+=("$REPO:$t")
  fi
done
# join tags with comma
TAGS_JOINED=$(IFS=,; echo "${normalized_tags[*]}")

echo "Context: $CONTEXT"
echo "Dockerfile: $DOCKERFILE"
echo "Platforms: $PLATFORMS"
echo "Tags: $TAGS_JOINED"
echo "Push: $PUSH"

# Quick environment checks
if ! command -v docker >/dev/null 2>&1; then
  echo "docker CLI not found. Please install Docker Desktop (macOS) or Docker Engine." >&2
  exit 1
fi

# Ensure docker daemon is responsive
if ! docker info >/dev/null 2>&1; then
  echo "Docker does not appear to be running or you don't have permission to access it." >&2
  echo "Please start Docker Desktop and try again." >&2
  exit 1
fi

# Install binfmt/qemu handlers (best-effort). On macOS Docker Desktop this can fail due to restricted privileges.
echo "Setting up QEMU binfmt handlers (best-effort) ..."
if ! docker run --rm --privileged tonistiigi/binfmt:latest --install all; then
  echo "Warning: automated binfmt install failed. If you're on macOS Docker Desktop that's expected in some setups." >&2
  echo "Continuing — Buildx may still emulate using existing handlers or the build may fail for certain platforms." >&2
fi

# Create/ensure a buildx builder
BUILDER_NAME="multi-builder"
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo "Creating buildx builder '$BUILDER_NAME'..."
  docker buildx create --name "$BUILDER_NAME" --driver docker-container --use || {
    echo "Failed to create buildx builder with driver docker-container. Trying create without specifying driver..."
    docker buildx create --name "$BUILDER_NAME" --use
  }
else
  echo "Using existing buildx builder '$BUILDER_NAME'"
  docker buildx use "$BUILDER_NAME"
fi

echo "Bootstrapping builder (this may take a few seconds)..."
docker buildx inspect --bootstrap

# Build command construction
build_cmd=(docker buildx build)
build_cmd+=(--platform "$PLATFORMS")
# Resolve Dockerfile path: if not absolute, make it relative to the context so buildx resolves it correctly
if [[ "$DOCKERFILE" = /* ]]; then
  FILE_ARG="$DOCKERFILE"
else
  FILE_ARG="$CONTEXT/$DOCKERFILE"
fi
build_cmd+=(--file "$FILE_ARG")

# Add tags
IFS=',' read -r -a _tags_array <<< "$TAGS_JOINED"
for tt in "${_tags_array[@]}"; do
  build_cmd+=(--tag "$tt")
done

# Cache flags
if [[ -n "$CACHE_FROM" ]]; then
  build_cmd+=(--cache-from "$CACHE_FROM")
fi
if [[ -n "$CACHE_TO" ]]; then
  build_cmd+=(--cache-to "$CACHE_TO")
fi

# Push vs local
if [[ "$PUSH" == true ]]; then
  build_cmd+=(--push)
else
  # For multi-platform builds, --load only supports a single platform. Warn user and set output to local tar files.
  echo "Note: Multi-platform local loads are limited. For multiple platforms the script will export separate tar files in ./multiarch-output." >&2
  mkdir -p "$PROJECT_ROOT/multiarch-output"
  build_cmd+=(--output "type=tar,dest=$PROJECT_ROOT/multiarch-output/image-{{.Platform}}.tar")
fi

# Context
build_cmd+=("$CONTEXT")

# Print and run build command
echo
echo "Running:"
# Show a shell-escaped version of the command for clarity
printf '%q ' "${build_cmd[@]}"
echo

# Execute the build command safely using the array (avoids word-splitting/eval issues)
(
  cd "$PROJECT_ROOT" && 
  "${build_cmd[@]}"
)

EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "buildx finished with exit code $EXIT_CODE" >&2
  exit $EXIT_CODE
fi

echo "Build finished successfully." 
if [[ "$PUSH" == true ]]; then
  echo "Images pushed:"
  for tt in "${_tags_array[@]}"; do
    echo "  - $tt"
  done
else
  echo "Tar artifacts saved to: $PROJECT_ROOT/multiarch-output/"
fi

exit 0
