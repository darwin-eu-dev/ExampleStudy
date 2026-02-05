# Ubuntu 22.04 (Jammy) · R 4.2 · Dependencies for ExampleStudy
# For Snowflake ODBC use: docker build --platform linux/amd64 ...
FROM rocker/rstudio:4.2
LABEL org.opencontainers.image.maintainer="Adam Black <a.black@darwin-eu.org>"

# Install java and rJava
RUN apt-get -y update && apt-get install -y \
   default-jdk \
   r-cran-rjava \
   sudo \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/ \
   && sudo R CMD javareconf

RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/2026-02-01"))' >>"${R_HOME}/etc/Rprofile.site"
RUN install2.r --error rJava && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error DatabaseConnector && rm -rf /tmp/download_packages/ /tmp/*.rds
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/hades/jdbc_drivers"
RUN R -e "DatabaseConnector::downloadJdbcDrivers('all');"

RUN install2.r --error Andromeda && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error RJSONIO && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error CirceR && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error SqlRender && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error renv && rm -rf /tmp/download_packages/ /tmp/*.rds

# Install utility R packages
RUN apt-get -y update && apt-get install -y \
    libxml2-dev libssl-dev libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

RUN install2.r --error openssl httr xml2 remotes && rm -rf /tmp/download_packages/ /tmp/*.rds
RUN install2.r --error duckdb && rm -rf /tmp/download_packages/ /tmp/*.rds

# Install odbc and RPostgres drivers (unixODBC + dev headers + pkg-config for R odbc package)
# CXX required: R was built without C++ compiler; odbc's configure invokes ${CXX} -E
RUN apt-get -y update && apt-get install -y --install-suggests \
    unixodbc unixodbc-dev libpq-dev curl pkg-config build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig \
    CXX=g++ \
    install2.r --error RPostgres duckdb odbc \
    && rm -rf /tmp/download_packages/ /tmp/*.rds

# Install Darwin packages (and study Imports: dplyr, ggplot2, shiny, plotly)
RUN install2.r --error \
        omopgenerics \
        CDMConnector \
        IncidencePrevalence \
        PatientProfiles \
        TreatmentPatterns \
        DrugExposureDiagnostics \
        DrugUtilisation \
        dplyr \
        ggplot2 \
        shiny \
        plotly \
   && rm -rf /tmp/download_packages/ /tmp/*.rds

# GitHub token for installs (pass at build time: docker build --build-arg GITHUB_PAT=xxx)
RUN echo "DATABASECONNECTOR_JAR_FOLDER=/opt/hades/jdbc_drivers" >> /usr/local/lib/R/etc/Renviron
RUN echo "RENV_PATHS_CELLAR=/opt/renv_cellar" >> /usr/local/lib/R/etc/Renviron

# SQL Server odbc
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc > /dev/null
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
RUN apt-get clean && apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17

# Snowflake odbc
RUN curl -fsSL --output snowflake-odbc-3.1.1.x86_64.deb https://sfc-repo.snowflakecomputing.com/odbc/linux/3.1.1/snowflake-odbc-3.1.1.x86_64.deb
RUN sudo dpkg -i snowflake-odbc-3.1.1.x86_64.deb

RUN install2.r --error here log4r testthat renv \
   && rm -rf /tmp/download_packages/ /tmp/*.rds

RUN echo "EUNOMIA_DATA_FOLDER=/opt/eunomia_data" >> /usr/local/lib/R/etc/Renviron
RUN R -e 'CDMConnector::downloadEunomiaData()'

# Install vim
RUN apt-get -y update && apt-get install -y vim && apt-get clean && rm -rf /var/lib/apt/lists/

# Fix Snowflake odbc lib path
RUN sed -i 's/libodbcinst.so.1/libodbcinst.so.2/g' /usr/lib/snowflake/odbc/lib/simba.snowflake.ini


RUN mkdir /results

# Copy package source into image (for running study and CI tests)
COPY . /code
WORKDIR /code

# Install R package dependencies from renv.lock
RUN R -e "renv::restore()"

CMD ["bash"]
