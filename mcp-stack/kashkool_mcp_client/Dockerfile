# Kashkool Cognitive MCP Client - Dockerfile
# Multi-stage build for production

# ==================== BASE STAGE ====================
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r kashkool && useradd -r -g kashkool -d /app -s /bin/bash kashkool

# Set work directory
WORKDIR /app

# ==================== BUILD STAGE ====================
FROM base as builder

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# ==================== PRODUCTION STAGE ====================
FROM base as production

# Copy Python packages from builder
COPY --from=builder /root/.local /home/kashkool/.local

# Copy application code
COPY --chown=kashkool:kashkool . .

# Install package in development mode
RUN pip install --no-deps -e .

# Create data directories
RUN mkdir -p /app/cognitive_data /app/logs && chown -R kashkool:kashkool /app

# Switch to non-root user
USER kashkool

# Add local bin to PATH
ENV PATH="/home/kashkool/.local/bin:${PATH}"

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["uvicorn", "kashkool_mcp_client.api_server:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]


# ==================== DEVELOPMENT STAGE ====================
FROM base as development

# Install dev dependencies
COPY requirements.txt .
RUN pip install --user -r requirements.txt && \
    pip install --user pytest pytest-asyncio pytest-cov black ruff mypy pre-commit

# Copy application code
COPY --chown=kashkool:kashkool . .

# Install package in development mode
RUN pip install --no-deps -e ".[dev]"

# Create data directories
RUN mkdir -p /app/cognitive_data /app/logs && chown -R kashkool:kashkool /app

# Switch to non-root user
USER kashkool

# Add local bin to PATH
ENV PATH="/home/kashkool/.local/bin:${PATH}"

# Expose port
EXPOSE 8000

# Default command with reload
CMD ["uvicorn", "kashkool_mcp_client.api_server:app", "--host", "0.0.0.0", "--port", "8000", "--reload", "--log-level", "debug"]