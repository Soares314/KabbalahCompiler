FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# instala GCC, Flex, Bison e ferramentas de build
RUN apt-get update && apt-get install -y \
    build-essential \
    flex \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Define a pasta de trabalho dentro do container
WORKDIR /workspace

CMD ["/bin/bash"]