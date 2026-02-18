# Base image built from Dockerfile.base (CI pushes to executionengine.azurecr.io)
BASE_IMAGE ?= executionengine.azurecr.io/darwin-eu-dev/examplestudy-base:latest
RSTUDIO_PORT ?= 8787

.PHONY: push pull rstudio rstudio-stop

push:
	git add .
	git commit -m "debug actions"
	git push

# Pull the base image (use before make rstudio if not already pulled). Uses linux/amd64 on Apple Silicon.
pull:
	docker pull --platform linux/amd64 $(BASE_IMAGE)

# Run RStudio Server from the base image. Open http://127.0.0.1:$(RSTUDIO_PORT)
# Login: username rstudio, password rstudio
# Usage: make rstudio  [BASE_IMAGE=your-base:tag]  ;  make rstudio-stop  to stop
# --platform linux/amd64: base image is amd64-only (Snowflake/SQL Server ODBC); required on Apple Silicon.
rstudio:
	-docker rm -f rstudio 2>/dev/null || true
	docker run -d --platform linux/amd64 \
	  -e USER=rstudio \
	  -e PASSWORD=rstudio \
	  -p 127.0.0.1:$(RSTUDIO_PORT):8787 \
	  --name rstudio \
	  $(BASE_IMAGE) \
	  bash -c "rstudio-server start && tail -f /dev/null"
	@echo "RStudio Server: http://127.0.0.1:$(RSTUDIO_PORT)  (user: rstudio, password: rstudio)"

rstudio-stop:
	docker rm -f rstudio 2>/dev/null || true
