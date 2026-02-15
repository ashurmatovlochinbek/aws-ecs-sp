# Stage 1: Base build stage
FROM python:3.13-slim AS builder

# Create the app directory
RUN mkdir /app

# Set the working directory
WORKDIR /app

# Set environment variables to optimize Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Upgrade pip and install dependencies
RUN pip install --upgrade pip

# Copy the requirements file first (better caching)
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Production stage
FROM python:3.13-slim

RUN useradd -m -r appuser && \
   mkdir /app && \
   chown -R appuser /app

# Copy the Python dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages/ /usr/local/lib/python3.13/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Set the working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Set environment variables to optimize Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Collect static files during build (optional)
# if you want to collect static files at runtime, you can skip this step and run it in the entrypoint script instead
# for example if you use aws s3 for static files, you might want to collect static files at runtime to avoid having stale files in the image
# create separate entrypoint script to run collectstatic and migrations at runtime, and set the entrypoint to that script instead of running collectstatic here
RUN python manage.py collectstatic --noinput

# Switch to non-root user
USER appuser

# Expose the application port (documentation only, but good practice)
EXPOSE 8000

# Start with Uvicorn async workers (works with sync Django apps!)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--worker-class", "uvicorn.workers.UvicornWorker", "aws_ecs_sp.asgi:application"]

