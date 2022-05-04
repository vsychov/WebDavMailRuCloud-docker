#FORK FROM https://github.com/slothds/wdmrc-proxy/blob/master/Dockerfile

ARG     WDMRC_REPO="https://github.com/yar229/WebDavMailRuCloud/releases"
ARG     WDMRC_HOME="/opt/runner"
ARG     NCORE_LVER="3.1.24"
ARG     ALPINE_VERSION="3.15"

FROM    alpine:${ALPINE_VERSION} as builder

ARG     WDMRC_REPO
ARG     WDMRC_HOME
ARG     NCORE_LVER

RUN     apk add --no-cache \
                           icu-libs \
                           krb5-libs \
                           libintl \
                           libssl1.1 \
                           libstdc++ \
                           lttng-ust \
                           zlib \
                           ca-certificates curl

WORKDIR ${WDMRC_HOME}/dotnet

RUN export NCORE_LINK="https://dotnet.microsoft.com/download/dotnet-core/thank-you/runtime-${NCORE_LVER}-linux-x64-alpine-binaries" && \
        echo "Download .Net Core v${NCORE_LVER} via ${NCORE_LINK}" && \
        curl -kfSL $(curl -sL ${NCORE_LINK} | sed -rn "s|.*<a href=\"(.*\.tar\.gz)\".*|\1|p;") \
        | tar -zx -C .

RUN  export WDMRC_LVER=$(curl -sL ${WDMRC_REPO}/latest | sed -rn 's|.*<a.*WebDAVCloudMailRu-([.[:digit:]]*)-dotNetCore.*|\1|p;') && \
     export WDMRC_DNET=$(curl -sL ${WDMRC_REPO}/latest | sed -rn 's|.*<a.*WebDAVCloudMailRu-.*(dotNetCore[[:digit:]]*)\.zip.*|\1|p;') && \
      echo "Download WebDavMailRuCloud v${WDMRC_LVER}-${WDMRC_DNET}" && \
      curl -kfSL ${WDMRC_REPO}/download/${WDMRC_LVER}/WebDAVCloudMailRu-${WDMRC_LVER}-${WDMRC_DNET}.zip \
            -o /tmp/wdmrc-core.zip && \
        unzip /tmp/wdmrc-core.zip -d ./..

FROM    alpine:${ALPINE_VERSION}

ARG     WDMRC_HOME

RUN     apk add --no-cache \
                           icu-libs \
                           krb5-libs \
                           libintl \
                           libssl1.1 \
                           libstdc++ \
                           lttng-ust \
                           zlib

RUN echo ${WDMRC_HOME} && addgroup -g 10001 runner && adduser -u 10001 -g 10001 -G users -HD -h ${WDMRC_HOME} -s /bin/false runner

WORKDIR ${WDMRC_HOME}

COPY --from=builder ${WDMRC_HOME} ${WDMRC_HOME}

RUN chown -R runner:runner .

EXPOSE 8010

CMD ["./dotnet/dotnet", "./wdmrc.dll", "--host=http://*", "--port=8010"]
