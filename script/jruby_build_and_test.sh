#!/usr/bin/env bash
set -euo pipefail

JRUBY_IMAGE="jruby:9.1.17.0-jdk"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Starting JRuby build in Docker container..."
echo "    Image: ${JRUBY_IMAGE}"
echo "    Project: ${PROJECT_DIR}"

rm -f "${PROJECT_DIR}/Gemfile.lock"

docker run --rm --platform linux/amd64 -v "${PROJECT_DIR}:/app" -w /app "${JRUBY_IMAGE}" bash -c '
  set -euo pipefail

  echo "==> Installing dependencies..."
  apt-get update -qq
  apt-get upgrade -y -qq
  apt-get install -y -qq git

  echo "==> Compiling Java source..."
  cd ext/java
  rm -f sin_fast_blank/*.class
  javac -cp /opt/jruby/lib/jruby.jar sin_fast_blank/SinFastBlankLibrary.java

  echo "==> Creating JAR file..."
  jar cvf ../../lib/sin_fast_blank/sin_fast_blank.jar sin_fast_blank/*.class

  echo "==> Installing Ruby dependencies..."
  cd ../../
  gem install bundler -v "< 2.4"
  bundle install

  echo "==> Running tests..."
  bundle exec rake test

  echo "==> JRuby build and test completed successfully."
'

rm "${PROJECT_DIR}/Gemfile.lock"
