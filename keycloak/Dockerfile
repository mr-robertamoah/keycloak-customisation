FROM quay.io/keycloak/keycloak:24.0

# Copy custom theme into Keycloak themes directory
COPY themes/blog-theme /opt/keycloak/themes/blog-theme

# Set working directory
WORKDIR /opt/keycloak

# Use the default entrypoint
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
