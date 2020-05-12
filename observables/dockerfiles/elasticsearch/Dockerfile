FROM docker.elastic.co/elasticsearch/elasticsearch:7.5.1

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0                       
# Allow ENTRYPOINT (and ES) to run even with a different user                       
RUN chgrp 0 /usr/local/bin/docker-entrypoint.sh && \
    chmod g=u /etc/passwd && \
    chmod 0775 /usr/local/bin/docker-entrypoint.sh