Certs are generated at runtime into the Docker volume `es_certs` by the `es-setup` container.
If you want local curl commands, copy the CA cert out of the volume or exec into a node container.
