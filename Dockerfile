FROM gcc:12.2.0

# Create non-root user
RUN useradd -m appuser
USER appuser

# Set safe environment variables
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# Copy only necessary files
COPY --chown=appuser:appuser Makefile /app/
COPY --chown=appuser:appuser src/ /app/src/
COPY --chown=appuser:appuser tests/ /app/tests/

WORKDIR /app

# Build and test
RUN make all && make test
