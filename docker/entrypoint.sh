#!/bin/bash

# Write the api_tokens.yml file
cat > /app/api_tokens.yml <<EOL
api_key: ${TB_API_KEY}
admin_key: ${TB_ADMIN_KEY}
EOL

# Write the config.yml file
cat > /app/config.yml <<EOL
network:
  host: ${TB_HOST:-127.0.0.1}
  port: ${TB_PORT:-5000}
  disable_auth: ${TB_DISABLE_AUTH:-false}
  disable_fetch_requests: ${TB_DISABLE_FETCH:-false}
  send_tracebacks: ${TB_SEND_TRACEBACKS:-false}
  api_servers: ["OAI"]
logging:
  log_prompt: ${TB_LOG_PROMPT:-false}
  log_generation_params: ${TB_LOG_GENERATION_PARAMS:-false}
  log_requests: ${TB_LOG_REQUESTS:-false}
model:
  model_dir: ${TB_MODEL_DIR:-/app/models}
  inline_model_loading: ${TB_INLINE_MODEL_LOADING:-false}
  use_dummy_models: false
  model_name: ${TB_MODEL_NAME}
EOL

# Optionally add max_seq_len if TB_MAX_SEQ_LEN is set
if [ -n "${TB_MAX_SEQ_LEN}" ]; then
  echo "  max_seq_len: ${TB_MAX_SEQ_LEN}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
  tensor_parallel: ${TB_TENSOR_PARALLEL:-false}
  gpu_split_auto: ${TB_GPU_SPLIT_AUTO:-true}
  autosplit_reserve: [96]
EOL

# Optionally add gpu_split if TB_GPU_SPLIT is set
if [ -n "${TB_GPU_SPLIT}" ]; then
  echo "  gpu_split: ${TB_GPU_SPLIT}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
  rope_scale: ${TB_ROPE_SCALE:-1.0}
EOL

# Optionally add rope_alpha if TB_ROPE_ALPHA is set
if [ -n "${TB_ROPE_ALPHA}" ]; then
  echo "  rope_alpha: ${TB_ROPE_ALPHA}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
  cache_mode: ${TB_CACHE_MODE:-FP16}
EOL

# Optionally add cache_size if TB_CACHE_SIZE is set
if [ -n "${TB_CACHE_SIZE}" ]; then
  echo "  cache_size: ${TB_CACHE_SIZE}" >> /app/config.yml
fi

# Optionally add chunk_size if TB_CHUNK_SIZE is set
if [ -n "${TB_CHUNK_SIZE}" ]; then
  echo "  chunk_size: ${TB_CHUNK_SIZE}" >> /app/config.yml
fi

# Optionally add max_batch_size if TB_MAX_BATCH_SIZE is set
if [ -n "${TB_MAX_BATCH_SIZE}" ]; then
  echo "  max_batch_size: ${TB_MAX_BATCH_SIZE}" >> /app/config.yml
fi

# Optionally add prompt_template if TB_PROMPT_TEMPLATE is set
if [ -n "${TB_PROMPT_TEMPLATE}" ]; then
  echo "  prompt_template: ${TB_PROMPT_TEMPLATE}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
  vision: ${TB_VISION:-false}
EOL

# Optionally add num_experts_per_token if TB_NUM_EXPERTS is set
if [ -n "${TB_NUM_EXPERTS}" ]; then
  echo "  num_experts_per_token: ${TB_NUM_EXPERTS}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
draft_model:
EOL

# Add draft_model entries if corresponding variables are set
if [ -n "${TB_DRAFT_MODEL_DIR}" ]; then
  echo "  draft_model_dir: ${TB_DRAFT_MODEL_DIR}" >> /app/config.yml
fi

if [ -n "${TB_DRAFT_MODEL_NAME}" ]; then
  echo "  draft_model_name: ${TB_DRAFT_MODEL_NAME}" >> /app/config.yml
fi

if [ -n "${TB_DRAFT_ROPE_SCALE}" ]; then
  echo "  draft_rope_scale: ${TB_DRAFT_ROPE_SCALE}" >> /app/config.yml
fi

if [ -n "${TB_DRAFT_ROPE_ALPHA}" ]; then
  echo "  draft_rope_alpha: ${TB_DRAFT_ROPE_ALPHA}" >> /app/config.yml
fi

if [ -n "${TB_DRAFT_CACHE_MODE}" ]; then
  echo "  draft_cache_mode: ${TB_DRAFT_CACHE_MODE}" >> /app/config.yml
fi

# Continue writing to config.yml
cat >> /app/config.yml <<EOL
developer:
  unsafe_launch: ${TB_UNSAFE_LAUNCH:-false}
  disable_request_streaming: ${TB_DISABLE_REQUEST_STREAMING:-false}
  cuda_malloc_backend: ${TB_CUDA_MALLOC_BACKEND:-false}
  uvloop: ${TB_UVLOOP:-false}
  realtime_process_priority: ${TB_REALTIME_PROCESS_PRIORITY:-false}
EOL

# ------------------------------------------------------------------------------
# MODEL DOWNLOAD SECTION
# ------------------------------------------------------------------------------

# Set default model directory and model name if not provided
MODEL_DIR="${TB_MODEL_DIR:-/app/models}"
MODEL_NAME="${TB_MODEL_NAME}"

# Ensure the model directory exists
mkdir -p "${MODEL_DIR}"

# Check if MODEL_ID is set; if not, inform the user and skip model download
if [ -n "${MODEL_ID}" ]; then
  echo "Starting model download..."

  # Set the default branch if not specified
  MODEL_BRANCH="${MODEL_BRANCH:-main}"

  # If TB_MODEL_NAME is not set, derive it from MODEL_ID
  if [ -z "${MODEL_NAME}" ]; then
    MODEL_NAME="$(basename "${MODEL_ID}")"
    echo "TB_MODEL_NAME not set. Using '${MODEL_NAME}' as model name."
  fi

  # Full path to the model directory
  FULL_MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"

  echo "Downloading model '${MODEL_ID}' to '${FULL_MODEL_PATH}'..."

  # Change to the model directory
  cd "${MODEL_DIR}" || exit 1

  # Download the model using huggingface-cli
  HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download \
    "${MODEL_ID}" \
    --local-dir "${MODEL_NAME}" \
    --revision "${MODEL_BRANCH}" \
    --cache-dir "${MODEL_DIR}/.cache" \
    --resume

  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error downloading model '${MODEL_ID}'. Exiting."
    exit 1
  else
    echo "Model '${MODEL_ID}' downloaded successfully."
  fi

else
  echo "Environment variable MODEL_ID not set. Skipping model download."
fi

# Return to the app directory
cd /app || exit 1

# ------------------------------------------------------------------------------
# END OF MODEL DOWNLOAD SECTION
# ------------------------------------------------------------------------------

# Execute the CMD
exec "$@"