FROM eclipse-temurin:17-jre-alpine

RUN apk add --no-cache bash curl jq

# Pin Synthea version for reproducibility
ENV SYNTHEA_VERSION=3.3.0
RUN curl -L -o /opt/synthea.jar \
    https://github.com/synthetichealth/synthea/releases/download/v${SYNTHEA_VERSION}/synthea-with-dependencies.jar

COPY synthea.properties /opt/synthea.properties
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]
