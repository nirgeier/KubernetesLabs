# syntax=docker/dockerfile:1.7

# ─── Build Stage ─────────────────────────────────────────────────────────────
FROM golang:1.22.4 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /workspace

# Cache module downloads as a separate layer
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY cmd/       cmd/
COPY api/       api/
COPY internal/  internal/

# Build the static binary (CGO disabled for distroless compatibility)
RUN CGO_ENABLED=0 \
  GOOS=${TARGETOS} \
  GOARCH=${TARGETARCH} \
  go build \
  -a \
  -ldflags="-s -w" \
  -o manager \
  cmd/main.go

# ─── Runtime Stage ────────────────────────────────────────────────────────────
# Use distroless/static for a minimal, CVE-resistant runtime image.
# The nonroot user (UID 65532) satisfies pod security standards.
FROM gcr.io/distroless/static:nonroot

WORKDIR /

COPY --from=builder /workspace/manager .

# Drop to non-root user
USER 65532:65532

ENTRYPOINT ["/manager"]
