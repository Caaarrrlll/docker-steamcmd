FROM caaarrrlll/wine-baseimage:latest

LABEL org.opencontainers.image.authors="venter109@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/Caaarrrlll/docker-steamcmd-server"

RUN apt-get update && \
	apt-get -y install lib32gcc-s1 screen xvfb winbind ca-certificates && \
    update-ca-certificates && \
    apt-get update && \
	apt-get -y autoremove

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Environment Variables
ENV DATA_DIR="/serverdata"
    
ENV HOME="${DATA_DIR}" \
    STEAMCMD_DIR="${DATA_DIR}/steamcmd" \
    SERVER_DIR="${DATA_DIR}/serverfiles" 

ENV GAME_ID="template" \
    MAP="template" \
    SERVER_NAME="template" \
    SRV_PWD="template" \
    SRV_ADMIN_PWD="template" \
    GAME_PARAMS="template" \
    GAME_PARAMS_EXTRA="template" \
    GAME_PORT=27015 \
    VALIDATE="template" \
    UMASK=000 \
    UID=99 \
    GID=100 \
    STEAM_USERNAME="template" \
    STEAM_PASSWORD="template" \
    USER="steam" \
    DATA_PERM=770 \
    DEBUG=0

# Workspace and User setup
RUN mkdir $DATA_DIR && \
	mkdir $STEAMCMD_DIR && \
	mkdir $SERVER_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR

# Scripts handling
ADD /scripts/ /opt/scripts/
RUN chmod -R ${DATA_PERM} /opt/scripts/ && \
    chown -R $USER:$GID /opt/scripts

ENTRYPOINT ["/opt/scripts/start.sh"]