# Telepresence Demo - Docker Images Build

This directory contains instructions for building the Docker images if you want to use custom images instead of inline deployments.

## Building Images

### Backend Service

```bash
cd backend-app
docker build -t your-registry/telepresence-backend:v1 .
docker push your-registry/telepresence-backend:v1
```

### Data Service

```bash
cd dataservice-app
docker build -t your-registry/telepresence-dataservice:v1 .
docker push your-registry/telepresence-dataservice:v1
```

### Frontend

```bash
cd frontend-app
docker build -t your-registry/telepresence-frontend:v1 .
docker push your-registry/telepresence-frontend:v1
```

## Using Custom Images

If you build custom images, update the Kubernetes manifests to use your images:

1. Edit `02-dataservice.yaml` and replace the inline Python image with your dataservice image
2. Edit `03-backend.yaml` and replace the inline Python image with your backend image
3. Edit `04-frontend.yaml` and replace nginx:alpine with your frontend image

## Note

The current setup uses inline deployments (building the app within the container at runtime) for simplicity. This is perfect for demos but not recommended for production use. For production, always use pre-built images.
