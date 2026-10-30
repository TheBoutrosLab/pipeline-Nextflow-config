#!/bin/bash
# Run a Groovy script with the Nextflow classes and the test dependencies on the
# classpath. Since Nextflow 24.07 the launcher runs a single shaded jar, so this calls
# GroovyMain against that jar directly instead of patching the launcher.
set -euo pipefail

NEXTFLOW_JAR=${NEXTFLOW_JAR:?Set NEXTFLOW_JAR to the path of nextflow-<version>-one.jar}
TEST_JARS_DIR=${TEST_JARS_DIR:-/bljars}

if [ ! -f "$NEXTFLOW_JAR" ]; then
    echo "NEXTFLOW_JAR not found: $NEXTFLOW_JAR" >&2
    exit 1
fi

# JVM options copied from the Nextflow launcher script
JAVA_OPTS=(
    -Dfile.encoding=UTF-8
    -Djava.awt.headless=true
    --add-opens=java.base/java.lang=ALL-UNNAMED
    --add-opens=java.base/java.io=ALL-UNNAMED
    --add-opens=java.base/java.nio=ALL-UNNAMED
    --add-opens=java.base/java.net=ALL-UNNAMED
    --add-opens=java.base/java.util=ALL-UNNAMED
    --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED
    --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED
    --add-opens=java.base/java.nio.file.spi=ALL-UNNAMED
    --add-opens=java.base/sun.nio.ch=ALL-UNNAMED
    --add-opens=java.base/sun.nio.fs=ALL-UNNAMED
    --add-opens=java.base/sun.net.www.protocol.http=ALL-UNNAMED
    --add-opens=java.base/sun.net.www.protocol.https=ALL-UNNAMED
    --add-opens=java.base/sun.net.www.protocol.ftp=ALL-UNNAMED
    --add-opens=java.base/sun.net.www.protocol.file=ALL-UNNAMED
    --add-opens=java.base/jdk.internal.misc=ALL-UNNAMED
    --add-opens=java.base/jdk.internal.vm=ALL-UNNAMED
    --add-opens=java.base/java.util.regex=ALL-UNNAMED
)

# The working directory goes first so Groovy can resolve test classes (e.g.
# ExampleTests, validator.bl.*) from their .groovy sources by class name
exec "${JAVA_CMD:-java}" "${JAVA_OPTS[@]}" \
    -cp ".:${NEXTFLOW_JAR}:${TEST_JARS_DIR}/*" \
    groovy.ui.GroovyMain "$@"
