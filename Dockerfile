# Builder stage with UV
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Copy only dependency files first (layer caching)
COPY pyproject.toml uv.lock ./

# Install only production dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Now copy the full source code
COPY . .

# Sync again to install your local package
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable


# Final runtime stage
FROM python:3.12-slim-bookworm

WORKDIR /app

# Copy virtualenv from builder
COPY --from=uv /app/.venv /app/.venv
# Copy app source
COPY --from=uv /app /app

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/src"

# Run the CLI entrypoint
ENTRYPOINT ["yfmcp"]
