FROM httpd:2.4

# Enable mod_status + include the info/status config (httpd-info.conf) by uncommenting defaults
RUN set -eux; \
  sed -ri 's/^\s*#\s*(LoadModule\s+status_module\s+modules\/mod_status\.so)/\1/' /usr/local/apache2/conf/httpd.conf; \
  sed -ri 's/^\s*#\s*(Include\s+conf\/extra\/httpd-info\.conf)/\1/' /usr/local/apache2/conf/httpd.conf

# Provide our hardened httpd-info.conf (overrides the stock one)
COPY conf/extra/httpd-info.conf /usr/local/apache2/conf/extra/httpd-info.conf
