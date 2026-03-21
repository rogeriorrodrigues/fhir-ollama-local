FROM eclipse-temurin:17-jre

RUN apt-get update && apt-get install -y --no-install-recommends curl jq python3 && rm -rf /var/lib/apt/lists/*

# Pin Synthea version for reproducibility
ENV SYNTHEA_VERSION=3.3.0
RUN curl -L -o /opt/synthea.jar \
    https://github.com/synthetichealth/synthea/releases/download/v${SYNTHEA_VERSION}/synthea-with-dependencies.jar

COPY synthea/synthea.properties /opt/synthea.properties
COPY synthea/entrypoint.sh /opt/entrypoint.sh
COPY load_patient.sh /opt/load_patient.sh
COPY load_evolutions.sh /opt/load_evolutions.sh
COPY synthea/generate_notes.py /opt/generate_notes.py
RUN chmod +x /opt/entrypoint.sh /opt/load_patient.sh /opt/load_evolutions.sh

WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]
