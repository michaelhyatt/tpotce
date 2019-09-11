FROM docker.elastic.co/kibana/kibana:7.3.1

#
# Add and move files
ADD --chown=kibana:kibana dist/ /dist/

RUN cd /dist && \
    # cp kibana.svg /usr/share/kibana/src/ui/public/images/kibana.svg && \
    # cp kibana.svg /usr/share/kibana/src/ui/public/icons/kibana.svg && \
    # cp elk.ico /usr/share/kibana/src/ui/public/assets/favicons/favicon.ico && \
    # cp elk.ico /usr/share/kibana/src/ui/public/assets/favicons/favicon-16x16.png && \
    # cp elk.ico /usr/share/kibana/src/ui/public/assets/favicons/favicon-32x32.png && \

# Setup configs
    sed -i 's/#server.basePath: ""/server.basePath: "\/kibana"/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#kibana.defaultAppId: "home"/kibana.defaultAppId: "dashboards"/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#elasticsearch.hosts: \["http:\/\/localhost:9200"\]/elasticsearch.hosts: \["http:\/\/elasticsearch:9200"\]/' /usr/share/kibana/config/kibana.yml && \
    sed -i 's/#server.rewriteBasePath: false/server.rewriteBasePath: false/' /usr/share/kibana/config/kibana.yml && \
    # sed -i "s/#005571/#e20074/g" /usr/share/kibana/built_assets/css/plugins/kibana/index.css && \
    # sed -i "s/#007ba4/#9e0051/g" /usr/share/kibana/built_assets/css/plugins/kibana/index.css && \
    # sed -i "s/#00465d/#4f0028/g" /usr/share/kibana/built_assets/css/plugins/kibana/index.css && \
    echo "" >> /usr/share/kibana/config/kibana.yml && \
    echo "xpack.infra.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    # echo "xpack.logstash.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    # echo "xpack.canvas.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    # echo "xpack.spaces.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    echo "xpack.apm.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    echo "xpack.uptime.enabled: false" >> /usr/share/kibana/config/kibana.yml && \
    # rm -rf /usr/share/kibana/optimize/bundles/* && \
    # /usr/share/kibana/bin/kibana --optimize
    echo ""

# Healthcheck
HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:5601'
#
# Start kibana
STOPSIGNAL SIGKILL
USER kibana:kibana
CMD ["/usr/share/kibana/bin/kibana"]
