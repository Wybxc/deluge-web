FROM debian:bookworm AS builder
RUN apt-get update && apt-get install -y cmake build-essential libssl-dev \
    libboost-tools-dev libboost-dev libboost-system-dev libboost-python-dev \
    python3-setuptools python3-wheel
WORKDIR /build
COPY ./libtorrent /build/libtorrent
RUN cd libtorrent && python3 setup.py build_ext --b2-args=webtorrent=on bdist_wheel

FROM python:3.11-slim-bookworm
WORKDIR /deluge
RUN apt-get update &&\
    apt-get install -y curl libboost-python1.74.0 &&\
    rm -rf /var/lib/apt/lists/*
RUN pip install deluge[all] pygeoip supervisor
RUN mkdir -p /usr/share/GeoIP/ && \
    curl -L --retry 10 --retry-max-time 60 --retry-all-errors \
    "https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/geoip.dat" \
    -o /usr/share/GeoIP/GeoIP.dat
COPY --from=builder /build/libtorrent/bindings/python/dist/*.whl /deluge/
COPY supervisord.conf /etc/supervisord.conf
RUN pip install /deluge/*.whl
VOLUME /config
CMD ["supervisord", "-n"]
