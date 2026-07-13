#!/bin/bash
# Build script for vLLM with NCCL 2.29.7+ fix on native ARM64 (GX10/MSI)
# This builds the vllm-openai-nccl-fix target for aarch64 systems
# Run this on MSI (native ARM64) to avoid cross-compilation issues

set -e

echo "=========================================="
echo "vLLM NCCL 2.29.7 Fix Build Script (ARM64)"
echo "=========================================="
echo ""

# Check if we're on ARM64
if [ "$(uname -m)" != "aarch64" ]; then
    echo "ERROR: This script must be run on native ARM64 (aarch64) systems"
    echo "Current architecture: $(uname -m)"
    exit 1
fi

echo "✓ Running on native ARM64 (aarch64)"
echo ""

# Verify Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

echo "✓ Docker is available"
echo ""

# Build parameters
REGISTRY="${REGISTRY:-anathn}"
IMAGE_NAME="${IMAGE_NAME:-vllm}"
IMAGE_TAG="${IMAGE_TAG:-nccl-fix-37602}"
NCCL_VERSION="${NCCL_VERSION:-2.29.7}"
DOCKERFILE="${DOCKERFILE:-docker/Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"
PUSH_TO_REGISTRY="${PUSH_TO_REGISTRY:-true}"

echo "Build Configuration:"
echo "  Registry: $REGISTRY"
echo "  Image: $IMAGE_NAME"
echo "  Tag: $IMAGE_TAG"
echo "  NCCL Version: $NCCL_VERSION"
echo "  Dockerfile: $DOCKERFILE"
echo "  Push to registry: $PUSH_TO_REGISTRY"
echo ""

# Full image name
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building: $FULL_IMAGE_NAME"
echo ""

# Build the image
docker build \
  --target vllm-openai-nccl-fix \
  --build-arg NCCL_VERSION="${NCCL_VERSION}" \
  -t "${FULL_IMAGE_NAME}" \
  -f "${DOCKERFILE}" \
  "${BUILD_CONTEXT}"

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed"
    exit 1
fi

echo ""
echo "✓ Build completed successfully"
echo ""

# Verify the image
echo "Image info:"
docker images | grep "${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# Push to registry if enabled
if [ "${PUSH_TO_REGISTRY}" = "true" ]; then
    echo "Pushing to Docker Hub..."
    if docker push "${FULL_IMAGE_NAME}"; then
        echo "✓ Successfully pushed: ${FULL_IMAGE_NAME}"
    else
        echo "ERROR: Failed to push image to Docker Hub"
        echo "Make sure you're logged in: docker login"
        exit 1
    fi
else
    echo "Skipping push (PUSH_TO_REGISTRY=false)"
    echo "To push later, run: docker push ${FULL_IMAGE_NAME}"
fi

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "Usage:"
echo "  docker run --gpus all \\"
echo "    -v /path/to/models:/models \\"
echo "    ${FULL_IMAGE_NAME} \\"
echo "    python -m vllm.entrypoints.openai.api_server \\"
echo "      --model /models/qwen3.5-122b-fp8 \\"
echo "      --tensor-parallel-size 2"
echo ""
