# Use an official CUDA runtime with Ubuntu as a parent image
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    python3.11 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip3 install --no-cache-dir --upgrade pip "huggingface_hub[cli]" hf_transfer

# Set the working directory in the container
WORKDIR /app

# Get requirements
COPY pyproject.toml .

# Install packages specified in pyproject.toml cu121, extras
RUN pip3 install --no-cache-dir .[cu121,extras]

RUN rm pyproject.toml

# Copy the current directory contents into the container
COPY . .

# Copy the entrypoint script
COPY docker/entrypoint.sh /app/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Set the entry point to the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]

# Run main.py when the container launches
CMD ["python3", "main.py"]