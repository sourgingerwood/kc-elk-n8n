FROM quay.io/keycloak/keycloak:26.2.1

USER root
RUN microdnf install -y curl && microdnf clean all
USER 1000
