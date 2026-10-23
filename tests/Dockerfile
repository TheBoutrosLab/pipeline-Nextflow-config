ARG MAVEN_VERSION=3-amazoncorretto-21
ARG NEXTFLOW_VERSION=25.10.5

# Download groovy-test, system-rules, and mockito using Maven
FROM maven:${MAVEN_VERSION} AS builder
COPY config/pom.xml /pom.xml
RUN mvn --batch-mode dependency:copy-dependencies -DoutputDirectory=/bljars

FROM nextflow/nextflow:${NEXTFLOW_VERSION}

COPY --from=builder /bljars /bljars

ARG NEXTFLOW_VERSION
ENV NEXTFLOW_JAR=/.nextflow/framework/${NEXTFLOW_VERSION}/nextflow-${NEXTFLOW_VERSION}-one.jar
ENV TEST_JARS_DIR=/bljars
# The configs under test require the legacy (v1) config parser
ENV NXF_SYNTAX_PARSER=v1

# Run Groovy scripts against the Nextflow jar instead of the Nextflow CLI
COPY groovy-runner.sh /usr/local/bin/groovy-runner
RUN chmod 755 /usr/local/bin/groovy-runner \
    && test -f "${NEXTFLOW_JAR}"

COPY validator /usr/local/validator

WORKDIR /mnt/pipeline
ENTRYPOINT ["groovy-runner"]
