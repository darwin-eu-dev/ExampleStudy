# Study image: prebuilt base + repo + renv::restore().
# Build in two steps:
#   1) Base:  docker build -f Dockerfile.base -t examplestudy-base:latest .
#             (Optionally push: docker push <registry>/examplestudy-base:latest)
#   2) Study: docker build -t examplestudy:latest .
#             (Then sign and push per your CI, e.g. cosign sign, docker push)
ARG BASE_IMAGE=examplestudy-base:latest
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.maintainer="Adam Black <a.black@darwin-eu.org>"

RUN install2.r --error devtools remotes \
   && rm -rf /tmp/download_packages/ /tmp/*.rds

WORKDIR /code
COPY . /code

# Install R package dependencies from renv.lock
RUN R -e "renv::restore()"

CMD ["bash"]
